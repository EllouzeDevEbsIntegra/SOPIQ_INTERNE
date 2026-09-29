# Scripts SQL du projet

Vingt-deux scripts, rangés par usage. Quinze scripts de diagnostic à usage unique ont été
retirés le 29/09/2026, leurs chantiers étant terminés ; ils restent accessibles dans
l'historique Git si le besoin revenait.

**Règle de lecture** : tout script qui écrit le dit dans son en-tête. Les autres ne font que
lire.

## À garder sous la main, ils reservent

| Script | Usage |
|---|---|
| `mesure-tableau-de-bord.sql` | mesurer ce que coûte l'ouverture d'une page, par écart de compteurs avant et après |
| `maj-refs-tables-non-cascadees.sql` | après un renommage, mettre à jour les tables que Business Central n'atteint pas |
| `controle-renommage-vehicules.sql` | lire le journal d'un renommage, en simulation comme en réel |
| `controle-apres-renommage-vehicules.sql` | vérifier qu'aucun ancien numéro ne subsiste, à partir du journal |
| `detection-refs-vehicules-non-cascadees.sql` | avant un renommage, chercher qui porte les numéros visés |
| `collisions-numeros-modele-version.sql` | détecter les numéros qui désignent un véhicule ici et une pièce ailleurs |

## Les retours arrière, à ne pas supprimer

| Script | Ce qu'il permet d'annuler |
|---|---|
| `vue-elva-item-reecriture-prod.sql` | la définition d'origine de la vue `ELVA_Item`, en fin de fichier |
| `index-prod-reference-origine.sql` | le retrait de l'index posé en production le 26/09/2026 |
| `index-liste-articles.sql` | les douze index de la liste articles, avec leur suppression |
| `index-temporaires-renommage.sql`, `-2.sql` | les index posés pour accélérer un renommage |
| `sauvegarde-avant-renommage-vehicules.sql` | les deux tables de sauvegarde du 28/09/2026, encore présentes en production |

## Les contrôles récurrents

| Script | Ce qu'il vérifie |
|---|---|
| `controle-prix-bs-apres-correctif.sql` | qu'aucun prix de BS ne repasse à zéro. Vérifié le 29/09/2026 : zéro sur 303 lignes |
| `controle-vue-elva-prod.sql` | que la vue réécrite rend exactement ce que rendait l'ancienne |
| `controle-copim.sql`, `controle-copim-cout.sql` | la couverture des liens de coût des requêtes du tableau de bord Direction |
| `controle-avoirs-retours-caisse.sql` | l'effet de la correction des avoirs et retours, avec l'exemple à montrer à la caisse |
| `recap-avoirs-timbre-prod.sql` | le recensement des avoirs portant un timbre fiscal |
| `controle-expeditions-nova.sql` | contrôle des expéditions Nova |

## Les réparations de données déjà exécutées

Conservées comme trace de ce qui a été modifié en production, et non pour être relancées.

| Script | Date | Portée |
|---|---|---|
| `reparation-prix-bs-copim.sql` | 25/09/2026 | 13 441 lignes de BS remises au prix d'origine |
| `reparation-prix-bs-cas-particuliers.sql` | 25/09/2026 | 10 lignes traitées à part |

## Le reste

`test-vue-elva-complete.sql` sert à comparer deux versions de la vue `ELVA_Item` colonne par
colonne. Il resservira le jour où elle sera retouchée.
