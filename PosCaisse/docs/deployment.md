# Déploiement

## Mise à jour et redémarrage (le plus simple)

`RESTART_POS.bat` (Windows) ou `./restart.sh` : arrêt des instances, `git pull`, préparation de la base, recompilation seulement si le code a changé, démarrage et ouverture du navigateur. C'est le script à utiliser au quotidien.

Sous Windows, les `.bat` ne sont que des lanceurs d'une ligne ; la séquence complète vit dans `restart.ps1` et la préparation de la base dans `init-db.ps1` (PowerShell 5.1, livré avec Windows, aucune installation). `cmd.exe` casse silencieusement sur les scripts longs — d'où ce découpage. Le dépôt force les fins de ligne CRLF sur `.bat`/`.ps1` via `.gitattributes` : sans cela `cmd.exe` mal-interprète les fichiers et la fenêtre se referme sans rien lancer.

## Développement (PC caisse ou poste de dev)
- `START_POS.bat` (Windows) : PostgreSQL, base, puis backend sur 8080 — sans rien arrêter et sans `git pull`. Si PosCaisse répond déjà, le navigateur s'ouvre simplement. Le backend sert l'interface déjà compilée (`frontend/dist`).
- `./start.sh` (Linux/macOS) : idem, avec le frontend Vite (5173, proxy `/api`) si `frontend/dist` est absent.
- Pour développer l'interface avec rechargement à chaud : `cd frontend && npm run dev` (5173), le backend restant sur 8080.
- La base `poscaisse` est créée automatiquement au lancement si elle n'existe pas (`INIT_DB.bat` fait la même chose seul). Variables : `.env.example`, notamment `POSCAISSE_DB_PASSWORD` si votre mot de passe `postgres` n'est pas `postgres`.

### Dépannage démarrage

| Message dans la fenêtre backend | Solution |
|---|---|
| `la base de données « poscaisse » n'existe pas` | `INIT_DB.bat` ou `psql -U postgres -c "CREATE DATABASE poscaisse;"` |
| `password authentication failed for user "postgres"` | définir `POSCAISSE_DB_PASSWORD` |
| `Connection refused` / `Connection to localhost:5432 refused` | démarrer le service PostgreSQL ou Docker Desktop |
| `Port 8080 was already in use` | définir `POSCAISSE_PORT` sur un autre port |

## Production locale (un seul port)
1. `BUILD_POS.bat` (ou `cd frontend && npm run build` puis `cd backend && mvn package`).
2. `START_POS.bat` (ou `RESTART_POS.bat`) lance `backend\target\poscaisse-backend.jar`, qui sert `frontend\dist` sur **http://localhost:8080** (SPA fallback) ; le navigateur de la caisse s'ouvre dessus.
3. Définissez impérativement `POSCAISSE_JWT_SECRET` (≥ 64 caractères) et un mot de passe PostgreSQL dédié ; changez les PIN/mots de passe de démonstration ; mettez `POSCAISSE_DEMO_DATA=false` sur une base de production (le jeu de démo n'est de toute façon chargé que sur une base vide).

## Multi-caisses
Plusieurs postes peuvent pointer vers le même backend (`http://<ip-serveur>:8080`) : chaque poste ouvre sa propre caisse (CAISSE 01, CAISSE 02…). Ajoutez l'origine du frontend à `POSCAISSE_CORS_ORIGINS` si le frontend est servi séparément.

## Sauvegardes
`pg_dump -U postgres poscaisse > backup.sql` (planifiez-le quotidiennement, après la clôture journalière).

## Mises à jour du schéma
Nouvelles migrations Flyway `V2__…sql` dans `backend/src/main/resources/db/migration` ; appliquées automatiquement au démarrage.
