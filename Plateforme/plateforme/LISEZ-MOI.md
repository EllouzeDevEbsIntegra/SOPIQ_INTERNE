# Back-office éditeur

L'application **que nous utilisons**, pas celle du client : nos clients, leurs
abonnements, leurs licences, leurs factures. Base séparée de celle des caisses, et aucune
donnée de vente ici — une faille dans la caisse d'un commerçant ne doit pas donner la
liste de trois cents commerçants.

## Démarrer

```bash
createdb plateforme
read -r -s -p 'Mot de passe initial administrateur : ' PLATEFORME_ADMIN_PASSWORD
export PLATEFORME_ADMIN_PASSWORD
mvn spring-boot:run          # http://localhost:8090
```

Premier compte créé automatiquement : **admin**, avec le secret fourni dans
`PLATEFORME_ADMIN_PASSWORD` (12 caractères au minimum). Sans ce secret, une base neuve
refuse de démarrer. Aucun mot de passe n'est journalisé. Une installation ayant déjà un
compte ne demande plus cette variable ; retirez-la après le premier démarrage.

Réglages (variables d'environnement) : `PLATEFORME_DB_*`, `PLATEFORME_PORT`,
`PLATEFORME_JWT_SECRET` (sinon une clé propre à l'installation est tirée au sort),
`PLATEFORME_CORS_ORIGINS`, `PLATEFORME_JOURS_SUSPENSION` (15 par défaut).

## Ce qu'il fait

| | |
|---|---|
| **Clients** | prospect → actif → suspendu → résilié, avec le contact et la ville |
| **Abonnements** | un métier, un nombre de caisses, un prix mensuel, une échéance |
| **Licences** | une clé par abonnement, vérifiée **au serveur** à chaque ouverture de caisse |
| **Facturation** | émission par période, règlements saisis à la main, solde déduit |
| **Impayés** | la liste des retards, et la suspension quand elle est décidée |
| **Journal** | qui a fait quoi, jamais effacé |

## Les trois décisions qui comptent

**La licence est vérifiée au serveur.** Une clé posée dans un fichier sur le poste se copie
d'une machine à l'autre et on ne le sait jamais. Ici, la caisse demande, le serveur répond,
et le nombre de postes vendus est celui qui ouvre.

**Suspendu n'est pas coupé.** Un impayé met la caisse en **lecture seule** et le dit en
français : *« Vos données sont intactes — contactez votre fournisseur »*. Prendre ses
données à un commerçant pour quarante dinars serait une faute, et un argument que la
concurrence utiliserait.

**Le solde ne se stocke pas.** Facture moins règlements : un solde écrit quelque part finit
toujours par ne plus correspondre à son détail, et c'est le détail qu'on montre au client
quand il conteste.

## L'API en un coup d'œil

```
POST /api/auth/connexion              → jeton (2 h)
GET  /api/tableau-de-bord             → clients, caisses, récurrent mensuel, retards
GET  /api/clients                     · POST /api/clients
POST /api/clients/{id}/abonnements    → souscrire (crée la licence)
POST /api/clients/{id}/suspendre      · POST /api/clients/{id}/reactiver
POST /api/abonnements/{id}/factures   → émettre
POST /api/factures/{id}/reglements    → encaisser
GET  /api/factures/en-retard          · POST /api/factures/suspendre-les-retards
POST /api/licences/verifier           → PUBLIC : ce qu'appelle une caisse en s'ouvrant
```

## Les rôles

- **ADMIN** — tout, y compris les comptes de l'équipe.
- **COMMERCIAL** — clients, abonnements, factures. Ni règlements, ni comptes.
- **SUPPORT** — lecture seule.

Un refus nomme le rôle et ce qui manque : *« votre rôle SUPPORT ne permet pas gérer les
clients — demandez à un administrateur »*. « Permission refusée » n'apprend rien à
personne.

## Tests

```bash
PLATEFORME_IT=true mvn test
```

Rien à créer à la main : le scénario refait sa base `plateforme_test` à chaque exécution.
Il travaillait auparavant sur la base de démonstration, et comptait donc les clients que
l'on venait d'y créer au navigateur : le chiffre d'affaires récurrent attendu à 49 dinars
en trouvait 207. Une base à lui, et ce qu'il compte est ce qu'il a fait.

Neuf scénarios qui suivent un client du prospect à l'impayé : la souscription qui crée la
licence, la deuxième caisse refusée quand une seule est vendue, le règlement qui dépasse le
reste dû, la facture soldée qui passe payée toute seule, la numérotation qui se suit d'une
facture à l'autre, la suspension qui laisse la caisse en lecture seule, le provisionnement
qui crée vraiment la base et ne rend jamais deux fois le mot de passe, et le compte support
qui ne peut rien créer.

## Le provisionnement

« Préparer la base du client » crée la base, un utilisateur PostgreSQL qui n'a de droits
que sur elle, et rend les accès **une seule fois** — le mot de passe n'est stocké nulle
part. La boîte demande d'abord si le client part de la carte de démonstration de son métier
ou d'un catalogue vide, puis rend la commande de lancement : la caisse y lit son métier et
son enseigne, pose son schéma, ses réglages et sa carte toute seule au premier démarrage.

Le détail des six métiers et la façon d'en ouvrir un septième : `../PROFILS-METIER.md`.

## Ce qui n'est pas encore là

- **L'écran définitif** : l'interface actuelle est d'un seul fichier, sans le système de
  design de la caisse. Elle montre tout ce que l'API sait faire, elle n'est pas jolie.
- **Les relances par courriel** avant suspension.
