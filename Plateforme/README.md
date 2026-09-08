# Plateforme — le code vivant

Ce dossier est **le** code qui évolue. `PosCaisse/` est la verticale Resto livrée à
NUMBER ONE : elle est **figée** et ne bouge plus que pour une anomalie de ce client.
`Plateforme/` en est la copie prise le 08/09/2026, et c'est ici que tout se fait
désormais.

## Un seul logiciel, plusieurs métiers

Le métier n'est pas un logiciel : c'est un **profil**. Un profil apporte

- ses **réglages** (décimales, service à table ou au comptoir, code-barres actif ou non…),
- sa **carte de démonstration** (`catalogs/*.json`),
- les **écrans** qu'il active ou masque.

Le noyau — caisse, panier, encaissement, tickets, sessions, clôtures, comptes clients,
impression — ne se duplique jamais. Une correction faite ici profite à tous les métiers.

| Profil | Carte de démonstration | Particularité |
|---|---|---|
| Resto | `catalogs/number-one-2026.json` | variantes de pâte, stock par pâte |
| Café | `catalogs/mistral-coffee.json` | goûts de chicha en variante, jeux de table |
| Shop | *(à venir)* | code-barres, stock entré à l'achat |

## À faire avant de vendre le profil Resto à un autre client

La carte `number-one-2026.json` est celle d'un **client réel**, avec ses prix. Elle a
servi de base de travail ; elle ne doit pas partir chez un concurrent. Le profil Resto
aura sa propre carte de démonstration, neutre, avant toute mise en vente.

## Ce qui reste de l'installation autonome

`packaging/` fabrique encore le poste autonome (Java + PostgreSQL embarqués). La
plateforme visera un serveur central et des caisses dans le navigateur, mais ce paquet
garde sa valeur : c'est la réponse toute prête au client qui ne peut pas se permettre
qu'une coupure d'internet arrête sa caisse en plein service.
