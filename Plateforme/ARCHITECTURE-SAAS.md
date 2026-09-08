# La plateforme : architecture

Ce document tranche les questions qu'on ne peut pas laisser ouvertes plus longtemps, et
dit **pourquoi**. Les décisions du 08/09 (un seul code, une base par client, serveur
central) sont le point de départ ; ce qui suit en découle.

---

## 1. Comment une seule application sert des centaines de clients

Trois façons de faire, et une seule tient debout avec « une base par client ».

| | Ce que c'est | Pourquoi pas |
|---|---|---|
| Une application par client | Un processus, un port, une base par boutique | 200 clients = 200 processus à surveiller, mettre à jour, redémarrer. Ingérable à la main, et cher. |
| Une base commune | Tout le monde dans les mêmes tables, séparé par un identifiant de société | Une requête qui oublie le filtre expose les ventes d'un client à un autre. **Écarté le 08/09.** |
| **Une application, N bases** | Un processus, qui choisit la base à chaque requête | ✔ Le cloisonnement est physique, la mise à jour est unique |

**Retenu : une application, une base par client, choisie à chaque requête.**

Concrètement : le jeton d'authentification porte le client (`tenant`). Un filtre le lit,
le pose dans le contexte de la requête, et la source de données aiguille vers la bonne base
— une par client, chacune avec son propre utilisateur PostgreSQL. Le code métier ne change
pas d'une ligne : il ne sait même pas qu'il y a plusieurs clients.

**Ce qui doit être vérifié, et pas supposé :** qu'aucune requête ne parte sans contexte.
Un test le prouvera — une requête sans `tenant` doit échouer bruyamment, jamais tomber sur
une base par défaut.

## 2. Deux applications, pas une

- **La caisse** (`Plateforme/`) : ce que le client utilise. Multi-clients par aiguillage,
  une base par client.
- **Le back-office éditeur** (`Plateforme/plateforme/`) : ce que **nous** utilisons.
  Clients, abonnements, licences, factures, versions. **Sa propre base**, séparée. Il ne
  contient aucune donnée de vente.

Elles ne partagent que le provisionnement : créer un client, c'est créer une base, la
migrer, y charger le profil métier choisi, et rendre un identifiant et un mot de passe.

Pourquoi séparer : ce sont deux métiers, deux publics et deux rythmes de mise à jour. Et
surtout, une faille dans la caisse d'un client ne doit jamais donner accès à la liste de
tous les clients.

## 3. Le cycle de vie d'un client

```
    Prospect ──► Client créé ──► Base provisionnée ──► Abonnement actif
                                        │                    │
                                        ▼                    ▼
                                Profil chargé          Facture émise
                                (démo du métier)       (suivi du règlement)
                                        │                    │
                                        ▼                    ▼
                                Il modifie, ou           Impayé ──► Suspension
                                repart de zéro                        (lecture seule)
```

**« Repartir de zéro »** est un bouton, pas une réinstallation : les scripts existent déjà
(`nettoyer-ventes.sql` efface les ventes, la purge du catalogue efface les articles). Le
client garde son entreprise, ses utilisateurs et ses réglages.

**La suspension n'efface rien** : la caisse passe en lecture seule et affiche la raison.
Couper l'accès aux données d'un commerçant qui a un impayé de 40 dinars serait une faute —
il doit pouvoir sortir son historique quoi qu'il arrive.

## 4. Licences

Une licence = un client, un module (métier), un nombre de caisses, une échéance.

Elle est **vérifiée côté serveur, à chaque ouverture de caisse** — pas par une clé posée
sur le poste, qui se copie. Le poste autonome (le paquet actuel, pour ceux qui ne peuvent
pas dépendre d'internet) reçoit une clé signée avec une date de fin ; il refuse de
s'ouvrir passé un délai de grâce, mais **ne détruit jamais rien**.

## 5. Facturation, sans paiement en ligne

Émission d'une facture par période et par abonnement, avec son numéro, son montant, sa
date d'échéance. Le règlement est **saisi à la main** par nous, quand il arrive (virement,
chèque, espèces). Un impayé au-delà du délai déclenche la suspension — après un rappel,
jamais du jour au lendemain.

C'est volontairement simple : brancher un paiement en ligne demande un contrat bancaire,
une conformité, et un mois de travail. Ça viendra quand il y aura des clients à facturer
automatiquement.

## 6. Sécurité — les règles qui ne se négocient pas

1. **Un utilisateur PostgreSQL par base client.** Le compte qui sert la boutique A ne peut
   pas ouvrir la base de la boutique B. C'est la dernière barrière quand tout le reste a
   échoué.
2. **Le back-office éditeur a sa propre base et ses propres comptes**, avec un deuxième
   facteur. C'est le trousseau de clés de tout le parc.
3. **Aucune requête sans client.** Le défaut n'est pas « la première base » : c'est une
   erreur.
4. **HTTPS partout, jetons courts côté éditeur.**
5. **Sauvegardes par client**, chiffrées, et une restauration testée par trimestre.
6. Le reste est dans `SECURITE.md`, avec ce qui a déjà été corrigé.

## 7. Ce qui existe déjà et qu'il ne faut pas refaire

- La caisse, le back-office client, l'impression, les clôtures, les comptes clients.
- Six cartes de démonstration, une par métier.
- Le paquet autonome (`packaging/`) : c'est la réponse au commerçant qui ne veut pas
  dépendre d'internet, et il restera vendable à côté de l'offre hébergée.
- Les scripts de mise en service : nettoyage des ventes, grille tarifaire, export.

## 8. L'ordre dans lequel construire

1. **Le back-office éditeur** : clients, abonnements, licences, factures, utilisateurs.
   *(Il a de la valeur avant même le multi-clients : il remplace le tableur.)*
2. **Le provisionnement** : créer la base, la migrer, charger le profil, rendre les accès.
3. **L'aiguillage multi-clients** dans la caisse, avec le test qui interdit l'absence de
   contexte.
4. **La suspension** et son écran de lecture seule.
5. **Le portail client** : facture, abonnement, contact.
