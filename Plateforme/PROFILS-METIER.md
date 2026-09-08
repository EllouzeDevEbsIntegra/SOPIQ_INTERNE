# Ouvrir une verticale

> **En une phrase :** un métier n'est pas du code, c'est une ligne de déclarations et un
> fichier de carte. La caisse ne connaît ni les cafés ni les supérettes — elle lit des
> réglages.

## Ce qui se passe quand un client neuf démarre

Le back-office prépare la base et rend une commande de lancement. Le poste la reçoit, et
se configure **lui-même** au tout premier démarrage :

```
LANG=C.UTF-8 POSCAISSE_DB_NAME=pos_cli0007_cafe POSCAISSE_DB_USER=pos_cli0007_cafe \
POSCAISSE_DB_PASSWORD=… POSCAISSE_PROFIL=CAFE POSCAISSE_ENSEIGNE='CAFÉ DES DÉLICES' \
POSCAISSE_DEMO_DATA=true java -jar poscaisse.jar
```

1. Flyway pose le schéma.
2. Le socle est créé : rôles, moyens de paiement, destinations d'impression, compte `admin`.
3. La maison est créée : société à l'enseigne du client, un point de vente, une caisse.
4. **Les réglages du métier sont écrits en base** — le gérant les voit dans son back-office
   et peut tous les changer.
5. **La carte de démonstration du métier est chargée** depuis le JAR, si on l'a demandée.

Aucun technicien, aucun script, aucun terminal ouvert chez le client.

### « Repartir de zéro »

`POSCAISSE_DEMO_DATA=false` : le commerçant reçoit la maison, une caisse, son compte
administrateur et les réglages de son métier — et un catalogue **vide**. L'adresse et le
matricule fiscal restent blancs : une adresse inventée s'imprimerait sur ses tickets.

Le choix se fait dans la boîte « Préparer la base du client » du back-office, et il est
gardé sur l'abonnement : la commande se rejoue telle quelle le jour où le poste est
remplacé.

### Cela ne s'exécute qu'une fois

Uniquement sur une base où **aucune société n'est enregistrée**. Un commerce en service ne
doit jamais voir sa carte remplacée ni ses réglages remis à ceux du profil parce qu'une
variable d'environnement a changé au redémarrage.

## Les six métiers livrés

| Profil | Carte | Articles | Scan | Stock | Rupture | Entrée | Modes |
|---|---|---:|---|---|---|---|---|
| `RESTO` | intégrée (avec menus) | 35 + 4 menus | non | aucun | refuser | libre | sur place, emporter, livraison |
| `CAFE` | `mistral-coffee.json` | 112 | non | partiel | avertir | libre | sur place, emporter |
| `SHOP` | `superette-el-baraka.json` | 187 | **oui** | total | avertir | achat | emporter |
| `VETEMENT` | `style-boutique.json` | 65 | **oui** | total | avertir | achat | emporter |
| `PATISSERIE` | `dar-halwa.json` | 71 | non | partiel | avertir | libre | sur place, emporter |
| `PARFUMERIE` | `nour-parfums.json` | 76 | **oui** | total | avertir | achat | emporter |

**Le scan n'est réservé à personne.** C'est un réglage comme un autre : un café qui décide
de scanner ses bouteilles coche la case, et cela marche. Le tableau donne ce que le profil
*pose au départ*, pas ce qu'il autorise.

**Pourquoi le restaurant refuse et le commerce avertit.** Un fast-food ne peut pas servir
ce qu'il n'a pas. Une supérette, si : le rayon a souvent raison contre le compteur, et
bloquer une vente devant le client pour un écart d'inventaire coûte plus cher que l'écart.

**Le RESTO n'a pas de fichier de carte.** Sa démonstration contient des **menus composés**,
que le format d'import ne sait pas encore porter ; elle est donc écrite dans le code
(`DemoDataSeeder.seedCarteFastFood`). Elle est **générique** — un fast-food de
démonstration — et surtout pas la carte d'un client réel : les prix d'un restaurant ne
partent pas chez ses concurrents. *Le jour où l'import portera les menus, cette ligne
recevra un fichier comme les autres.*

## Ajouter un septième métier

1. **Écrire la carte** : un JSON dans `Plateforme/catalogs/`, au format d'import
   (`catalogs/LISEZ-MOI-CARTES.md`). Données proches du marché réel, prix compris.
2. **La déclarer dans le JAR** : une ligne `<include>` dans `backend/pom.xml`.
3. **Ajouter la ligne du profil** dans `ProfilMetier` : libellé, enseigne de démonstration,
   nom du fichier, et les réglages de départ.
4. **Ajouter le module** côté back-office éditeur (`Enums.Module`) pour pouvoir le vendre.

Rien d'autre. `ProfilMetierTest` vérifie ensuite tout seul que la carte existe dans le JAR,
qu'elle se lit, que chaque article a un code et un prix, que les réglages déclarés sont des
réglages que la caisse connaît, et qu'un métier qui scanne a bien des codes-barres dans sa
carte. Une faute de frappe dans un nom de fichier devient un échec de compilation chez
nous, au lieu d'une caisse vide chez un client un matin d'ouverture.

## `LANG=C.UTF-8` n'est pas un détail

Une variable d'environnement est une suite d'octets. La machine virtuelle la lit avec
l'encodage du système, et un serveur démarré sans langue configurée lit en ASCII :
`SUPÉRETTE ESSALEM` arrive alors amputé de son É, et ce nom abîmé s'imprimerait sur chaque
ticket du commerce.

La caisse s'en aperçoit — elle refuse d'enregistrer une enseigne contenant des caractères
de remplacement, pose celle du profil en attendant, et écrit dans le journal exactement
quoi corriger. Mais autant ne pas la mettre dans cette situation : la commande rendue par
le back-office porte `LANG=C.UTF-8` en tête.

## Où c'est écrit

| Fichier | Ce qu'il fait |
|---|---|
| `backend/.../bootstrap/ProfilMetier.java` | La table des métiers : réglages de départ et carte |
| `backend/.../bootstrap/AmorcageMetier.java` | Lit la configuration, pose les réglages, charge la carte |
| `backend/.../bootstrap/DemoDataSeeder.java` | Le socle, la maison, et la carte fast-food du RESTO |
| `backend/pom.xml` | Les cartes embarquées dans le JAR |
| `plateforme/.../service/ProvisionnementService.java` | La base, le compte, et la commande de lancement |
