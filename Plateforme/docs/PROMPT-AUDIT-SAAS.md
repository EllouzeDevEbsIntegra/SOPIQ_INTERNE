# Prompt d'audit — à coller dans Codex, Antigravity ou tout agent de code

Ce fichier est un **prompt**, pas une documentation. Il est versionné pour être rejoué à
l'identique d'un audit à l'autre : deux campagnes comparables valent mieux que deux
campagnes brillantes et incomparables.

---

Tu es chargé d'auditer et de durcir **PosCaisse SaaS**, une caisse tactile commerciale
vendue en abonnement à des commerçants tunisiens (restauration, café, supérette,
prêt-à-porter, pâtisserie, parfumerie). Le dépôt est en français : commentaires, messages
d'erreur, noms de tests. Continue dans cette langue.

## 1. Le périmètre, et ce qui est interdit

Le dossier de travail est `Plateforme/`. Il contient **quatre** parties :

| Chemin | Ce que c'est |
|---|---|
| `Plateforme/backend/` | La caisse (Spring Boot 3.5, Java 21, PostgreSQL 16, Flyway). Un processus par client. |
| `Plateforme/frontend/` | L'écran de vente et le back-office du commerçant (Vue 3.5, Vite 6, Pinia 3). |
| `Plateforme/plateforme/` | Le back-office **éditeur** : clients, abonnements, licences, factures, démos, provisionnement. Son interface est un unique `index.html` statique dans le JAR — pas de Node. |
| `Plateforme/deploiement/` | systemd, nginx, sudoers, et les scripts d'ouverture (`poscaisse-ouvrir`, `preparer-demos.sh`). |

**INTERDITS ABSOLUS** :

1. **Ne touche jamais à `PosCaisse/`** (à la racine du dépôt, hors `Plateforme/`). C'est la
   version 1 livrée à un client réel, en exploitation. `Plateforme/` en est la copie qui
   évolue.
2. **Aucun paiement en ligne** dans le back-office éditeur. C'est une décision produit :
   ne l'introduis pas, même « en préparation ».
3. Ne lance rien contre le serveur de production (`135.125.100.21`,
   `*.pos.ebs-integra.com`). Tout se teste en local.
4. Ne désactive, ne saute et ne mets en quarantaine **aucun test** pour obtenir du vert.

## 2. Comment faire tourner tout ça

Il te faut un PostgreSQL 16 local. `docker compose up -d postgres` depuis `Plateforme/`
en fournit un, sinon un PostgreSQL local convient.

```bash
# La caisse — 107 tests
cd Plateforme/backend
export POSCAISSE_IT=true POSCAISSE_DB_HOST=127.0.0.1 POSCAISSE_DB_USER=postgres POSCAISSE_DB_PASSWORD=postgres
mvn test

# Le back-office éditeur — 26 tests
cd ../plateforme
export PLATEFORME_IT=true PLATEFORME_DB_HOST=127.0.0.1 PLATEFORME_DB_USER=postgres PLATEFORME_DB_PASSWORD=postgres
mvn test

# L'interface
cd ../frontend
npm ci && npm run build && npm test
```

**Commence par établir la ligne de base** : lance tout, note ce qui passe et ce qui ne
passe pas, et ne change rien tant que tu n'as pas ce chiffre. Un audit qui commence par
une correction ne sait pas ce qu'il a cassé.

## 3. Ce qu'il faut auditer

Pour **chaque** point : dis si c'est tenu, et **prouve-le par un test qui échoue quand la
protection est retirée**. Une affirmation sans test n'a aucune valeur ici.

### 3.1 Sécurité — c'est l'axe prioritaire

Le cloisonnement entre clients est la promesse commerciale du produit. Une fuite d'un
client vers un autre tue l'entreprise, pas seulement la fonctionnalité.

- **Cloisonnement des bases.** Une base et un rôle PostgreSQL par client (`BasesPostgres`).
  Vérifie que le compte du client A ne peut ni ouvrir la base de B, ni endosser son rôle.
  Vérifie aussi que le compte qui provisionne ne garde aucune appartenance après coup.
- **Le préfixe `posdemo_` est une frontière de sécurité** : le seul endroit du logiciel qui
  SUPPRIME une base refuse tout nom qui ne commence pas par lui. Essaie de la franchir.
- **Authentification** : JWT (12 h) et code PIN à 4 chiffres en caisse. Le ralentisseur
  anti-force-brute compte par adresse (`X-Forwarded-For`). Vérifie qu'il ne se contourne
  pas, et qu'il ne bloque pas tout le magasin pour un seul poste fautif.
- **Autorisations** : chaque endpoint doit exiger sa permission. Cherche celui qui ne le
  fait pas — un caissier ne doit pas lire la marge, ni un client la liste des clients.
- **Injection** : les noms d'objets PostgreSQL (bases, rôles) entrent dans des instructions
  qui ne se paramètrent pas. Vérifie que rien de saisissable n'y arrive jamais.
