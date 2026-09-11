# Déployer sur un serveur

Ce dossier contient ce qui vit **sur le serveur** et non dans l'application : les unités
systemd, les vhosts nginx, le script d'allumage des démos et sa règle sudo. Ils sont
versionnés ici pour qu'on puisse les relire, les comparer et les remettre à l'identique
sur une autre machine.

Rédigé pour le VPS où le déploiement a été fait : Ubuntu 24.04, nginx et PostgreSQL 16
déjà en place, **cinq applications en production sur la même machine**. Rien de ce qui
suit ne les touche.

## Le principe

| Ce qui écoute | Où | Exposé ? |
|---|---|---|
| nginx | `0.0.0.0:80`, `0.0.0.0:443` | oui, seul point d'entrée |
| back-office | `127.0.0.1:8090` | non |
| caisses clients | `127.0.0.1:8101-8120` | non |
| caisses de démo | `127.0.0.1:8121…8126` | non |
| PostgreSQL | `127.0.0.1:5432` | non |

**Aucune application Java n'écoute sur l'interface publique.** Tout passe par nginx, donc
par HTTPS, donc par un journal d'accès.

## Ce qu'il faut préparer une fois

```bash
# 1. Java 21 À CÔTÉ du Java déjà installé, sans changer le défaut
sudo apt-get install -y openjdk-21-jre-headless
sudo update-alternatives --set java /usr/lib/jvm/java-17-openjdk-amd64/bin/java   # si l'install a basculé le défaut

# 2. Le compte système et les dossiers
sudo useradd --system --home-dir /opt/poscaisse --shell /usr/sbin/nologin poscaisse
sudo mkdir -p /opt/poscaisse/{jars,plateforme,caisses} /etc/poscaisse
sudo chown -R poscaisse:poscaisse /opt/poscaisse
sudo chown root:poscaisse /etc/poscaisse && sudo chmod 750 /etc/poscaisse

# 3. Le rôle PostgreSQL — CREATEDB et CREATEROLE, jamais superutilisateur
#    (voir la commande complète dans l'historique de déploiement)
```

`/etc/poscaisse` en `750 root:poscaisse` : le service **lit** ses identifiants, il ne peut
pas les **modifier**, et personne d'autre sur la machine ne peut même lister le dossier.

## Les fichiers d'environnement

Un par application, en `640 root:poscaisse`. Ils portent les mots de passe de base :
ils ne doivent jamais entrer dans le dépôt.

`/etc/poscaisse/plateforme.env`
```
PLATEFORME_DB_HOST=127.0.0.1
PLATEFORME_DB_NAME=poscaisse_plateforme
PLATEFORME_DB_USER=poscaisse_admin
PLATEFORME_DB_PASSWORD=…
PLATEFORME_PORT=8090
```

`PLATEFORME_CORS_ORIGINS` **n'est plus nécessaire** pour l'adresse qui sert l'écran : le
back-office autorise d'office sa propre origine. Ne la remplissez que si une page hébergée
**ailleurs** doit appeler l'API — l'interface de développement sur `localhost:5173`, par
exemple.

`/etc/poscaisse/demo-cafe.env` — une caisse de démonstration
```
POSCAISSE_DB_HOST=127.0.0.1
POSCAISSE_DB_NAME=posdemo_cafe
POSCAISSE_DB_USER=posdemo_cafe
POSCAISSE_DB_PASSWORD=…
POSCAISSE_PORT=8122
POSCAISSE_PROFIL=CAFE
POSCAISSE_ENSEIGNE=Café de démonstration
POSCAISSE_ADMIN_PASSWORD=…
LANG=C.UTF-8
```

**`POSCAISSE_ADMIN_PASSWORD` est obligatoire sur une base vide**, et la caisse refuse de
démarrer sans lui. Il ne sert qu'à créer le compte `admin` au tout premier démarrage ;
ensuite elle ne le relit plus, et le commerçant a le sien. `preparer-demos.sh` et
`poscaisse-ouvrir` le tirent au sort, l'écrivent ici et l'affichent **une fois**.

L'administrateur n'a **pas de PIN** par défaut. `POSCAISSE_ADMIN_PIN` en pose un si on y
tient, mais quatre chiffres sur le seul compte qui peut tout faire, joignable depuis
internet, c'est une porte à dix mille clés — et le ralentisseur ne fait que ralentir. Les
PIN sont l'outil du caissier, qui tape son code cent fois par jour devant un client qui
attend.

