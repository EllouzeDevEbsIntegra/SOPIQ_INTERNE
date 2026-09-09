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
| caisses clients | `127.0.0.1:8101…` | non |
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

`/etc/poscaisse/demo-cafe.env` — une caisse de démonstration
```
POSCAISSE_DB_HOST=127.0.0.1
POSCAISSE_DB_NAME=posdemo_cafe
POSCAISSE_DB_USER=posdemo_cafe
POSCAISSE_DB_PASSWORD=…
POSCAISSE_PORT=8122
POSCAISSE_PROFIL=CAFE
POSCAISSE_ENSEIGNE=Café de démonstration
LANG=C.UTF-8
```

**`LANG=C.UTF-8` n'est pas décoratif.** Une machine virtuelle Java démarrée sans langue lit
son environnement en ASCII : l'enseigne accentuée y perd ses accents, et ce nom abîmé
s'imprimerait sur chaque ticket. La caisse s'en aperçoit et refuse de l'enregistrer, mais
autant ne pas l'y mettre.

## Installer les fichiers de ce dossier

```bash
sudo install -m 644 systemd/*.service /etc/systemd/system/
sudo install -m 755 -o root -g root sbin/poscaisse-demo /usr/local/sbin/poscaisse-demo
sudo install -m 440 -o root -g root sudoers.d/poscaisse-demo /etc/sudoers.d/poscaisse-demo
sudo visudo -c            # VÉRIFIER avant de se déconnecter
sudo systemctl daemon-reload
```

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

Le jeton OVH doit être limité à `GET|POST|DELETE /domain/zone/ebs-integra.com/*` et sans
date d'expiration — sinon le renouvellement automatique casse dans un an, sans prévenir.

## Ce qui reste manuel, et pourquoi

- **La règle des 24 h sur les démos** est dans l'application, pas dans un `cron` : l'état
  « allumée depuis 14 h 32 » vit en base et survit à un redémarrage du back-office.
- **Le pare-feu** n'est pas configuré ici. La machine porte d'autres applications, dont
  certaines écoutent sur l'interface publique : activer `ufw` sans autoriser SSH d'abord
  coupe l'accès au serveur. C'est une opération à faire les yeux ouverts, séparément.