- **CORS** : l'origine servie par l'application est autorisée d'office (même origine
  reconstruite depuis `Host` + `X-Forwarded-Proto`). Vérifie qu'ouvrir sa propre origine
  n'ouvre **pas** celle des autres.
- **Secrets** : cherche tout secret en dur, tout mot de passe journalisé, tout mot de passe
  passé en argument de commande (lisible dans `ps` par n'importe quel compte).
- **En-têtes** : HSTS, `X-Frame-Options`, `X-Content-Type-Options`, CSP. La caisse ne doit
  pas pouvoir être affichée dans un cadre sur un autre site.
- **Traversée de chemin et injection de commande** dans les scripts de `deploiement/` :
  ils prennent des noms qui deviennent des noms de fichiers, d'unités systemd et de
  directives nginx.
- Relis `Plateforme/SECURITE.md` : il liste sept défauts déjà corrigés et ce qui reste à
  faire. **Vérifie que les sept corrections tiennent toujours**, et attaque la liste des
  restants.

### 3.2 Multi-tenant — le chantier ouvert

Aujourd'hui : **un processus par client**, une base par client. `ARCHITECTURE-SAAS.md`
décrit la cible : une application, N bases, le client porté par le jeton et la source de
données aiguillée à chaque requête.

Écris le test qui manque et que le document réclame : **une requête sans contexte client
doit échouer bruyamment, jamais retomber sur une base par défaut.** Puis dis honnêtement
ce qu'il faudrait pour y arriver, et ce que ça coûte.

### 3.3 Temps de réponse

Mesure, ne suppose pas. Sur un catalogue réaliste (187 articles pour la supérette, 112
pour le café) :

- L'ouverture de l'écran de vente et le chargement du catalogue.
- Un encaissement complet, de la première tuile touchée au ticket rendu.
- Les rapports et la clôture journalière sur un mois de ventes — génère les données.
- Le back-office éditeur avec 200 clients et leurs factures : cherche les requêtes N+1,
  elles ne se voient pas à 3 clients.

Donne des chiffres (médiane et p95), pas des adjectifs. Dis lesquels sont acceptables
pour une caisse : un caissier qui attend, c'est une file d'attente qui s'allonge.

### 3.4 Interface

- **Tactile** : les cibles sont-elles atteignables au doigt, sur un écran de 15 pouces
  comme sur une tablette ? Teste en 1024×768, 1366×768 et 1920×1080.
- **Le vocabulaire est-il vrai pour les six métiers ?** Un écran qui parle de cuisine chez
  un parfumeur est un défaut, pas un détail. Cherche les autres.
- **Accessibilité** : contrastes, navigation au clavier, libellés de champs.
- **Les erreurs disent-elles quoi faire ?** Un message qui décrit le problème sans donner
  la suite fait appeler le support.
- Vérifie les six profils métier : chacun doit démarrer avec ses réglages, sa carte, et
  **rien qui appartienne au commerce d'un autre**.

### 3.5 Tests

- Où la couverture ment-elle ? Cherche le code critique sans test : calcul de prix et de
  remises, TVA, rendu de monnaie, numérotation des tickets, clôture, remboursements.
- **Les tests sont-ils rejouables ?** Chaque scénario doit pouvoir tourner deux fois de
  suite. Ceux qui laissent une caisse ouverte ou un catalogue purgé derrière eux ne
  passent qu'une fois, et cela ne se voit que des mois plus tard.
- Ajoute les tests de bord : montants négatifs, quantités nulles, vente au poids à zéro,
  concurrence de deux caisses sur le même ticket, base injoignable au démarrage.

### 3.6 Exploitation

- Que se passe-t-il si PostgreSQL tombe pendant une vente ? Si le disque est plein ?
- Les sauvegardes : existent-elles, et **ont-elles déjà été restaurées** ? Une sauvegarde
  jamais restaurée n'est pas une sauvegarde.
- Les journaux disent-ils assez pour diagnostiquer sans reproduire ? Contiennent-ils des
  données personnelles ou des secrets ?
- Les migrations Flyway sont-elles rejouables et réversibles ? Que fait une migration sur
  une base d'un client en service, avec ses données à lui ?

## 4. Comment livrer

1. **Un rapport** `Plateforme/docs/AUDIT-<date>.md` : ce qui a été vérifié, comment, avec
   les chiffres. Classe les défauts par **ce qu'ils coûtent** — une fuite entre clients
   n'est pas un libellé mal choisi — et pour chacun : comment le reproduire, la correction
   proposée, et le test qui la garde.
2. **Un test par défaut trouvé, écrit AVANT la correction**, et dont tu montres qu'il
   échoue sans elle. Colle le message d'échec dans le rapport.
3. **Les corrections**, une par commit, chacune avec son test.
4. **Ce que tu n'as pas pu vérifier**, et pourquoi. C'est la partie la plus utile du
   rapport : elle dit où regarder ensuite.

Ne présente rien comme vérifié que tu n'aies mesuré. Si un test échoue, dis-le avec sa
sortie. Si une étape a été sautée, dis-le. Un audit qui n'a rien trouvé n'est pas un bon
audit : c'est un audit qui n'a pas cherché.