**`LANG=C.UTF-8` n'est pas décoratif.** Une machine virtuelle Java démarrée sans langue lit
son environnement en ASCII : l'enseigne accentuée y perd ses accents, et ce nom abîmé
s'imprimerait sur chaque ticket. La caisse s'en aperçoit et refuse de l'enregistrer, mais
autant ne pas l'y mettre.

## Installer les fichiers de ce dossier

```bash
sudo install -m 644 systemd/*.service /etc/systemd/system/
sudo install -m 755 -o root -g root sbin/poscaisse-demo   /usr/local/sbin/poscaisse-demo
sudo install -m 755 -o root -g root sbin/poscaisse-ouvrir /usr/local/sbin/poscaisse-ouvrir
sudo install -d -m 755 -o root -g root /etc/poscaisse/modeles
sudo install -m 644 -o root -g root nginx/pos-caisse.conf.modele /etc/poscaisse/modeles/pos-caisse.conf
sudo install -m 440 -o root -g root sudoers.d/poscaisse-demo /etc/sudoers.d/poscaisse-demo
sudo visudo -c            # VÉRIFIER avant de se déconnecter
sudo systemctl daemon-reload
```

`poscaisse-ouvrir` n'a **aucune règle sudo**, contrairement à `poscaisse-demo`, et c'est
délibéré : le back-office ne l'appelle pas. Ouvrir un client est un geste rare, fait par
quelqu'un qui a déjà les droits sur la machine ; lui donner un chemin automatique depuis
une application web serait ajouter une porte pour un confort qui ne sert qu'une fois par
client.

Le `visudo -c` n'est pas une politesse : un fichier sudoers invalide rend `sudo`
inutilisable sur toute la machine, et on ne s'en aperçoit qu'après s'être déconnecté.

## Le certificat, une fois pour toutes

Un **joker** `*.pos.ebs-integra.com`, validé par DNS via l'API OVH. Un seul certificat
couvre le back-office, tous les clients et toutes les démos — **ouvrir un client ne
demande donc aucun certificat**, ce qui serait autrement plafonné par les limites
hebdomadaires de Let's Encrypt.

```bash
sudo apt-get install -y certbot python3-certbot-dns-ovh
sudo install -m 600 -o root -g root /dev/null /etc/letsencrypt/ovh.ini   # puis y coller le jeton
sudo certbot certonly --dns-ovh --dns-ovh-credentials /etc/letsencrypt/ovh.ini \
     -d pos.ebs-integra.com -d '*.pos.ebs-integra.com'
```

Le jeton OVH doit porter **quatre** droits, et pas trois : `GET /domain/zone/` (le
listage des zones, sans lequel certbot s'arrête sur un 403 avant même de toucher à la
zone), puis `GET`, `POST` et `DELETE` sur `/domain/zone/ebs-integra.com/*`. Et sans
date d'expiration — sinon le renouvellement automatique casse dans un an, sans prévenir.

## Les six caisses de démonstration

Un seul script, à lancer une fois par serveur, depuis ce dossier :

```bash
sudo ./preparer-demos.sh
```

Il pose ce qu'une démo ne peut pas se donner elle-même — son rôle PostgreSQL, son fichier
d'environnement, son adresse dans nginx — et rien d'autre : **il ne crée aucune base et
n'allume aucune caisse**, le back-office reste le seul chemin. Le relancer ne change aucun
mot de passe déjà en service.

Avant lui, trois choses doivent être en place : le jar de la caisse, l'unité systemd, et
la règle sudo.

```bash
cd ../frontend && npm ci && npm run build
cd ../backend && JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64 mvn -Pbundle -DskipTests package
sudo install -m 644 -o root -g root target/poscaisse-backend.jar /opt/poscaisse/jars/poscaisse.jar
cd ../deploiement
sudo install -m 644 systemd/poscaisse-demo@.service /etc/systemd/system/
sudo install -m 755 -o root -g root sbin/poscaisse-demo /usr/local/sbin/poscaisse-demo
sudo install -m 440 -o root -g root sudoers.d/poscaisse-demo /etc/sudoers.d/poscaisse-demo
sudo visudo -c && sudo systemctl daemon-reload
```

Le `-Pbundle` n'est pas optionnel : sans lui l'interface compilée n'entre pas dans le jar,
et la caisse sert une page d'explication au lieu de l'écran de vente.

Éprouver la règle sudo avant de compter dessus — sous le compte `poscaisse`, un métier
valide doit rendre 3 (éteinte) et un nom fabriqué doit être refusé avec 2 :

