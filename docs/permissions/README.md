# Permissions du compte API

## Pourquoi ce dossier existe

En Business Central 16, un jeu de permissions **ne peut pas être livré dans l'extension**. Le
compilateur est catégorique :

```
error AL0666: 'PermissionSet, PermissionSetExtension, and License Support' is not available
in runtime version '5.0'. The supported runtime versions are: '7.0' or greater.
```

L'objet `permissionset` n'existe qu'à partir du runtime 7.0, soit Business Central 20. Jusque-là,
les permissions sont des **données**, pas du code : elles vivent dans la base, pas dans le `.app`.

Conséquence directe : un objet ajouté à l'extension fonctionne immédiatement pour un
administrateur, et échoue pour le compte de l'API tant que personne n'a mis à jour son jeu de
permissions. C'est ce qui s'est passé le 28/09/2026 sur le premier reçu envoyé par Reapro :

```
You do not have the following permissions on Table Recu Caisse Demande: Execute.
```

Ce dossier sert à ce que cela ne se reproduise pas : le jeu de permissions est versionné avec le
code, et se met à jour dans le même commit que l'objet qu'il couvre.

## Le fichier

`SOPIQ-RECU-API.xml` — jeu de permissions du compte de service utilisé par Reapro pour le reçu
de caisse.

Il ne contient **que** les objets de l'extension : tables du reçu, codeunit de validation, pages
API, état du reçu. Les tables métier — factures, avoirs, expéditions, retours — n'y sont pas, et
c'est voulu : le codeunit et les pages portent la propriété `Permissions`, qui accorde ces droits
seulement pendant leur exécution. Le compte API ne peut donc pas lire ni écrire un document de
vente autrement qu'à travers ces objets.

## Comment l'installer

1. dans Business Central, rechercher **Jeux d'autorisations** ;
2. action **Importer les jeux d'autorisations**, choisir `SOPIQ-RECU-API.xml` ;
3. ouvrir la fiche du compte de service utilisé par Reapro, onglet des jeux d'autorisations, et
   ajouter **SOPIQ-RECU-API** ;
4. refaire l'opération sur chaque base : DEV et production sont indépendantes.

Un réimport écrase le jeu existant sans toucher aux affectations : c'est la façon normale de le
mettre à jour après l'ajout d'un objet.

## La règle à tenir

**Tout nouvel objet accessible par l'API entre dans ce fichier, dans le même commit.** Table,
page, codeunit, état. Sans cela, l'objet marchera chez nous et échouera chez Reapro, avec un
message qui ne dit pas grand-chose à qui ne connaît pas ce mécanisme.

Objets restant à ajouter quand ils existeront : la page `getPdfRecuCaisse`, le journal des
corrections de reçu, et l'état ticket 80 mm.
