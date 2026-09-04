# PosCaisse — Caisse tactile pour fast-food / petite restauration

Application full-stack de point de vente (POS) : **Vue.js 3 + Vite** (frontend tactile), **Spring Boot 3 / Java 21** (backend REST), **PostgreSQL 16** (Flyway).
Principe : **back-office riche, caisse ultra simple**. Marché initial : Tunisie (TND, 3 décimales, fuseau Africa/Tunis, interface en français).

```
Connexion PIN → Ouverture caisse → POS (catégories / produits / panier) → ENCAISSER → Tickets → Nouvelle commande
```

## Prérequis

| Composant | Version | Remarque |
|-----------|---------|----------|
| Java (JDK) | 17+ (testé avec 21) | `java -version` |
| Maven | 3.8+ | `mvn -version` |
| Node.js / npm | 18+ (testé avec 22) | `node -v` |
| PostgreSQL | 14+ (testé avec 16) | local **ou** via `docker compose up -d postgres` |
| Docker (optionnel) | — | uniquement pour PostgreSQL |

## Lancement en un clic (Windows)

Double-cliquez sur **`RESTART_POS.bat`**. Il enchaîne tout, sans aucune autre manipulation :

1. arrête l'instance en cours et libère les ports 8080 / 5173 ;
2. récupère la dernière version (`git pull`) ;
3. démarre PostgreSQL (Docker si présent, sinon le service Windows) et **crée la base si elle n'existe pas** ;
4. recompile l'interface et le backend **uniquement si nécessaire** (comparaison des dates entre les sources et les binaires : fiable même si vous avez fait le `git pull` vous-même) ;
5. démarre l'application et ouvre le navigateur sur http://localhost:8080.

Comptez une quinzaine de secondes sans recompilation, une à deux minutes avec.
Sous Linux / macOS : `./restart.sh` fait exactement la même chose.

### Charger votre carte

Le catalogue livré par défaut est un jeu de démonstration. Pour charger une vraie carte, placez son fichier JSON dans `catalogs/` puis double-cliquez sur **`IMPORT_MENU.bat`** (Linux/macOS : `./import-menu.sh`).

La carte **NUMBER ONE** est déjà fournie : `catalogs/number-one.json` — 78 produits (Classic, Classic Spécial, Healthy, Healthy Spécial, Lablebi, Extras) et les variantes de pain (Simple / Double / 3arbi, Céréale / Chia / 3arbi) en options obligatoires avec supplément.

L'import remplace le catalogue : ce qui n'est pas dans le fichier est **supprimé s'il n'a jamais été vendu, sinon simplement désactivé**, afin que l'historique des tickets reste intact. Un ré-import met à jour les produits existants par leur code, sans créer de doublon — c'est le moyen de faire évoluer vos prix. Pour ajouter sans rien retirer : `./import-menu.sh catalogs/ma-carte.json --ajouter`.

Les autres scripts restent disponibles pour un usage ciblé : `START_POS.bat` (démarrer sans rien arrêter ni mettre à jour), `STOP_POS.bat` (arrêter), `BUILD_POS.bat` (compiler seulement), `INIT_DB.bat` (préparer la base seulement).

Ces `.bat` sont de simples lanceurs : la logique est dans `restart.ps1` et `init-db.ps1`, exécutés par le PowerShell livré avec Windows. Si un double-clic ouvre puis referme la fenêtre sans rien afficher, le fichier a été récupéré avec des fins de ligne Unix : `git pull` le corrige (le dépôt impose CRLF aux `.bat`/`.ps1`).

## Lancement détaillé (Windows)

