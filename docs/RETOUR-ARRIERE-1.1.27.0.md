# Retour arrière de 1.1.27.0 vers 1.1.13.0, en production

Préparé le 01/10/2026, le soir de la publication, pendant que tout va bien.

Publiée en production le 01/10/2026 au soir, en même temps que la mise en production de Reapro.
C'est la première version dont les API sont **réellement appelées en production** : la surface de
risque n'est plus l'écran de Business Central, c'est Reapro.

## D'abord : faut-il vraiment revenir en arrière ?

**Revenir en arrière** si Business Central lui-même se dégrade pour les utilisateurs du bureau :
un écran qui ne s'ouvre plus, une impression qui échoue, une liste qui refuse de s'afficher.

**Corriger en avant** si le problème est dans Reapro ou dans une API : l'écran web se trompe, une
action web échoue, un PDF sort mal. Ces chemins ne servent qu'à Reapro ; une correction ciblée
publiée dans la journée coûte beaucoup moins cher qu'un retour arrière, et le retour arrière
casserait Reapro en entier plutôt que de réparer un bout.

**Troisième voie, souvent la bonne** : demander à l'équipe web de suspendre l'écran fautif dans
Reapro. Business Central reste en 1.1.27.0 et les utilisateurs du bureau ne voient rien.

## Ce que cette version change pour les utilisateurs du bureau

C'est la liste à surveiller demain matin. Tout le reste ne concerne que Reapro.

- **Administration des clients** (page 50117) : la liste n'écrit plus en base à chaque ligne
  affichée, et la colonne « Dep Enc Princ. » est calculée à l'affichage. À vérifier : la colonne
  montre la même valeur qu'avant, et la liste est plus rapide.
- **Les six états COPIM** (BS, BL, facture, avoir, devis, réception de retour) : la condition qui
  enregistre le client imprimé sur le document a changé. À vérifier : en impression manuelle depuis
  Business Central, avec la case « Modifier information client à imprimer » cochée, le nom saisi
  doit toujours être enregistré sur le document. En impression depuis Reapro, il ne doit **pas**
  être réécrit.
- **Commande vente EBS** (page API 25006816) : quatre champs exposés en plus et une action
  d'expédition. Page déjà utilisée en production avant cette version : si une intégration
  existante s'en sert, c'est le point à regarder en premier.

## Ce qu'on perd en revenant en arrière

| Table | Champs supprimés | Ce que ça détruit |
|---|---|---|
| `Recu Caisse` (70011) | `Version Correction`, `Historique Corrections` | l'historique des corrections de reçu envoyées par Reapro |

**La différence avec le retour arrière du 29/09** : ce jour-là, Reapro n'appelait pas la production
et ces colonnes étaient forcément vides. Ce n'est plus vrai depuis le 01/10. Lancer d'abord
`docs/sql/controle-avant-retour-arriere-1.1.27.sql` : s'il rend autre chose que des zéros, le retour
arrière détruit des données réelles. Exporter ces lignes avant, ou choisir de corriger en avant.

Les reçus, leurs documents et leurs paiements ne sont pas touchés : ce sont des champs présents dans
les deux versions.

Les dix-neuf pages API ajoutées depuis 1.1.13 disparaissent, sans perte de données : elles ne
stockent rien, elles lisent et écrivent des documents standard. Mais **Reapro perd d'un coup
l'impression des documents COPIM, les devis, le panier BS, les brouillons de facture et d'avoir, et
la correction de reçu.** Autrement dit : revenir en arrière ici, c'est arrêter Reapro.

## Le paquet de secours

`D:\ELLOUZE\SOPIQ_INTERNE\retour-arriere\SOPIQ INTERNE_1.1.13.0.app`

Reconstruit le 01/10 à partir du commit `e357336`, qui est l'état exact publié en production depuis
le 30/09. Il est hors du dépôt, pour ne dépendre ni d'une branche ni de ce qui reste publié sur le
serveur.

## La procédure

Sur le serveur de production **192.168.1.4**, instance **BC160** (la base s'appelle
`SOPIQ_PROD_BC16`, l'instance non : ne pas la chercher sous ce nom). Console PowerShell
**administrateur**. Copier le fichier `.app` sur le serveur au préalable.

```powershell
# Le module de BC16, sinon c'est celui de BC24 qui se charge et qui refuse
. 'C:\Program Files\Microsoft Dynamics 365 Business Central\160\Service\NavAdminTool.ps1'

# 1. Constat : quelles versions sont publiees, laquelle est installee
Get-NAVAppInfo -ServerInstance BC160 -Name 'SOPIQ INTERNE'

# 2. Desinstaller la version en cours, sans effacer les donnees
Uninstall-NAVApp -ServerInstance BC160 -Name 'SOPIQ INTERNE' -Version 1.1.27.0

# 3. Si 1.1.13.0 n'apparait plus comme publiee a l'etape 1, la republier
Publish-NAVApp -ServerInstance BC160 -Path 'C:\Temp\SOPIQ INTERNE_1.1.13.0.app' -SkipVerification

# 4. Resynchroniser le schema. ForceSync est indispensable : c'est lui qui supprime les deux
#    colonnes ajoutees, et sans lui la synchronisation est refusee
Sync-NAVApp -ServerInstance BC160 -Name 'SOPIQ INTERNE' -Version 1.1.13.0 -Mode ForceSync

# 5. Reinstaller
Install-NAVApp -ServerInstance BC160 -Name 'SOPIQ INTERNE' -Version 1.1.13.0

# 6. Verifier : 1.1.13.0 installee, 1.1.27.0 publiee mais non installee
Get-NAVAppInfo -ServerInstance BC160 -Name 'SOPIQ INTERNE'
```

Les deux instances du serveur de production, `BC160` et `BC160-PRODWS`, partagent la même base :
publier sur `BC160` suffit, la seconde suit.

Puis ouvrir Business Central sur une société, vérifier qu'un écran se comporte comme avant, et
**prévenir l'équipe web immédiatement** : leurs écrans tombent au même instant.
