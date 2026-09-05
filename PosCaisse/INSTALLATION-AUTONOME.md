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
| `postgresql-16-windows-x64-binaries.zip` | enterprisedb.com → *PostgreSQL Binaries*, 16, Windows x86-64 |

Sur Linux, `./build-bundle.sh` fait la même chose (`.tar.gz`).

## 2. Installer sur le poste (sans internet)

1. Copier le ZIP par clé USB, le décompresser dans **`C:\PosCaisse`**
   (éviter le Bureau et *Mes documents* : chemins longs, synchronisation cloud).
2. Double-cliquer sur **`INSTALLER.bat`** — 2 à 3 minutes.
3. Se connecter : `admin` / `admin123`, puis **changer ce mot de passe immédiatement**.

L'installation crée un serveur PostgreSQL privé dans le dossier, avec un mot de passe tiré
au hasard, à l'écoute de `127.0.0.1` seulement. Aucun service Windows n'est enregistré,
aucune clé de registre n'est écrite.

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
