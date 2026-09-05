# Installation sur un poste sans internet

Le poste du client n'a besoin de **rien** : ni Java, ni PostgreSQL, ni Node, ni droits
administrateur, ni connexion. Tout voyage dans un dossier que l'on copie par clé USB.

Le principe : une machine qui a internet fabrique le paquet une fois ; le poste hors ligne
ne fait que le décompresser et lancer `INSTALLER.bat`.

---

## 1. Fabriquer le paquet (machine avec internet)

```
cd PosCaisse\packaging
powershell -ExecutionPolicy Bypass -File build-bundle.ps1
```

Le script compile l'interface, la scelle **dans** le JAR, compile l'application, récupère
le moteur Java et PostgreSQL, assemble le tout et produit :

```
packaging\dist\PosCaisse-<version>.zip     (~250 Mo)
```

Les archives tierces sont conservées dans `packaging\telechargements\` et réutilisées :
la deuxième fabrication ne télécharge plus rien.

**Si un téléchargement échoue** (lien déplacé, réseau filtré), le script indique le nom
exact du fichier et l'adresse où le prendre. Déposez-le dans `packaging\telechargements\`
et relancez :

| Fichier attendu | Où le prendre |
|---|---|
| `jre-21-windows-x64.zip` | adoptium.net → Temurin 21, Windows x64, **JRE**, archive `.zip` |
| `postgresql-16-windows-x64-binaries.zip` | enterprisedb.com → *PostgreSQL Binaries*, 16, Windows x86-64 (le `16` suit `-VersionPostgres` ; n'importe quelle version mineure convient) |

Sur Linux, `./build-bundle.sh` fait la même chose (`.tar.gz`).

### Quelle version de PostgreSQL embarquer

Par défaut la **16**. Elle n'a d'importance que sur un point, mais il est décisif : une
sauvegarde écrite par `pg_dump` ne se relit que par un `pg_restore` de version **égale ou
supérieure**. Un poste en 16 refuse un fichier exporté en 17, avec le message
`version non supportée (1.16) dans le fichier d'en-tête`.

`EXPORTER_DONNEES.bat` affiche la version de **votre serveur** de développement. Si elle
est plus récente que 16, fabriquez le paquet dans cette version :

```powershell
.\build-bundle.ps1 -VersionPostgres 17
```

Versions acceptées : 14, 15, 16, 17. Le script essaie plusieurs versions mineures jusqu'à
ce que le serveur d'EnterpriseDB en serve une — les anciennes y disparaissent sans
préavis, et seule la version **majeure** compte pour relire une sauvegarde. Si aucune ne
répond, il indique le nom exact du fichier à déposer à la main. La version réellement
assemblée est lue dans les binaires et inscrite dans `VERSION.txt` du paquet.

