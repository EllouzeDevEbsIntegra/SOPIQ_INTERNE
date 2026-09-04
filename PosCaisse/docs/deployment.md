# Déploiement

## Développement (PC caisse ou poste de dev)
- `START_POS.bat` (Windows) / `./start.sh` : PostgreSQL (Docker si possible), backend `mvn spring-boot:run` (8080), frontend `npm run dev` (5173, proxy `/api`).
- Variables : `.env.example`. Sans Docker, créez la base `poscaisse` sur votre PostgreSQL local et ajustez `POSCAISSE_DB_*`.

## Production locale (un seul port)
1. `BUILD_POS.bat` (ou `cd frontend && npm run build` puis `cd backend && mvn package`).
2. `START_POS.bat` détecte `backend\target\poscaisse-backend.jar` et `frontend\dist` : le backend sert l'application sur **http://localhost:8080** (SPA fallback) ; le navigateur de la caisse s'ouvre dessus.
3. Définissez impérativement `POSCAISSE_JWT_SECRET` (≥ 64 caractères) et un mot de passe PostgreSQL dédié ; changez les PIN/mots de passe de démonstration ; mettez `POSCAISSE_DEMO_DATA=false` sur une base de production (le jeu de démo n'est de toute façon chargé que sur une base vide).

## Multi-caisses
Plusieurs postes peuvent pointer vers le même backend (`http://<ip-serveur>:8080`) : chaque poste ouvre sa propre caisse (CAISSE 01, CAISSE 02…). Ajoutez l'origine du frontend à `POSCAISSE_CORS_ORIGINS` si le frontend est servi séparément.

## Sauvegardes
`pg_dump -U postgres poscaisse > backup.sql` (planifiez-le quotidiennement, après la clôture journalière).

## Mises à jour du schéma
Nouvelles migrations Flyway `V2__…sql` dans `backend/src/main/resources/db/migration` ; appliquées automatiquement au démarrage.
