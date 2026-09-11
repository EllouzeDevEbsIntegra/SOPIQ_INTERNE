#!/bin/bash
#
# PREPARER LES SIX CAISSES DE DEMONSTRATION SUR UN SERVEUR.
#
# A executer une fois, en root, depuis le dossier deploiement/ du depot. Le script est
# IDEMPOTENT : le relancer ne casse rien et ne change aucun mot de passe deja pose.
#
#   sudo ./preparer-demos.sh
#
# CE QU'IL FAIT, ET CE QU'IL NE FAIT PAS. Il pose ce qu'une demo ne peut pas se donner a
# elle-meme : son role PostgreSQL, son fichier d'environnement, son adresse dans nginx.
# Il ne cree AUCUNE base et n'allume AUCUNE caisse - c'est le back-office qui le fait,
# par le bouton, et c'est lui qui doit rester le seul chemin.
#
# POURQUOI LE ROLE EST CREE ICI PLUTOT QUE PAR LE BACK-OFFICE. Le back-office sait creer
# un role, mais il lui tire un mot de passe au hasard qu'il ne relit ni ne revele jamais -
# c'est voulu pour un client, dont la caisse est provisionnee d'un seul geste. Une demo,
# elle, a son mot de passe ecrit dans un fichier systemd pose a la main : les deux doivent
# donc etre choisis au meme endroit, et c'est ici. Le back-office, lui, ne recree pas un
# role qui existe deja.

set -euo pipefail

DOMAINE="${DOMAINE:-pos.ebs-integra.com}"
ICI="$(cd "$(dirname "$0")" && pwd)"

# Le compte sous lequel tourne le back-office, lu dans son propre fichier : c'est lui qui
# devra creer les bases des demos, et il lui faut pour cela l'ADMIN OPTION sur leurs roles.
PLATEFORME_ENV="/etc/poscaisse/plateforme.env"
# Sans tube : « set -o pipefail » a deja tue ce script une fois (voir alea plus bas).
ADMIN="$(LC_ALL=C awk 'index($0, "PLATEFORME_DB_USER=") == 1 { print substr($0, 20); exit }' \
         "$PLATEFORME_ENV" 2>/dev/null || true)"
ADMIN="${ADMIN:-poscaisse_admin}"
MODELE="$ICI/nginx/pos-caisse.conf.modele"

# metier:port:profil — les ports sont ceux de la table « demo » du back-office (V3).
DEMOS="resto:8121:RESTO cafe:8122:CAFE shop:8123:SHOP vetement:8124:VETEMENT patisserie:8125:PATISSERIE parfumerie:8126:PARFUMERIE"

[ "$(id -u)" = 0 ] || { echo "À lancer en root : sudo $0" >&2; exit 1; }
[ -f "$MODELE" ] || { echo "Modèle nginx introuvable : $MODELE" >&2; exit 1; }
id poscaisse >/dev/null 2>&1 || { echo "Le compte système « poscaisse » n'existe pas." >&2; exit 1; }
command -v openssl >/dev/null || { echo "openssl est requis pour tirer les mots de passe." >&2; exit 1; }
[ -f /etc/letsencrypt/live/$DOMAINE/fullchain.pem ] || {
    echo "Certificat absent pour $DOMAINE — voir LISEZ-MOI.md § Le certificat." >&2; exit 1; }

install -d -m 750 -o root -g poscaisse /etc/poscaisse
install -d -m 755 -o poscaisse -g poscaisse /opt/poscaisse/caisses

# Un secret alphanumerique : les fichiers d'environnement de systemd ne sont pas un shell,
# mais un mot de passe sans caractere special evite aussi les surprises cote psql.
#
# SANS TUBE, ET CE N'EST PAS UN DETAIL DE STYLE. La forme naturelle - « tr -dc ... <
# /dev/urandom | head -c 32 » - tue « tr » d'un tube ferme des que head a ses 32 octets ;
# avec « set -o pipefail » le pipeline rend 141, et « set -e » arrete le script AVANT sa
# premiere ligne d'affichage. Le script mourait donc sans rien dire ni rien faire.
alea() {
    local n="$1" h
    h="$(openssl rand -hex "$n")"      # 2n caracteres, tous alphanumeriques
    printf '%s' "${h:0:n}"
}

# Lire une valeur deja posee : on ne change JAMAIS un mot de passe en service.
# Sans tube non plus, et pour la meme raison.
deja() {
    [ -f "$2" ] || return 0
    LC_ALL=C awk -v k="$1" 'index($0, k "=") == 1 { print substr($0, length(k) + 2); exit }' "$2"
}