```bash
sudo -u poscaisse sudo -n /usr/local/sbin/poscaisse-demo status cafe        # 3
sudo -u poscaisse sudo -n /usr/local/sbin/poscaisse-demo start /etc/shadow  # 2
```

**Une démo met une vingtaine de secondes à répondre au premier allumage** : elle crée son
schéma et pose sa carte. nginx affiche 502 pendant ce temps — c'est le démarrage, pas une
panne. Le journal dit où elle en est :

```bash
sudo journalctl -u poscaisse-demo@cafe -f
```

## Ouvrir la caisse d'un client

Le back-office prépare la base et rend **deux** lignes. La première fait tourner un
processus ; elle ne le rend joignable par personne. La seconde est celle-ci, à lancer en
SSH sur le serveur :

```bash
sudo poscaisse-ouvrir --sous-domaine numberone --port 8101 \
     --base pos_cli0001_resto --profil RESTO --enseigne 'Number One' --demonstration true
```

Elle pose le fichier d'environnement, le service qui redémarre tout seul, et le vhost
nginx à l'adresse du client — puis vérifie nginx avant de le recharger.

**Le mot de passe est demandé à l'écran, jamais en argument.** Tout ce qui passe en
argument se lit dans `ps` par n'importe quel compte de la machine, et reste dans
l'historique du shell. Le script vérifie d'ailleurs la connexion à la base **avant**
d'écrire quoi que ce soit : un mot de passe mal recopié donnerait sinon un service qui
redémarre en boucle, et l'erreur serait à chercher dans `journalctl` au lieu d'être dite
tout de suite.

Il est **idempotent** : relancé sur un client déjà ouvert, il garde son mot de passe et
son jeton, réécrit les mêmes fichiers et redémarre le service. C'est ce qu'on veut après
une mise à jour du jar.

Le sous-domaine et le port viennent du back-office, qui les attribue une fois pour toutes
et les garantit uniques. Le script les revalide quand même — il s'utilise aussi à la main,
et un port déjà pris ne se voit autrement qu'au démarrage, sous la forme d'un
« Address already in use » dans un journal que personne ne lit.

## Le pare-feu

À faire **avant** d'ouvrir le service à des clients, et les yeux ouverts : `ufw` activé
sans règle SSH coupe l'accès au serveur, définitivement si l'hébergeur n'offre pas de
console de secours.

L'ordre compte. On pose les règles pendant que le pare-feu est encore inactif, on relit,
et on active seulement à la fin.

```bash
sudo ss -tlnp | grep sshd                        # 1. sur quel port SSH écoute-t-il vraiment ?
sudo ufw allow 22/tcp comment 'SSH'              # 2. la règle qui sauve, en premier
sudo ufw allow 80,443/tcp comment 'Web nginx'    # 3. le web
sudo ufw default deny incoming                   # 4. tout le reste est refusé
sudo ufw show added                              # 5. on relit : SSH doit y être
sudo ufw enable                                  # 6. répondre y
```

Garder la session SSH ouverte après l'activation : c'est le filet de sécurité, et
`sudo ufw disable` annule tout tant qu'elle vit.

Les applications, elles, n'ont **aucune règle** et n'en veulent pas : nginx les joint sur
`127.0.0.1`, et le pare-feu ne filtre jamais la boucle locale. Le vérifier plutôt que le
supposer — un `proxy_pass` vers l'adresse publique, lui, casserait à l'activation :

```bash
sudo grep -Rn proxy_pass /etc/nginx/sites-enabled/   # -R, pas -r : ce sont des liens symboliques
```

Puis vérifier depuis une autre machine que le port d'une application est bien devenu
injoignable, et que tous les sites répondent encore :

```bash
for d in $(sudo grep -Rh server_name /etc/nginx/sites-enabled/ | grep -v '^ *#' | sed 's/;//' \
           | awk '{for(i=2;i<=NF;i++) print $i}' | grep -v '[*_]' | sort -u); do
  printf '%-40s %s\n' "$d" "$(curl -s -o /dev/null -w '%{http_code}' -m 10 "https://$d/")"
done
```

Un `000` sur un nom qui n'est pas couvert par le certificat est normal et n'a rien à voir
avec le pare-feu : `curl -sS https://ce-nom/` le dit en clair.

## Ce qui reste manuel, et pourquoi

- **La règle des 24 h sur les démos** est dans l'application, pas dans un `cron` : l'état
  « allumée depuis 14 h 32 » vit en base et survit à un redémarrage du back-office.
- **Le redémarrage** après les mises à jour du noyau : la machine porte d'autres
  applications en production, la fenêtre se choisit avec le client.
