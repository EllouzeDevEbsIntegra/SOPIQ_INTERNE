# Retour arrière de 1.1.10.0 vers 1.0.9.0, en production

Préparé le 29/09/2026, le soir de la publication, pendant que tout va bien.

## D'abord : faut-il vraiment revenir en arrière ?

Le retour arrière supprime des colonnes en base. Il n'est pas gratuit, et il n'est pas
toujours la bonne réponse.

**Revenir en arrière** si le comptoir est bloqué : la fiche reçu refuse un encaissement
légitime, le reçu ne s'imprime plus, un écran ne s'ouvre plus.

**Corriger en avant** si le problème est visible mais contournable : un montant douteux sur
un rapport, un document qui n'apparaît pas dans une liste, un libellé. Une correction ciblée
publiée dans la journée coûte moins cher qu'un aller-retour de version.

Ce que 1.1.10.0 a changé pour les utilisateurs, donc ce qu'il faut surveiller demain matin :

- la fiche reçu refuse un document sans reste à encaisser ;
- un BL facturé ne ressort plus dans la liste des documents proposés ;
- le reçu est marqué imprimé dès la validation, et non plus par le rapport ;
- le rapport `Etat Solde Client` est corrigé sur les avoirs et retours. Contrôlé le 29/09 :
  aucun document de production n'est affecté aujourd'hui.

## Ce qu'on perd en revenant en arrière

Les champs ajoutés par 1.1.x disparaissent avec leurs données :

| Table | Champs ajoutés |
|---|---|
| `Recu Caisse` (70011) | `Id Brouillon Reapro`, `Contenu Reapro` |
| `Recu Caisse Document` (70012) | `Date Document`, `Reste A Payer`, `Signe`, `Est Fournisseur`, `Type Nom` |

Ces champs ne sont écrits que par l'API appelée par Reapro, qui n'appelle pas encore la
production. Ils doivent donc être vides. **Le vérifier avant de lancer**, avec
`docs/sql/controle-avant-retour-arriere.sql`. S'ils ne le sont plus, c'est que Reapro écrit
en production : arrêter, et en parler avant de rien supprimer.

Les reçus eux-mêmes, leurs documents et leurs paiements ne sont pas touchés : ce sont des
champs d'origine, présents dans les deux versions.

## Le paquet de secours

`D:\ELLOUZE\SOPIQ_INTERNE\retour-arriere\SOPIQ INTERNE_1.0.9.0.app`

Reconstruit le 29/09 à partir du commit `0e78fa4`, qui est l'état exact publié en production
le 28/09 au soir. Il est hors du dépôt, pour ne dépendre ni d'une branche ni de ce qui reste
publié sur le serveur.

## La procédure

Sur le serveur de production 192.168.1.4, dans une console PowerShell **administrateur**.
Copier le fichier `.app` sur le serveur au préalable.

```powershell
# Le module de BC16, sinon c'est celui de BC24 qui se charge et qui refuse
. 'C:\Program Files\Microsoft Dynamics 365 Business Central\160\Service\NavAdminTool.ps1'

# 1. Constat : quelles versions sont publiées, laquelle est installée
Get-NAVAppInfo -ServerInstance BC160 -Name 'SOPIQ INTERNE'

# 2. Désinstaller la version en cours, sans effacer les données
Uninstall-NAVApp -ServerInstance BC160 -Name 'SOPIQ INTERNE' -Version 1.1.10.0

# 3. Si 1.0.9.0 n'apparaît plus comme publiée à l'étape 1, la republier
Publish-NAVApp -ServerInstance BC160 -Path 'C:\Temp\SOPIQ INTERNE_1.0.9.0.app' -SkipVerification

# 4. Resynchroniser le schéma. ForceSync est indispensable : c'est lui qui supprime les
#    colonnes ajoutées par 1.1.x, et sans lui la synchronisation est refusée
Sync-NAVApp -ServerInstance BC160 -Name 'SOPIQ INTERNE' -Version 1.0.9.0 -Mode ForceSync

# 5. Réinstaller
Install-NAVApp -ServerInstance BC160 -Name 'SOPIQ INTERNE' -Version 1.0.9.0

# 6. Vérifier : 1.0.9.0 installée, 1.1.10.0 publiée mais non installée
Get-NAVAppInfo -ServerInstance BC160 -Name 'SOPIQ INTERNE'
```

Puis ouvrir Business Central sur une société et vérifier qu'un écran du chantier reçu se
comporte de nouveau comme avant.

## Si `Publish-NAVApp` échoue

Il a déjà échoué sur ce serveur le 28/09, sur une erreur de symboles introuvables. Dans ce
cas, passer par Visual Studio Code, qui est le chemin qui a fonctionné ce jour-là :

```
git worktree add ../retour-arriere-src 0e78fa4
```

Ouvrir ce dossier dans Visual Studio Code, sélectionner la configuration **SOPIQ PROD**, y
passer `schemaUpdateMode` à `ForceSync`, puis Ctrl+F5. Faire les étapes 1 et 2 ci-dessus
avant, sinon Business Central refuse d'installer une version plus ancienne que celle en
place.

## Après

Republier 1.1.10.0 n'est pas un problème : c'est une version plus récente, elle se réinstalle
par le chemin habituel. Les champs supprimés sont recréés vides.