for d in $DEMOS; do
    metier="${d%%:*}"; reste="${d#*:}"; port="${reste%%:*}"; profil="${reste##*:}"
    role="posdemo_$metier"
    env="/etc/poscaisse/demo-$metier.env"
    nom="demo-$metier"

    mdp="$(deja POSCAISSE_DB_PASSWORD "$env")"
    [ -n "$mdp" ] || mdp="$(alea 32)"
    jeton="$(deja POSCAISSE_JWT_SECRET "$env")"
    [ -n "$jeton" ] || jeton="$(alea 80)"

    # LE SECRET DE L'ADMINISTRATEUR DE CETTE DEMONSTRATION.
    #
    # Une demo est joignable depuis internet : << admin / admin123 >>, ecrit dans le code
    # source, laissait n'importe qui saccager la carte pendant qu'on la montre a un
    # prospect. L'equipe de demonstration garde ses PIN - c'est ce qu'on tape devant lui -
    # mais le compte qui peut tout faire prend un secret propre a ce serveur.
    #
    # Il est affiche en fin de script, une fois, et relu du fichier aux relances : il ne
    # change donc pas sous les pieds d'un commercial en rendez-vous.
    admin_mdp="$(deja POSCAISSE_ADMIN_PASSWORD "$env")"
    [ -n "$admin_mdp" ] || admin_mdp="$(alea 24)"

    # Le role : cree s'il manque, remis au mot de passe du fichier s'il est deja la.
    # ALTER plutot que rien : le role « posdemo_cafe » d'un essai precedent porte un mot de
    # passe que personne ne connait, et la caisse ne pourrait pas ouvrir sa base.
    if [ "$(sudo -u postgres psql -tAc "SELECT 1 FROM pg_roles WHERE rolname='$role'")" = 1 ]; then
        echo "ALTER ROLE $role WITH LOGIN PASSWORD '$mdp';" | sudo -u postgres psql -qv ON_ERROR_STOP=1 > /dev/null
        echo "  rôle $role : mot de passe réaligné sur le fichier"
    else
        echo "CREATE USER $role WITH PASSWORD '$mdp';" | sudo -u postgres psql -qv ON_ERROR_STOP=1 > /dev/null
        echo "  rôle $role : créé"
    fi

    # L'ADMIN OPTION POUR LE BACK-OFFICE, ET RIEN DE PLUS.
    #
    # Le back-office cree la base de la demo par « CREATE DATABASE ... OWNER $role », et
    # PostgreSQL 16 exige pour cela qu'il puisse ENDOSSER le role - il s'accorde donc
    # l'appartenance le temps de creer la base, puis se la retire. Encore faut-il qu'il ait
    # le droit de se l'accorder : « permission denied to grant role », sinon.
    #
    # Ce droit, il l'aurait eu d'office s'il avait cree le role lui-meme : PostgreSQL 16
    # donne l'ADMIN OPTION au createur. Mais nous creons le role ICI, sous « postgres »,
    # pour en choisir le mot de passe - et le back-office se retrouve alors devant un role
    # qu'il ne peut pas administrer. C'est ce que cette ligne repare, en lui rendant
    # exactement l'etat qu'il aurait eu.
    #
    # INHERIT FALSE, SET FALSE : l'administration du role, PAS son usage. Sans ces deux
    # mots, le compte qui provisionne pourrait endosser le role de chaque demo et lire ses
    # ventes en permanence, au lieu de le faire trois secondes sous son propre controle.
    # Verifie : « permission denied to set role » apres coup.
    echo "GRANT $role TO $ADMIN WITH ADMIN OPTION, INHERIT FALSE, SET FALSE;" | sudo -u postgres psql -qv ON_ERROR_STOP=1 > /dev/null

    # Le fichier d'environnement. 640 root:poscaisse : la caisse le lit, personne d'autre.
    # POSCAISSE_ENSEIGNE est volontairement ABSENT - vide, la caisse prend l'enseigne du
    # profil, ecrite dans le code en UTF-8, et l'accent ne traverse donc aucun environnement.
    umask 027
    cat > "$env" <<EOF
POSCAISSE_DB_HOST=127.0.0.1
POSCAISSE_DB_PORT=5432
POSCAISSE_DB_NAME=$role
POSCAISSE_DB_USER=$role
POSCAISSE_DB_PASSWORD=$mdp
POSCAISSE_PORT=$port
POSCAISSE_PROFIL=$profil
POSCAISSE_DEMO_DATA=true
POSCAISSE_ADMIN_PASSWORD=$admin_mdp
POSCAISSE_JWT_SECRET=$jeton
LANG=C.UTF-8
EOF
    chown root:poscaisse "$env"; chmod 640 "$env"

    # L'adresse. Le vhost precis l'emporte sur le joker « pos-inconnu ».
    sed -e "s/@NOM@/$nom/g" -e "s/@PORT@/$port/g" "$MODELE" \
        > "/etc/nginx/sites-available/pos-$nom"
    ln -sfn "/etc/nginx/sites-available/pos-$nom" "/etc/nginx/sites-enabled/pos-$nom"
    echo "  $nom.$DOMAINE → 127.0.0.1:$port   (admin : $admin_mdp)"
done

systemctl daemon-reload

# nginx -t AVANT de recharger : ce serveur porte cinq autres sites en production, et une
# configuration refusee doit l'etre pendant qu'on regarde, pas au prochain redemarrage.
nginx -t
systemctl reload nginx
echo
echo "Les mots de passe « admin » ci-dessus ouvrent le back-office de chaque démonstration."
echo "Ils sont dans /etc/poscaisse/demo-<métier>.env, lisibles par root seul, et ne"
echo "changent pas aux relances de ce script."
echo
echo "Prêt. Les six démos s'allument depuis le back-office, onglet « Démos »."
