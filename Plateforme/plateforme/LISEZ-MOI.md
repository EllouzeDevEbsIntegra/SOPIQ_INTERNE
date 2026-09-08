# Back-office éditeur

L'application **que nous utilisons**, pas celle du client : nos clients, leurs
abonnements, leurs licences, leurs factures. Base séparée de celle des caisses, et aucune
donnée de vente ici — une faille dans la caisse d'un commerçant ne doit pas donner la
liste de trois cents commerçants.

## Démarrer

```bash
createdb plateforme
mvn spring-boot:run          # http://localhost:8090
```

Premier compte créé automatiquement : **admin / plateforme123**. Le journal le dit en
avertissement au démarrage — **changez-le** avant d'ouvrir quoi que ce soit sur internet.

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
createdb plateforme_it
PLATEFORME_IT=true PLATEFORME_DB_NAME=plateforme_it mvn test
```

Huit scénarios qui suivent un client du prospect à l'impayé : la souscription qui crée la
licence, la deuxième caisse refusée quand une seule est vendue, le règlement qui dépasse le
reste dû, la facture soldée qui passe payée toute seule, la suspension qui laisse la caisse
en lecture seule, et le compte support qui ne peut rien créer.

## Ce qui n'est pas encore là

- **Le provisionnement** : créer la base du client, la migrer, y charger la carte de
  démonstration du métier et rendre les accès. C'est l'étape suivante — le modèle prévoit
  déjà où l'écrire (`abonnement.base_nom`, `url_client`, `provisionne_le`).
- **L'interface** : l'API est complète, l'écran reste à faire.
- **Les relances par courriel** avant suspension.