Sur un poste **déjà installé**, changer de version majeure rend illisible le dossier
`donnees\` : sauvegardez (`SAUVEGARDER.bat`), renommez `donnees\`, relancez
`INSTALLER.bat`, puis `RESTAURER.bat`.

## 2. Installer sur le poste (sans internet)

1. Copier le ZIP par clé USB, le décompresser dans **`C:\PosCaisse`**
   (éviter le Bureau et *Mes documents* : chemins longs, synchronisation cloud).
2. Double-cliquer sur **`INSTALLER.bat`** — 2 à 3 minutes.
3. Se connecter : `admin` / `admin123`, puis **changer ce mot de passe immédiatement**.

L'installation crée un serveur PostgreSQL privé dans le dossier, avec un mot de passe tiré
au hasard, à l'écoute de `127.0.0.1` seulement. Aucun service Windows n'est enregistré,
aucune clé de registre n'est écrite.

## 2 bis. Transférer VOS données sur le poste

Le paquet s'installe avec un jeu de **démonstration** — enseigne fictive, articles
d'exemple. Ce n'est pas votre carte. Pour mettre le poste en service avec ce que vous avez
préparé :

**Sur votre poste**, une fois : `EXPORTER_DONNEES.bat`

Il pose une question, et c'est la seule qui compte :

| Réponse | Ce qui part | Quand |
|---|---|---|
| **N** (défaut) | carte, entreprise, utilisateurs, réglages, clients, livreurs, remarques | **mise en service** : le client démarre avec un journal vierge et des tickets numérotés à partir de 1 |
| **O** | tout, vos tickets de test compris | reproduire un problème sur un autre poste |

Le fichier est écrit dans `PosCaisse\exports\`.

**Sur le poste du client** : copiez le `.dump` par clé USB, puis `ARRETER.bat` →
`RESTAURER.bat` (indiquez le chemin du fichier) → `DEMARRER.bat`.

La restauration **remplace** tout ce que contient la base du poste. Elle rétablit aussi la
propriété des tables au compte local : votre base appartient à `postgres`, celle du poste à
`poscaisse`, et sans cela la restauration s'achèverait sur une avalanche de « rôle
inexistant ».

**Si `RESTAURER.bat` répond « version non supportée »** : le fichier vient d'un PostgreSQL
plus récent que celui du poste. Le poste n'a rien de cassé — c'est le paquet qui est trop
ancien. Deux issues, au choix :

1. exporter avec les outils PostgreSQL de la version du serveur (l'export prévient
   lorsqu'il utilise un `pg_dump` d'une autre version que le serveur) ;
2. refabriquer le paquet dans la version du serveur — voir *Quelle version de PostgreSQL
   embarquer* — et réinstaller.

## 3. Au quotidien

| Fichier | Rôle |
|---|---|
| `DEMARRER.bat` | ouvre la caisse — à placer dans le dossier Démarrage de Windows |
| `ARRETER.bat` | ferme proprement la caisse et la base |
| `SAUVEGARDER.bat` | copie de sécurité dans `sauvegardes\` |
| `ETAT.bat` | ce qui tourne, et la date de la dernière sauvegarde |
| `RESTAURER.bat` | remet les données d'une sauvegarde (remplace tout) |

## 4. Mettre à jour une installation existante

Les données vivent dans `donnees\`, séparées de l'application. Une mise à jour ne les
touche pas :

1. `SAUVEGARDER.bat`, et **copier le fichier obtenu sur une clé USB**.
2. `ARRETER.bat`.
3. Remplacer **`poscaisse.jar`** par celui du nouveau paquet — et lui seul.
4. `DEMARRER.bat`. Les migrations de schéma s'appliquent au démarrage.

Ne remplacez jamais le dossier `donnees\` : ce sont les ventes du client.

## 5. Ce que le poste ne fait pas

- **Pas de mise à jour automatique.** Sans internet, chaque version passe par une clé USB.
- **Pas de sauvegarde hors du poste.** `sauvegardes\` est sur le même disque : cela protège
  d'une fausse manœuvre, pas d'une panne de disque ni d'un vol. La copie sur support externe
  reste un geste humain, à inscrire dans la routine de fermeture.
- **Un seul poste.** Pour plusieurs caisses, il faut un poste serveur et un réseau local —
  l'application le permet (elle est déjà multi-caisses), le paquet autonome non.

## 6. Réglages

`config\poscaisse.conf`, au Bloc-notes, appliqué au redémarrage :

| Clé | Rôle |
|---|---|
| `APP_PORT` | port de la caisse (8080) |
| `PG_PORT` | port de la base (5433, volontairement différent du 5432 habituel pour cohabiter avec un PostgreSQL déjà installé) |
| `KIOSQUE` | `1` = ticket imprimé sans boîte de dialogue (Chrome ou Edge requis) |
| `PASS` | mot de passe de la base, tiré au hasard à l'installation — à ne pas modifier à la main |

---

## Note pour qui modifie les scripts `.ps1`

Windows PowerShell 5.1 — celui livré avec Windows — lit un fichier **sans marque d'ordre des
octets (BOM)** comme de l'ANSI, pas comme de l'UTF-8. Un tiret cadratin `—` y devient `â€"`,
dont le dernier caractère est un guillemet fermant que le langage prend pour un **délimiteur
de chaîne** : le script est coupé en deux et l'erreur signalée tombe des dizaines de lignes
plus bas que la vraie cause.

Les scripts du dépôt sont donc en **ASCII pur** et portent une **marque d'ordre des octets**.
`packaging/verifier-scripts.sh` le contrôle, et `build-bundle.sh` l'exécute avant toute
compilation. PowerShell 7 ne montre pas le problème : il lit l'UTF-8 par défaut.