1. Copiez le dossier dans `D:\PosCaisse` (ou n'importe où).
2. Double-cliquez **`START_POS.bat`** : démarre PostgreSQL (Docker si présent) et le backend (port 8080, qui sert l'interface compilée depuis `frontend\dist`), puis ouvre le navigateur. Si PosCaisse tourne déjà, il ouvre simplement le navigateur au lieu de tout redémarrer.
4. **`STOP_POS.bat`** arrête tout. **`BUILD_POS.bat`** produit un build de production (`backend\target\poscaisse-backend.jar` + `frontend\dist`, alors servis ensemble sur http://localhost:8080).

Linux / macOS : `./start.sh` et `./stop.sh` (créent aussi la base au besoin).

### Si le backend ne démarre pas

Lisez la dernière ligne `Caused by:` dans la fenêtre « PosCaisse Backend » :

| Message | Cause | Solution |
|---------|-------|----------|
| `la base de données « poscaisse » n'existe pas` | base absente | lancez `INIT_DB.bat`, ou `psql -U postgres -c "CREATE DATABASE poscaisse;"` |
| Le backend démarre mais `http://localhost:8080` affiche « interface non compilée » | `frontend/dist` absent (les builds ne sont pas versionnés) | `cd frontend && npm install && npm run dev` puis http://localhost:5173, ou `npm run build` pour le mode un seul port |
| `password authentication failed` | mot de passe PostgreSQL différent | définissez `POSCAISSE_DB_PASSWORD` (voir `.env.example`) avant de lancer |
| `Connection refused` | PostgreSQL arrêté | démarrez le service PostgreSQL (ou Docker Desktop) |
| `Port 8080 was already in use` | une instance de PosCaisse tourne déjà | lancez `STOP_POS.bat` puis relancez, ou définissez `POSCAISSE_PORT=8081` |
| Le log affiche encore `Using generated security password` | vous exécutez une version antérieure du code | `git pull` puis `BUILD_POS.bat` |

## Lancement manuel

```bash
# 1. PostgreSQL (option Docker)
docker compose up -d postgres

# 2. Backend
cd backend
mvn spring-boot:run                     # http://localhost:8080  (santé : /actuator/health)

# 3. Frontend (développement, proxy /api → 8080)
cd frontend
npm install
npm run dev                             # http://localhost:5173

# Production : npm run build  → le backend sert frontend/dist sur http://localhost:8080
```

Variables d'environnement : voir **`.env.example`** (`POSCAISSE_DB_*`, `POSCAISSE_PORT`, `POSCAISSE_JWT_SECRET`, `POSCAISSE_DEMO_DATA`, …).
Le schéma est créé automatiquement par Flyway au premier démarrage ; un jeu de démonstration complet est chargé si la base est vide (`POSCAISSE_DEMO_DATA=true`).

## Comptes de démonstration

| Rôle | Identifiant | Mot de passe | PIN |
|------|-------------|--------------|-----|
| Administrateur | `admin` | `admin123` | `9999` |
| Manager | `manager` | `manager123` | `2222` |
| Caissier Ahmed | `ahmed` | — | `1234` |
| Caissier Sami | `sami` | — | `5678` |
| Caissière Mariem | `mariem` | — | `4321` |

Entreprise **FAST FOOD DEMO**, point de vente **CENTRE-VILLE (PV01)**, caisses **CAISSE 01 / CAISSE 02**, 39 produits (burgers, sandwichs, pizzas, boissons, desserts, extras, salades, 4 menus), options/suppléments, 5 moyens de paiement, 5 destinations d'impression.

## URLs

| Quoi | URL |
|------|-----|
| POS (dev) | http://localhost:5173 |
| POS (prod, après build) | http://localhost:8080 |
| Back-office | http://localhost:5173/admin |
| API REST | http://localhost:8080/api/... (JWT Bearer) |
| Santé backend | http://localhost:8080/actuator/health |

## Fonctionnalités principales

- **Caisse tactile** : catégories + favoris, tuiles produits (taille configurable), recherche instantanée, panier géré côté navigateur (0 appel réseau par toucher), options/suppléments, menus/formules, notes, remises (ligne / commande, seuil manager), modification de prix (permission), modes de service (sur place / à emporter / livraison), client facultatif, commandes en attente / reprise, raccourcis clavier (F2 encaisser, F4 attente, F3 recherche).
- **Encaissement** : espèces (boutons 5/10/20/50, montant exact, calcul du rendu), carte, chèque, ticket restaurant, autre, **paiement mixte**, protection double validation (idempotence `clientRef` + transaction + verrou de numérotation).
- **Tickets** : ticket client + tickets de préparation routés par destination (cuisine, pizza, boissons…), nombre de copies paramétrable, formats 58/80 mm, modèle configurable avec aperçu, impression navigateur, réimpression (DUPLICATA), file `print_job` prête pour un agent ESC/POS.
- **Caisse** : ouverture avec fond, une seule session ouverte par caisse, entrées/sorties, journal chronologique, clôture avec espèces théoriques / réelles / écart, clôture journalière manager avec historique.
- **Après-vente** : annulation de ticket encaissé (motif + remboursement + audit), remboursement total/partiel, historique des tickets multi-critères.
- **Back-office** : dashboard PostgreSQL (CA, tickets, panier moyen, heure par heure, catégories, top produits, caissiers, paiements), 14 rapports avec export CSV, produits / catégories / options / menus / favoris / disposition, utilisateurs / rôles / permissions granulaires, entreprise / points de vente / caisses, moyens de paiement, tickets & impression, paramètres POS, journal d'audit.
- **Sécurité** : JWT, BCrypt (mots de passe et PIN), permissions vérifiées côté backend (`@PreAuthorize` + contrôles métier), audit des actions sensibles.

## Tests

```bash
cd backend
mvn test                                   # tests unitaires (calculs, numérotation, tickets)
POSCAISSE_IT=true mvn test                 # + scénario d'intégration complet sur PostgreSQL (login PIN, ouverture, vente, paiement mixte, permissions, remboursement, clôture)
```

## Documentation

- `PROJECT_STATUS.md` — état du projet (terminé / partiel / restant / tests)
- `ARCHITECTURE.md` — décisions structurantes
- `docs/functional-specification.md`, `docs/database-model.md`, `docs/api.md`, `docs/printing.md`, `docs/deployment.md`
- `CHANGELOG.md`, `TODO.md`
