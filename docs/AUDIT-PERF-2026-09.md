# SOPIQ INTERNE — Audit global performance & qualité de code

> **Date** : 2026-09-05 · **Version analysée** : 1.0.0.1 · **Branche** : `fix/references-externes`
> **Contexte** : BC16 OnPrem (runtime 5.0), extension en PRODUCTION sur 5 sociétés.
> **Règle de travail** : aucune refonte. Un correctif à la fois → DEV → PROD → test → suivant.
> Chaque chantier ci-dessous est autonome et réversible (1 commit = 1 chantier).

---

## 0. Chiffres de départ

| Indicateur | Valeur | Commentaire |
|---|---:|---|
| Fichiers AL | 459 | 80 481 lignes |
| PageExt / Page / TableExt / Report | 102 / 88 / 62 / 61 | |
| WebService + NovaApi | 78 | surface d'intégration importante |
| `OnAfterGetRecord` | 249 | dont **187 avec accès base** |
| `CalcFields` | 279 | |
| `FindFirst` | 270 | vs 93 `FindSet` — beaucoup de `Get()` déguisés |
| `SetCurrentKey` | 19 | très faible pour 80k lignes |
| FlowFields déclarés par l'extension | 187 | |
| **Clés déclarées dans les 62 `tableextension`** | **1** | ⚠️ racine n°1 — la seule est `Tab27.AlerteMgStk` |
| Lignes de code commenté | 3 803 | ~5 % du code |
| Poids du dépôt `.git` | 249 Mo | `.app` + `.alpackages` versionnés |

---

## 1. Les 5 causes racines

Presque tous les ralentissements observés remontent à cinq mécanismes. Les comprendre évite
de traiter les symptômes un par un.

### R1 — Filtrer ou agréger sur un FlowField
En AL, un `SetRange`/`SetFilter` posé sur un champ `FieldClass = FlowField`, ou une
`CalcFormula` dont le `WHERE` référence un autre FlowField, **interdit à SQL d'utiliser le
moindre index**. Le serveur doit matérialiser le FlowField ligne par ligne avant de filtrer.
Sur `Item Ledger Entry` ou `Sales Shipment Line`, c'est un scan complet + une sous-requête
par ligne.

C'est le mécanisme documenté dans le commentaire déjà présent en tête de
[Cod50025.KPIManagement.al](../src/CodeUnit/Cod50025.KPIManagement.al) — le diagnostic est bon,
il n'a simplement pas encore été appliqué partout.

### R2 — Aucun index sur les champs custom
Les 62 `tableextension` ajoutent des dizaines de champs (`solde`, `BS`, `Special Order`,
`year`, `Price modified`, `Reference Origine Liée`, `STOuvert`…) qui sont massivement filtrés.
Une **seule** clé est déclarée dans tout ce périmètre (`Tab27-Ext80103` → `key(AlerteMgStk)`,
ajoutée avec `UpdateAlertesMgStk`). Tous les autres filtres = scan de table standard BC.

### R3 — Travail par ligne dans les listes
187 `OnAfterGetRecord` déclenchent des `CalcFields`, `Get`, `FindFirst` ou des boucles.
À cela s'ajoutent **~100 FlowFields custom affichés directement dans des repeaters** : BC
émet une requête d'agrégation par ligne **et par champ**, même sans `CalcFields` explicite.
Une liste de 50 lignes avec 12 FlowFields = 600 requêtes pour un écran.

### R4 — Agrégats calculés en boucle AL au lieu de `CalcSums`
Le code additionne en `repeat … until` ce que SQL sait faire en une requête. Systématique
dans `KPI Management`, et souvent doublé d'un second passage juste pour compter.

### R5 — Écritures dans des triggers à très haut volume
`Item Ledger Entry` (la table la plus volumineuse de BC) porte un `OnInsert` qui **duplique
chaque écriture** dans `Specific Item Ledger Entry` et **modifie la table `Item`**. Toute
validation de document paie ce coût et prend des verrous sur `Item`.

---

## 2. Backlog priorisé

Ordre conseillé : **V0 → V1 → V2 → V3**. La vague 0 ne modifie rien et sert à mesurer.

Légende — **Gain** : impact ressenti · **Risque** : probabilité de casser la prod · **Effort** : temps dev.

---

### VAGUE 0 — Diagnostic, aucun changement de code

#### V0.1 · Mesurer avant de corriger
**Gain** — · **Risque** aucun · **Effort** 1 h

Sans point de départ chiffré on ne saura pas si un correctif a servi.

- Activer sur l'instance BC160 : `Event Log` → `Microsoft-DynamicsNAV-Server/Admin`, et la
  télémétrie des requêtes longues (`enableLongRunningSqlStatements` est déjà à `true` dans
  `.vscode/launch.json`).
- Côté SQL Server, relever le top 20 des requêtes par durée cumulée :
  ```sql
  SELECT TOP 20 qs.total_elapsed_time/1000 AS ms_total, qs.execution_count,
         qs.total_elapsed_time/qs.execution_count/1000 AS ms_moyen,
         SUBSTRING(st.text, (qs.statement_start_offset/2)+1, 200) AS requete
  FROM sys.dm_exec_query_stats qs
  CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) st
  WHERE st.text LIKE '%Item Ledger Entry%' OR st.text LIKE '%Sales Shipment%'
     OR st.text LIKE '%Specific Item%'
  ORDER BY qs.total_elapsed_time DESC;
  ```
- Chronométrer manuellement les 5 écrans dont les utilisateurs se plaignent le plus, et les
  noter ici. Candidats probables d'après le code :
  `Pag50119 PurchaseItemCompare`, `Pag50117 CustomerListAdministration`,
  `Pag50124 KPIventeDtails`, Role Center `Pag50126/50127`, liste des articles standard (Pag31).

**Validation** : un tableau « écran → temps avant » rempli, qui servira de référence.

#### V0.2 · Vérifier que `Item Ledger Entry.year` est bien alimenté
**Gain** — · **Risque** aucun · **Effort** 15 min

[Tab32-Ext80106.ItemLedgerEntry.al:200](../src/TableExt/Tab32-Ext80106.ItemLedgerEntry.al#L200) :

```al
trigger OnAfterInsert()
begin
    year := DATE2DMY("Posting Date", 3);
end;
```

`OnAfterInsert` s'exécute **après** l'écriture en base et il n'y a pas de `Modify()` :
l'affectation est très probablement perdue. Si c'est le cas, `ILE.year = 0` partout, et les
FlowFields qui en dépendent renvoient **0 en permanence** :
`Item."Total Vendu curr. Year"`, `Item."Total Achete curr. Year"`,
`Purchase Price."Purch. Qty Curr. Year frs"` et les 3 champs voisins.

```sql
SELECT COUNT(*) AS total,
       SUM(CASE WHEN [year] = 0 THEN 1 ELSE 0 END) AS annee_vide
FROM [<Société>$Item Ledger Entry];
```

**Si `annee_vide` ≈ `total`** → c'est un **bug fonctionnel silencieux**, pas seulement un
sujet de perf, et il devient prioritaire (voir V1.1).

---

### VAGUE 1 — Gain fort, risque faible, code seul (pas de resync de schéma)

#### V1.1 · Corriger l'alimentation de `ILE.year`
**Gain** ⭐⭐⭐ (correction) · **Risque** faible · **Effort** 1 h + rattrapage

Déplacer l'affectation dans le trigger qui s'exécute **avant** l'écriture, à côté du code
existant qui alimente déjà correctement `Specific Item Ledger Entry.Year` :

```al
trigger OnInsert()
begin
    year := DATE2DMY("Posting Date", 3);   // <- ajouter ici
    ...
end;
```

Puis supprimer le `OnAfterInsert` devenu inutile, et prévoir un **rattrapage de l'historique**
(script SQL de mise à jour, ou report de reprise) — à faire hors heures ouvrées, une société
à la fois.

**Validation** : une nouvelle réception/vente crée une ligne avec `year` renseigné ; les
champs « curr. Year » de la fiche article affichent enfin une valeur.

#### V1.2 · Sortir `UpdateAlertesMgStk()` de l'ouverture du Role Center
**Gain** ⭐⭐⭐ · **Risque** faible · **Effort** 2 h

[Pag50127.CommercedeGrosKPI.al:772](../src/Page/Pag50127.CommercedeGrosKPI.al#L772) appelle
`KPIManagement.UpdateAlertesMgStk()` dans `OnOpenPage`. Cette procédure parcourt tous les
articles en stock **et écrit dedans** (`Item.Modify(false)`).

Conséquence : chaque utilisateur qui ouvre son Role Center déclenche un balayage + des
écritures sur `Item` — donc des verrous sur la table article en pleine journée, pour tout
le monde, plusieurs fois par jour.

**Correctif** : déplacer l'appel dans un **Job Queue Entry** (codeunit dédiée, toutes les
15–30 min ou la nuit). L'`OnOpenPage` ne fait plus que **lire** les compteurs :

```al
// OnOpenPage : lecture seule
NbArtMgStkSousMin := KPIManagement.GetNbArtMgStkSousMin();
NbArtMgStkSansQteMin := KPIManagement.GetNbArtMgStkSansQteMin();
```

**Validation** : ouverture du Role Center chronométrée avant/après ; les compteurs restent
justes après le passage du Job Queue.

#### V1.3 · Remplacer les boucles d'agrégation par `CalcSums` dans `KPI Management`
**Gain** ⭐⭐⭐ · **Risque** faible · **Effort** 3 h · **✅ FAIT le 2026-09-05 (chantier 1)**

> ⚠️ **Contrainte du runtime 5.0 découverte à la compilation** : `CalcSums` **n'accepte que des
> champs `Normal`**. Sur un FlowField le compilateur rejette :
> *« The argument N of field class FlowField is not supported. Allowed field class types are 'Normal' »*.
> Pour une somme de FlowFields, la bonne construction est **`SetAutoCalcFields(...)` avant le
> `FindSet`**, puis la boucle sans `CalcFields` : BC calcule alors les FlowFields dans la requête
> principale (une jointure) au lieu d'un aller-retour par ligne. Valeurs identiques,
> `1 + N` requêtes → `1`.

[Cod50025.KPIManagement.al](../src/CodeUnit/Cod50025.KPIManagement.al) — 8 procédures suivent
le même schéma :

```al
if SalesLine.FindSet() then
    repeat
        Total += SalesLine."Line Amount";
    until SalesLine.Next() = 0;
```

→ une ligne :

```al
SalesLine.CalcSums("Line Amount");
Total := SalesLine."Line Amount";
```

Concernées : `ComputeTodaySales`, `ComputeTotalFactureNonRegleeRC`, `ComputeTotalAvoirNonRegleeRC`,
`ComputeTotalBLNonRegleeRC`, `ComputeTotalBSNonRegleeRC`, `ComputeTotalRetourBLNonRegleeRC`,
`ComputeTotalRetourBSNonRegleeRC`.

Cas particulier : `ComputeTotalFacturesNonReglees` / `ComputeTotalAvoirsNonReglees` bouclent
sur `Cust. Ledger Entry` avec `CalcFields("Remaining Amount")` par ligne. `Remaining Amount`
étant lui-même un FlowField, `CalcSums` ne s'applique pas directement — agréger sur
`Detailed Cust. Ledg. Entry."Amount (LCY)"` avec les mêmes filtres, ou utiliser
`SetAutoCalcFields` en attendant. **À traiter en dernier dans ce chantier**, résultat à
recouper avec l'existant.

Fusionner aussi les paires `ComputeTotalXxx` / `ComputeNbXxx` : elles refont deux fois le même
scan avec les mêmes filtres.

**Validation** : les valeurs affichées sur les cues KPI sont **identiques** avant/après
(comparer écran à écran sur une société), et le temps d'affichage chute.

#### V1.4 · Borner les scans intégraux du KPI par une date
**Gain** ⭐⭐⭐ · **Risque** moyen (métier) · **Effort** 1 h + validation métier

Les `ComputeTotal*NonRegleeRC` font `SetRange(solde, false)` **sans aucun filtre de date** :
ils balaient tout l'historique de factures / BL / BS depuis la mise en service, sur 5 sociétés.

**Correctif** : ajouter un filtre `Posting Date` (p. ex. `>= 01/01/N-2`) — ou mieux, un champ
de paramétrage pour la profondeur d'historique retenue.

⚠️ **Décision métier requise** : un document non soldé plus ancien que la borne disparaîtrait
du total. À valider avec le contrôle de gestion avant de coder.

#### V1.5 · Nettoyer `OnAfterGetRecord` de la liste des articles
**Gain** ⭐⭐ · **Risque** faible · **Effort** 2 h

[Pag31-Ext80118.item.al:377](../src/PageExt/Pag31-Ext80118.item.al#L377) exécute **par ligne** :

```al
rec.setMgPrincipalFilter(rec);
CalcFields("Available Inventory", "Default Bin", "Total Vendu",
           "Last Purch Price Devise", isOem, StorageQty, MainQty);
```

Deux problèmes distincts :

1. `setMgPrincipalFilter` fait un `FindFirst()` sur `Inventory Setup` — une table **singleton** —
   à chaque ligne. À remplacer par un `Get()` unique en `OnOpenPage` stocké dans une variable
   de page. Au passage, le paramètre `recitem` de la procédure n'est jamais utilisé.
2. Les 7 `CalcFields` incluent `Available Inventory`, `StorageQty`, `MainQty` — les trois
   FlowFields dont le `WHERE` filtre sur `isLocationExclu` / `isStorageLocation` /
   `isMainLocation`, c'est-à-dire le cas R1 dans sa forme la plus coûteuse (voir V3.1).
   **Ne garder que ceux réellement affichés dans le repeater** ; supprimer les autres.

**Validation** : la liste des articles s'ouvre et défile nettement plus vite ; les colonnes
affichées gardent les mêmes valeurs.

#### V1.6 · Corriger `Pag22 CustomerList` — champ non calculé
**Gain** ⭐ (correction) · **Risque** faible · **Effort** 30 min

[Pag22-Ext80182.CustomerList.al:120](../src/PageExt/Pag22-Ext80182.CustomerList.al#L120) :

```al
CalcFields("Opened Invoice", "Shipped Not Invoiced BL");
TotalEncours := "Opened Invoice" + "Shipped Not Invoiced BL" + "Return Receipts Not Invoiced";
```

`"Return Receipts Not Invoiced"` est un FlowField **qui n'est pas calculé** : il vaut 0 sauf
s'il est affiché ailleurs sur la page. **L'encours client et le style d'alerte de dépassement
sont donc faux** dès qu'un client a des retours non facturés.

Soit l'ajouter au `CalcFields`, soit le retirer du calcul si c'est voulu — mais il faut trancher.

**Validation** : comparer l'encours d'un client ayant des retours en cours avec le calcul métier
de référence.

#### V1.7 · Retirer les `Sleep()` des batchs
**Gain** ⭐ · **Risque** faible · **Effort** 30 min

`Sleep(50)` / `Sleep(100)` dans [Cod50027](../src/CodeUnit/Cod50027.UpdateAvgDailySales.al#L60),
[Cod50028](../src/CodeUnit/Cod50028.PopulateItemDailyStats.al#L86) et
[Rep25006150](../src/Report/Rep25006150.BatchUpdateOEMCount.al#L58).

L'intention (ne pas saturer le serveur) est bonne mais le moyen est mauvais : sur 50 000
articles, `Sleep(50)` tous les 100 = **plus de 20 minutes** d'attente pure. Les `Commit()`
périodiques suffisent à relâcher les verrous. À supprimer une fois ces batchs passés en
Job Queue nocturne.

---

### VAGUE 2 — Index & schéma (fenêtre de synchronisation requise)

> Ces chantiers créent des index SQL. Chacun demande un `Synchronize` de l'extension et donc
> une fenêtre hors production (la création d'index sur `Item Ledger Entry` peut être longue).
> **Un seul index à la fois, une société à la fois.**

#### V2.1 · Clé primaire et clés secondaires sur `Specific Item Ledger Entry`
**Gain** ⭐⭐⭐ · **Risque** moyen · **Effort** 2 h + fenêtre

[Tab50023.SpecificItemLedgerEntry.al](../src/Table/Tab50023.SpecificItemLedgerEntry.al) — 57 champs,
une ligne insérée **pour chaque ligne d'`Item Ledger Entry`**, et le bloc `keys` est **vide** :

```al
    keys
    {

    }
```

Aucune clé secondaire, aucun SIFT. Tout filtre sur cette table est un scan complet — y compris
le FlowField `Item."NbJourRupture"` (`sum(... where("Item No.", "Entry Type"))`) et le
`SetRange("Entry No.")` du trigger `OnAfterModify` d'ILE.

**Correctif** :

```al
keys
{
    key(PK; "Entry No.") { Clustered = true; }
    key(ItemEntryType; "Item No.", "Entry Type", "Posting Date")
    {
        SumIndexFields = Quantity;
    }
    key(ItemPostingDate; "Item No.", "Posting Date") { }
}
```

Et remplacer dans `Tab32-Ext80106` :
```al
recSpecItemLeadEntry.SetRange("Entry No.", "Entry No.");
if recSpecItemLeadEntry.FindFirst() then
```
par `if recSpecItemLeadEntry.Get("Entry No.") then`.

**Validation** : la page `Pag50110 SpecificItemLedgerEntry` et le champ `NbJourRupture`
répondent en une fraction du temps.

#### V2.2 · Clés sur les champs custom réellement filtrés
**Gain** ⭐⭐⭐ · **Risque** moyen · **Effort** 3 h + fenêtre

Aucun des 62 `tableextension` ne déclare de clé. Les champs custom les plus filtrés dans le code :

| Table | Champ custom | Où il est filtré |
|---|---|---|
| `Sales Invoice Header` | `solde` | `Cod50025`, `Pag50134` |
| `Sales Shipment Header` | `solde`, `BS` | `Cod50025`, `Pag50136` |
| `Return Receipt Header` | `solde`, `BS` | `Cod50025` |
| `Entete archive BS` | `solde` | `Cod50025`, `Pag50140`, `Pag50160` |
| `Sales Line` | `Special Order`, `Price modified`, `Discount modified` | cues `Tab9053` |
| `Item Ledger Entry` | `year` | FlowFields `Item` + `Purchase Price` |
| `Item` | `Reference Origine Liée` | `Purchase Price."No."` (V3.2) |

**Procéder champ par champ**, en commençant par `solde` sur `Sales Invoice Header` (le plus
sollicité). Toujours vérifier avec le plan d'exécution SQL que l'index est bien utilisé avant
de passer au suivant.

#### V2.3 · Alléger les cues du Role Center
**Gain** ⭐⭐ · **Risque** faible · **Effort** 2 h

[Tab9053-Ext80101.SalesCue.al](../src/TableExt/Tab9053-Ext80101.SalesCue.al) déclare **22 FlowFields**,
tous calculés à l'ouverture de la page d'accueil, par chaque utilisateur, à chaque connexion.
Cinq d'entre eux filtrent sur un autre FlowField (cas R1) : `Sales Line PU Modif`,
`Sales Line Disc. Modif`, `Item Bin`, `Purchase Special Order`, `Reci. Purch. Special Order`.

De plus, `Pag50127.OnOpenPage` pose `SetRange("Date Filter", 0D, WorkDate - 1)` : les compteurs
portent sur **tout l'historique**.

**Correctif, dans l'ordre** :
1. Supprimer de la page les cues qui ne servent plus (plusieurs sont déjà commentées).
2. Borner les compteurs par une date de début raisonnable au lieu de `0D`.
3. Pour les 5 cues du cas R1 : remplacer le FlowField intermédiaire par un champ normal
   entretenu à la validation (même approche que V3.1).

#### V2.4 · `Pag50127.OnOpenPage` — supprimer les écritures au chargement
**Gain** ⭐⭐ · **Risque** faible · **Effort** 1 h

Le trigger fait deux `Modify()` sur l'enregistrement de cue (`"Default Vendor"`, `"date jour"`)
à chaque ouverture, plus 4 `CalcFields("Sales (LCY)")` successifs avec des filtres de dates
différents. Les écritures posent un verrou sur la table cue partagée entre utilisateurs.

Regrouper les deux `Modify()` en un seul, conditionné, et évaluer si les 4 cumuls de ventes
peuvent venir du cache `KPI Cache` (la table existe déjà, `Tab25006659`) plutôt que d'être
recalculés à chaud.

---

### VAGUE 3 — Refonte ciblée des FlowFields toxiques

> Le plus gros gain du dossier, mais chaque item touche des valeurs affichées : à faire
> **un champ à la fois**, avec recette métier.

#### V3.1 · `isLocationExclu` & consorts : FlowField → champ normal
**Gain** ⭐⭐⭐⭐ · **Risque** moyen · **Effort** 1 j + reprise de données

[Tab32-Ext80106.ItemLedgerEntry.al](../src/TableExt/Tab32-Ext80106.ItemLedgerEntry.al) définit
4 FlowFields `lookup` vers `Location` : `isLocationExclu`, `isImportLocation`,
`isStorageLocation`, `isMainLocation`.

Ils sont ensuite **utilisés comme filtres** :
- dans les `CalcFormula` de `Item."Available Inventory"`, `ImportQty`, `StorageQty`, `MainQty`
  et `Purch. Inv. Line.Inventory` ;
- dans le code : `Cod50027` (×2), `Cod50028` (×2).

C'est le pire cas de R1 : un `Sum` sur `Item Ledger Entry` dont le `WHERE` contient un FlowField.
SQL ne peut utiliser ni index ni SIFT et doit résoudre le lookup ligne à ligne sur des millions
d'écritures. **C'est très probablement la cause n°1 des lenteurs sur tout ce qui touche au stock.**

**Correctif** : transformer les 4 champs en champs **normaux** (Boolean, non FlowField)
alimentés à l'insertion de l'écriture depuis `Location`, puis ajouter les clés SIFT
correspondantes sur `Item Ledger Entry`. Reprise nécessaire sur l'historique.

**Alternative moins invasive**, déjà appliquée dans `UpdateAlertesMgStk` : passer par
`Item."Location Filter"` + `Item.Inventory` standard, qui exploitent les SIFT natifs de BC.
À privilégier partout où l'on a juste besoin d'un stock par magasin.

**Validation** : comparer `Available Inventory` / `StorageQty` / `MainQty` sur un échantillon
d'articles avant et après, société par société.

#### V3.2 · `Purchase Price` : FlowFields en cascade
**Gain** ⭐⭐⭐ · **Risque** moyen · **Effort** 1 j

[Tab7012-Ext80109.PurchasePrice.al](../src/TableExt/Tab7012-Ext80109.PurchasePrice.al) —
18 FlowFields, dont un enchaînement particulièrement coûteux :

```al
field(80109; master;  …) CalcFormula = lookup(Item."Reference Origine Liée" where("No." = field("Item No.")));
field(80110; "No.";   …) CalcFormula = lookup(Item."No." where("Reference Origine Liée" = field(master)));
field(80111; frs;     …) CalcFormula = lookup(Item."Vendor No." where("No." = field("No.")));
```

`"No."` fait un lookup sur `Item."Reference Origine Liée"` — un champ **non indexé** (scan de la
table article) — en filtrant sur `master` qui est **lui-même un FlowField**. Et 6 autres champs
(`frs`, `Description`, `Famille`, `Sous Famille`, `Sales Qty`, `Last Curr. Price.`) prennent ce
`"No."` en entrée : chaque ligne déclenche une cascade complète.

[Pag50119.PurchaseItemCompare.al](../src/Page/Pag50119.PurchaseItemCompare.al) affiche **12 de
ces champs** dans son repeater. Pour 50 lignes à l'écran, on est à plusieurs centaines de scans
de la table `Item`.

**Correctif** : reconstruire cette page sur une table temporaire remplie en une passe
(un `FindSet` sur `Item` + un sur `Purchase Price`, jointure en mémoire), au lieu de laisser
BC résoudre 12 FlowFields par ligne. Le champ `master` peut devenir un champ normal alimenté à
la validation, et `Item."Reference Origine Liée"` doit recevoir une clé.

#### V3.3 · `Sales Shipment Line.solde` : lookup filtré 40 fois
**Gain** ⭐⭐⭐ · **Risque** moyen · **Effort** 4 h

`solde` = `lookup("Entete archive BS".solde where("No." = field("Document No.")))`, filtré via
`SetRange(solde, …)` dans `Cod50025`, `Pag50129`, `Pag50132`, `Pag50133` — sur une table de lignes
d'expédition qui grossit indéfiniment.

**Correctif** : filtrer d'abord sur `Entete archive BS` (table d'en-têtes, bien plus petite),
récupérer la liste des `Document No.`, puis filtrer les lignes dessus. Ou dénormaliser `solde`
en champ normal sur la ligne, mis à jour en même temps que l'en-tête.

---

### VAGUE 4 — Dette technique & hygiène (sans impact prod immédiat)

| # | Sujet | Détail |
|---|---|---|
| V4.1 | **Analyseurs de code absents** | Ajouter `"al.codeAnalyzers": ["${CodeCop}", "${PerTenantExtensionCop}", "${UICop}"]` dans `.vscode/settings.json` + un `.ruleset.json`. Les règles AA0139/AA0206/AA0217 auraient signalé une partie des points ci-dessus. |
| V4.2 | **Dépôt git à 249 Mo** | `.alpackages/*.app` (dont `Base Application` ≈ 100 Mo) et les `.app` compilés sont versionnés. `.gitignore` les exclut désormais mais ils restent suivis : `git rm --cached` sur ces fichiers. |
| V4.3 | **`.gitignore` contient `*.json`** | Trop large : masque `app.json`, `launch.json`, `settings.json` et tout nouveau fichier de config. À restreindre. |
| V4.4 | **Fichiers morts** | `src/Table/Ignored.FollowUp*.al` (×3), `src/WebService/Pag25006864.GETPDFSalesShipment copy.al`. À supprimer ou à sortir de `src/`. |
| V4.5 | **3 803 lignes commentées** | ~5 % du code. Git conserve l'historique ; le code mort commenté rend la relecture pénible et masque les vrais problèmes. Nettoyage progressif, fichier par fichier, en même temps que les autres chantiers. |
| V4.6 | **Reports quasi identiques** | `Rep50201.InvoicePR` / `Rep50218.InvoiceServices` / `SIInvoiceServicesPack` partagent le même `OnAfterGetRecord` (7 `Get` + `FindSet` imbriqué). Même chose pour `Rep50215`/`Rep50234`/`Rep25006121` et `Rep25006030`/`Rep50221`/`Rep50225`. Factoriser la logique commune dans une codeunit. |
| V4.7 | **3 pages API sans `ODataKeyFields`** | `Pag25006804.ItemAPI`, `Pag25006811.ItemCopyAPI`, `Pag25006838.CustomerLedgerEntryAPI`. Sans clé OData, les `PATCH`/`DELETE` sont peu fiables et la pagination dégrade. |
| V4.8 | **Migration runtime** | `SetLoadFields` (qui limite les colonnes lues) n'existe qu'à partir du runtime 6.0 / BC17. C'est le levier de perf le plus rentable pour ce type de code — argument à verser au dossier d'une éventuelle montée de version. |

---

## 3. Ordre d'exécution proposé

Chaque ligne = un cycle complet **DEV → test → PROD → observation 48 h → suivant**.

| # | Chantier | Pourquoi en premier |
|---|---|---|
| 1 | **V0.1** Mesures de référence | Sans chiffres, pas de preuve d'amélioration |
| 2 | **V0.2** Vérifier `ILE.year` | 15 min, peut révéler un bug de données majeur |
| 3 | **V1.2** `UpdateAlertesMgStk` hors Role Center | Gain immédiat perçu par **tous** les utilisateurs, risque quasi nul |
| 4 | **V1.3** `CalcSums` dans KPI Management | Gros gain, résultat vérifiable au chiffre près |
| 5 | **V1.5** Liste articles | Écran très utilisé, correctif localisé |
| 6 | **V1.6** Encours client `Pag22` | Correction fonctionnelle rapide |
| 7 | **V1.1** Correction `ILE.year` | Après V0.2, avec rattrapage planifié |
| 8 | **V2.1** Clés `Specific Item Ledger Entry` | Premier index — rodage de la procédure de fenêtre |
| 9 | **V2.2** Clés champs custom (`solde` d'abord) | Un index à la fois |
| 10 | **V1.4** Bornage des scans KPI | Nécessite l'accord métier en amont |
| 11 | **V2.3 / V2.4** Cues Role Center | |
| 12 | **V3.1** `isLocationExclu` | Le plus gros gain, mais après rodage du process |
| 13 | **V3.3** puis **V3.2** | |
| — | **V4.x** | En parallèle, au fil de l'eau |

---

## 4. Règles à tenir pendant les corrections

1. **Une branche par chantier**, un commit, un message qui cite l'identifiant (`V1.2 …`).
2. **Compiler et tester sur DEV** (`SOPIQ DEV`, 192.168.1.5) avant tout déploiement.
   La configuration existe dans `.vscode/launch.json` — l'utiliser systématiquement.
3. **Une société pilote** avant de généraliser aux 5.
4. **Noter le temps avant / après** dans le tableau de V0.1 : c'est ce qui justifiera la suite.
5. **Ne jamais enchaîner deux chantiers sur la même mise en prod** — en cas de régression on ne
   saurait pas lequel incriminer.
6. **Retour arrière** : chaque chantier étant un commit isolé, un `git revert` + redéploiement
   suffit. Les chantiers de la vague 2 (index) demandent en plus une resynchronisation.

---

## 5. Journal des chantiers

| Chantier | Date DEV | Date PROD | Avant | Après | Statut |
|---|---|---|---|---|---|
| **Chantier 1** (V1.3 + V1.7 partiel) | | | | | **compilé OK, à déployer DEV** |
| V0.1 | | | | | à faire |

### Chantier 1 — 2026-09-05 · « Agrégats SQL & lectures inutiles »

Périmètre : uniquement des transformations dont le résultat est **mathématiquement identique**.
Compilation `alc` : exit 0, 0 erreur, 421 warnings (tous préexistants).

**Bloc A — boucle de somme → `CalcSums`** (champs `Normal`, 7 procédures de `Cod50025`)
`ComputeTodaySales`, `ComputeTodayReturns`, `ComputeChequeEnCoffre`, `ComputeChequeImpaye`,
`ComputeTraiteEnCoffre`, `ComputeTraiteEnEscompte`, `ComputeTraiteImpayee`
\+ `Cod50027.CalcAvgDailySales` (somme de `Item Daily Stats."Total Sold"`).

**Bloc B — `CalcFields` par ligne → `SetAutoCalcFields`** (FlowFields, 9 procédures de `Cod50025`)
`ComputeTotalFacturesNonReglees`, `ComputeTotalAvoirsNonReglees`, les 6 `ComputeTotal*NonRegleeRC`,
`ComputeAjustementPositif`, `ComputeAjustementNegatif`.

**Bloc C — `FindSet` inutile avant `CalcSums`** (6 sites)
`Pag50120:361`, `Pag50121:286`, `Pag50122:374` (pages, gain ressenti direct) ·
`Cod50027` ×2, `Cod50028` ×1 (appelés par article dans les batchs).
`CalcSums` ne nécessite pas d'enregistrement positionné et met le champ à 0 sur un ensemble vide :
le `FindSet` lisait tout le recordset pour rien.

**Bloc D — cache du singleton `Inventory Setup`**
`Tab27-Ext80103.setMgPrincipalFilter` faisait un `FindFirst()` **par ligne affichée**, depuis
6 appelants (`Pag31`, `Pag25006977`, `Pag25006979`, `Pag50152`, `Rep25006154`, `Rep50203`).
Désormais lu une seule fois par instance d'enregistrement.
*Seule différence de comportement possible* : si « Magasin Central » est modifié pendant qu'une
page est ouverte, l'ancienne valeur reste affichée jusqu'à réouverture.

**À vérifier en recette** — comparer avant/après, sur une société, le contenu de la table
`KPI Cache` du jour (les 22 champs) et le stock affiché sur les pages Devis.

#### Résultat en production — 2026-09-07

**Durée du job `Cod50026 KPI Cache Job` : de 5–11 minutes à 29 secondes.**

Relevé du journal de la file d'attente, société `SOPIQ PROD` :

| Passage | Durée | Code |
|---|---|---|
| 04/09, 7 passages | 5 min 31 s → 11 min 07 s | ancien |
| 05/09, 10 passages | 5 min 14 s → 8 min 05 s | ancien |
| 07/09 08:00 / 09:06 / 10:14 / 11:23 | 6 min 39 s → 10 min 07 s | ancien |
| **07/09 12:34** | **29 s 300 ms** | **nouveau** |

Comparaison de la **même ligne** (07/09) recalculée avant et après déploiement :
**18 colonnes sur 22 strictement identiques**. Les 4 autres — `Total BL Non Réglés RC`,
`Total Retour BL RC`, `Ventes du Jour`, `Retours du Jour` — progressent toutes dans le sens
de l'activité de la journée.

`Ventes du Jour` (43 951 → 49 978) et `Retours du Jour` (6 012 → 6 070) étaient les deux
seules conversions qu'aucun test n'avait pu valider, faute de données non nulles sur DEV.
Elles sont désormais validées.

Vérifications complémentaires sur DEV : colonne « Emplacement par défaut » de la liste
articles renseignée, stock magasin de vente correct sur les pages Devis.

#### 🔴 Bug confirmé en production : le cache renvoie zéro

La ligne du **06/09 (dimanche) est intégralement à zéro** — y compris
`Total Factures Non Réglées`, alors qu'il y avait 239 factures impayées le vendredi **et**
le lundi. Le journal de la file d'attente ne montre **aucun passage le 06/09**.

L'enregistrement a été créé à 14:54 par `GetOrCreateTodayCache` quand quelqu'un a ouvert le
tableau de bord. Cette personne a vu **zéro partout**.

Le piège : les triggers de la table `KPI Cache` renseignent l'horodatage à l'insertion —

```al
trigger OnInsert()
begin
    "Last Calculated" := CurrentDateTime;
    "Calculated By"   := UserId;
end;
```

— donc un enregistrement vide porte une date de calcul **d'apparence fraîche**. Rien
n'indique à l'utilisateur que le calcul n'a pas eu lieu. **À traiter en priorité** : se
rabattre sur le dernier cache disponible plutôt que d'en créer un vide, et afficher la date
de fraîcheur. ⚠️ Ce correctif **change le comportement** (0 devient « valeur de la veille ») :
ce n'est pas une optimisation neutre mais une correction de bug.


### Chantier 4 — 2026-09-26 · « Tuiles articles du tableau de bord, et interface Reapro »

#### Partie 1 — Tableau de bord du responsable dépôt (SOPIQ INTERNE v1.0.7.0)

Mesure d'entrée sur `SOPIQ_DEV`, deux ouvertures de la page, par écart de
`sys.dm_exec_query_stats` avant et après :

| Tuile | Coût mesuré | Décision |
|---|---|---|
| Article avec +Emplacement | 28,9 s | cache KPI, calcul réécrit |
| En Stock & Sans prix vente | 26,0 s | cache KPI, calcul inchangé |
| Réception et Litige + | 5,7 s en 27 304 requêtes | Litige + au cache, Réception en temps réel par requête agrégée |

Le champ calculé `"Item Bin"` de `Tab9053-Ext80101` empilait **trois niveaux** de champs
calculés : il filtre sur `"Count Content"`, qui filtre lui-même sur `"Quantity"`, somme des
mouvements de stock. SQL ne peut rien indexer là-dedans. Remplacé par la requête
`Que50013 "Stock Emplacement Agrege"`, un regroupement des mouvements par emplacement que SQL
résout sur la vue indexée `VSIFT$Key5` avec `NOEXPAND` : **0,20 s par appel**.

Contrôle : la page *KPI vente Détails* (`Pag50124`) n'a pas été modifiée et sert de témoin.
Elle affiche les mêmes nombres que le tableau de bord — 64, 0 et 60 sur DEV.

**Ouverture du tableau de bord : 50 s → 25 s sur DEV.**

#### Résultat en production — 2026-09-26, 17:13

Version 1.0.7.0 publiée, cache recalculé, société SOPIQ PROD.

**Ouverture du tableau de bord : 13 secondes.**

Les quatre tuiles retouchées affichent exactement les valeurs relevées juste avant
publication, quand elles étaient encore calculées en direct :

| Tuile | Avant publication, calcul direct | Après, cache ou requête agrégée |
|---|---|---|
| Réception | 61 | 61 (temps réel) |
| Litige + | 0 | 0 |
| Article avec +Emplacement | 36 | 36 |
| En Stock & Sans prix vente | 1 | 1 |

Durée du job `Cod50026` en production : de 28-40 secondes à **3 minutes**. Hausse attendue et
voulue : le traitement a repris à son compte ce que la page faisait à chaque ouverture, pour
chaque utilisateur.

Reste identifié, non traité : quatre requêtes de comptage sur `Sales Header` avec des
`OUTER APPLY` sur `Sales Line`, environ 6 s par ouverture, même maladie sur une autre table.

#### Partie 2 — L'interface Reapro, hors périmètre AL

Découverte en mesurant le tableau de bord : les vues `ELVA_*` de la base `Amiral_LS` lisent
**directement les tables de production** `SOPIQ_PROD_BC16`, et DEV comme PROD sont hébergées
sur la même instance SQL `SRV-SQL`. Plus de cinq heures de travail SQL cumulé leur étaient
imputables.

| Correction | Avant | Après | Où |
|---|---|---|---|
| Index `IDX_PERF_ItemExt_RefOrigine` sur `[Reference Origine Lié]` | 14 527 pages, 3 analyses complètes | 3 pages, 1 recherche | PROD, fait |
| Réécriture de la vue `ELVA_Item` | 12 M pages, 22,3 s UC, 34 à 81 s | 1,94 M pages, 6,1 s UC, **4,55 s** | PROD, fait |

La réécriture remplace trois `OUTER APPLY` — une somme par article, 179 847 fois — par trois
jointures externes sur des sommes groupées. Identité prouvée par `EXCEPT` dans les deux sens,
sur les vingt-neuf colonnes, `NULL` compris, d'abord sur DEV puis **sur les données de
production après bascule**. Retour arrière conservé dans
`docs/sql/vue-elva-item-reecriture-prod.sql`.

Un index couvrant sur `Reservation Entry` a été essayé sur DEV en cours de diagnostic. Il
divisait ses lectures par dix, mais la réécriture de la vue le rend inutile : il n'a jamais
été posé en production.

**Reste à traiter, et qui ne dépend pas de nous** : l'application appelle
`count(*) FROM ELVA_ITEM WHERE No_=@P0` **878 537 fois**, article par article. Chaque appel
est rapide, c'est le nombre qui pèse : 2 239 s cumulées. Seul le développeur Reapro peut
regrouper ces appels. À signaler.

**Reste à traiter, et qui dépend de nous** : le filtre le plus utilisé de la vue,
`WHERE [Vendor Item No_] IN (...)`, porte sur une expression `CASE … REPLACE(…)` et non sur
une colonne. Aucun index ne peut le servir. Deux voies possibles, à étudier : exposer la
colonne brute à côté de l'expression, ou une colonne calculée persistante.


### Chantier 5 — 2026-09-28 · « Numérotation des versions de modèle »

Le même numéro d'article pouvait désigner une pièce dans une société et un véhicule dans une
autre : `204002` valait « Vanne EGR » dans SOPIQ PROD et « C 220 CDI » dans 3S AGENCE. Le
traitement des Item Master recopiait la pièce sur le véhicule. Business Central l'a refusé, mais
par effet de bord : il réclamait un code traçabilité que la pièce n'avait pas. Si le véhicule
avait eu une valorisation ordinaire, la fiche aurait été écrasée en silence.

**Deux réponses, livrées le même jour.**

Un garde-fou dans le code, version 1.0.8.0 : le traitement des Item Master contrôle le champ
`Item Type` avant toute écriture. Une fiche « Modèle Version » n'est ni écrasée, ni propagée, et
les références écartées sont listées en fin de traitement au lieu d'être tues.

Une séparation des numéros, version 1.0.9.0 : les versions de modèle Mercedes de 3S AGENCE, à
six chiffres, prennent un point entre le troisième et le quatrième chiffre. `204002` devient
`204.002`.

**Mesures avant lancement** : 850 fiches concernées en production, aucune collision, treize
lignes dans `items Master` toutes rattachées à 3S AGENCE, et surtout un balayage des 222 colonnes
de numéro d'article de la société, qui n'a trouvé que deux colonnes portant ces numéros —
`Item Unit of Measure`, que Business Central met à jour seul, et le champ `N° 2` de la fiche
article, que le renommage n'atteint pas et que le batch reporte désormais lui-même.

**Résultat en production — 2026-09-28, 18:12 à 19:22**

| Contrôle | Attendu | Obtenu |
|---|---|---|
| Fiches renommées | 850 | 850 |
| Collisions | 0 | 0 |
| Fiches restantes à six chiffres | 0 | 0 |
| `N° 2` en écart | 0 | 0 |

Une heure et dix minutes, soit cinq secondes par fiche : c'est le temps que met Business Central
à reporter un numéro sur tout l'historique qui s'y rattache. La répétition sur DEV avait donné
858 fiches en 1 h 06.

**Deux enseignements pour la prochaine fois.**

Le traitement valide après chaque fiche, il est donc reprenable. Il s'est interrompu une fois,
parce qu'une commande a été tapée dans la fenêtre qui l'exécutait ; relancé, il a repris à la
195e sans rien perdre.

Le serveur Business Central et le serveur SQL n'ont pas la même heure : une heure d'écart. Le
journal étant horodaté par BC et `GETDATE()` par SQL, un suivi naïf fait croire à un arrêt. Se
fier à la progression du compteur, jamais à l'écart de temps.

<!-- Compléter au fil de l'eau. -->

### Chantier 6 — 2026-09-29 · « Les tuiles qu'on calculait sans les afficher »

Le chantier 4 laissait un reste identifié : quatre requêtes de comptage sur `Sales Header` avec
des `OUTER APPLY` sur `Sales Line`, à chaque ouverture du tableau de bord.

**Trois fausses pistes, et ce qu'elles enseignent.** La première mesure n'a rien capté, faute
d'avoir refermé la page avant la photo. La deuxième a été prise sur une autre société que celle
où le coût apparaissait. La troisième m'a fait masquer les tuiles d'une page du verticalisateur,
la partie « Activités » du Role Center vendeur pièces, qui portait bien des tuiles du même nom
mais n'était pas celle que les utilisateurs ouvrent. Cette extension de page a été retirée.
Une capture d'écran du Role Center a tranché en dix secondes ce que trois quarts d'heure de
lecture de symboles n'avaient pas réglé : **regarder l'écran de l'utilisateur avant de fouiller
le code**.

**La cause, dans notre propre code.** La page 50127, « Commerce de Gros KPI », appelait
`CalculateCueFieldValues` à chaque ouverture. Cette procédure calcule « Average Days Delayed »,
« Ready to Ship », « Partially Shipped » et « Delayed », dont les tuiles sont **commentées dans
la mise en page depuis longtemps**. On payait l'affichage de tuiles invisibles.

Le coût venait de la nature des filtres : `Completely Shipped`, `Shipped` et
`Late Order Shipping` sont des FlowFields de l'en-tête vente, calculés depuis les lignes. Aucun
index ne peut servir un filtre sur un FlowField, SQL recalcule la valeur de chaque en-tête avant
de pouvoir compter. C'est la cause racine R1, dans sa forme la plus coûteuse.

**Résultat, mesuré sur DEV, société STE COPIM, à l'ouverture du tableau de bord**

| Requête | Avant | Après |
|---|---|---|
| Comptage « Delayed » | 0,51 s, 346 206 pages | supprimée |
| Comptage « Partially Shipped » | 0,31 s, 114 175 pages | supprimée |
| Comptage « Ready to Ship » | 0,19 s, 112 097 pages | supprimée |
| Lecture « Average Days Delayed » | 0,33 s, 276 956 pages | supprimée |
| **Total** | **1,34 s, 849 434 pages** | **0** |

Les tuiles affichées ne bougent pas : les sept statuts de commande, les BL et retours non
facturés, les factures et avoirs, le panier BS et les articles sont calculés ailleurs.

La page 50124, témoin du chantier 4, garde le calcul d'origine.

**Reste identifié, et qui ne dépend pas de nous** : pendant ces mesures, l'application Reapro a
lancé une quinzaine de requêtes sur `ELVA_ITEM` à 47 214 pages chacune, en quelques secondes.
C'est le même sujet que le reste du chantier 4, à leur signaler.

### Essai non concluant — 2026-09-29 · « Rendre indexable le filtre de ELVA_ITEM »

Le chantier 4 laissait ce reste : le filtre le plus utilisé de la vue,
`WHERE [Vendor Item No_] IN (...)`, porte sur une expression et non sur une colonne.

```sql
CASE IX.Produit WHEN 1 THEN REPLACE(I.No_, 'MASTER', '')
                WHEN 0 THEN I.[Vendor Item No_] END
```

**L'idée essayée** : couper la lecture en deux selon `Produit`. Les 161 834 articles en
`Produit = 0`, soit 84 %, retomberaient sur la vraie colonne `[Vendor Item No_]`, qu'un index
peut servir. Un index a été posé sur cette colonne, l'essai lancé sur PROD, puis tout a été
remis en état. Script conservé : `docs/sql/essai-filtre-elva-vendor-item.sql`.

**Mesure, sur une liste réelle de 34 références rendant 6 lignes**

| | Pages lues | Processeur | Temps rendu |
|---|---|---|---|
| Vue actuelle | 47 214 | 5,0 s | 2,7 s |
| Lecture coupée en deux | 759 | 5,0 s | 5,5 à 7,2 s |

**Pourquoi c'est un échec.** Le coût n'était pas la lecture mais le calcul : `REPLACE` puis
trente-quatre comparaisons de texte sur 193 305 articles, soit plus de six millions
d'opérations. Diviser les lectures par soixante n'y change rien. Pire, la vue actuelle est
parallélisée par SQL Server, les cinq secondes de processeur se répartissent sur plusieurs
cœurs ; la version coupée s'exécute sur un seul et rend la main deux fois plus tard.

**Ce qu'il faudrait pour gagner vraiment**, et qui reste à décider : une colonne calculée
persistante portant `REPLACE(No_, 'MASTER', '')` sur la table article du verticalisateur, avec
son index. Les deux moitiés deviendraient des recherches directes, et le coût tomberait de cinq
secondes à quelques millisecondes.

Le prix : c'est une colonne ajoutée à une table gérée par Business Central. Une republication
de l'extension du verticalisateur peut la faire disparaître, et la vue tomberait alors en panne
pour toutes les applications connectées. À décider, pas à improviser.

**Rappel de la contrainte, posée le 29/09/2026** : ces vues sont un contrat avec plusieurs
applications. Ni leur nom, ni leurs colonnes, ni leur contenu ne doivent changer. Toute
optimisation est de notre côté et doit rester invisible pour elles.

### Incident — 2026-09-30 · « Le comptoir ne pouvait plus imprimer »

Premier matin de la version 1.1.12.0 en production. À 7 h 56, un agent de COPIM valide un reçu
et reçoit une erreur technique au lieu de son ticket : Business Central refuse de lancer un
rapport avec sa fenêtre de demande tant qu'une transaction d'écriture est ouverte.

**La cause.** Dans la fiche reçu, la séquence était `Commit`, puis `CurrPage.Update(true)`, puis
`Report.RunModal`. Or `Update(true)` écrit la fiche, donc rouvre une transaction d'écriture,
juste avant le rapport. Cette séquence existait depuis longtemps et ne posait pas de problème :
à cet instant la fiche n'avait rien à écrire. Elle en a depuis que la validation pose `Imprimé`,
changement livré la veille. Le `Commit` protégeait une écriture qui n'existait plus et ne
protégeait pas celle qui venait d'apparaître.

**Le correctif**, version 1.1.13.0 : inverser les deux lignes. La fiche est écrite, la
transaction est validée, puis le rapport part.

**Ce qui a limité les dégâts.** Le reçu était bien créé, avec ses documents et ses paiements :
seule l'impression échouait, et le ticket se ressortait par le rapport avec le numéro en filtre.
Le comptoir n'a jamais été empêché d'encaisser.

**La leçon.** Déplacer une écriture dans un code partagé peut casser un appelant qui n'a pas
changé d'une ligne. Ici, poser `Imprimé` à la validation était juste, mais rendait dirty un
enregistrement qu'une page écrivait juste avant un `RunModal`. Devant tout déplacement
d'écriture, chercher les `Commit` des appelants et se demander ce qu'ils protégeaient.

### Chantier 7 — 2026-09-30 · « L'encours de la liste clients »

La liste clients recalcule l'encours de chaque client affiché. Le champ `Shipped Not Invoiced BL`
somme les lignes vente avec deux filtres qui interdisent à Business Central d'utiliser ses sommes
précalculées : `"Shipped Not Invoiced (LCY)" = FILTER(> 0)`, un filtre sur le montant qu'il somme,
et `"Expédition type" = filter('Expédition')`, un champ calculé de la ligne qui va chercher
l'en-tête vente. Il lit donc les lignes une à une, pour chaque client à l'écran.

**Mesure de départ**, ouverture de la liste : 58 exécutions, 1 467 709 pages lues, 3,91 s.

**Trois voies possibles**, et le choix du moins risqué. Un index ne change ni le code, ni les
chiffres affichés. Corriger la formule aurait donné plus, mais les montants pouvaient bouger.
Calculer l'encours dans le batch de nuit aurait été le plus rapide à l'écran, mais un encours de
la veille ne vaut rien pour un contrôle de crédit.

**Essai sur DEV, sur cinquante clients**

| | Pages lues | Temps |
|---|---|---|
| Avant | 55 639 | 94 ms |
| Après | 340 | 11 ms |

Valeurs identiques client par client. Après publication, la boucle a disparu de la mesure de la
page, et l'utilisateur a confirmé le gain à l'usage.

**Posé en production le 30/09/2026 à 11h46**, sur les quatre sociétés, en 3,9 secondes au total
et sans blocage ressenti. Script et retour arrière dans `docs/sql/index-prod-liste-clients.sql`.

**Reste à traiter** : une seconde boucle par client, sur `Sales Shipment Line`, 695 276 pages,
qui cherche les bons de livraison non facturés. Ce n'est pas un champ calculé mais du code AL,
à localiser.

**Et une correction fonctionnelle en attente**, notée dans l'audit sous V1.6 et toujours vraie :
`"Return Receipts Not Invoiced"` entre dans le total de l'encours mais n'est jamais calculé. Il
vaut donc toujours zéro, et l'encours affiché ignore les retours non facturés.

---

## 01/10/2026 : mise en production de Reapro, et de 1.1.27.0

Reapro est passé en production. Avec lui, la version **1.1.27.0** a été publiée sur le serveur de
production, qui restait en 1.1.13.0 depuis le 30/09 : les quatorze versions intermédiaires n'avaient
vécu que sur DEV, le temps que l'équipe web éprouve chaque écran.

**Ce que la version apporte** : dix-neuf pages API nouvelles (impression des documents COPIM, devis
et versions de devis, lignes à extraire, panier BS, brouillons de facture et d'avoir, correction de
reçu), deux champs sur le reçu de caisse pour l'historique des corrections, et trois corrections
visibles depuis Business Central : la liste « Administration des clients » qui n'écrit plus en base à
l'affichage, les six états COPIM qui n'écrasent plus le client imprimé quand c'est Reapro qui
imprime, et la page API de commande vente qui expose le client imprimé.

**Ce que ça change pour la suite** : jusqu'ici, une API qui se trompait ne coûtait rien, puisque
personne ne l'appelait en production. Ce n'est plus vrai. Le retour arrière, lui, est devenu un geste
lourd : il n'enlève pas seulement du code, il arrête Reapro. La bonne réponse à un défaut est
désormais la correction en avant, ou la suspension de l'écran côté web.

Procédure de secours et contrôle préalable : `docs/RETOUR-ARRIERE-1.1.27.0.md` et
`docs/sql/controle-avant-retour-arriere-1.1.27.sql`. Paquet de la version précédente reconstruit dans
`D:\ELLOUZE\SOPIQ_INTERNE\retour-arriere\`.

**Un point de vigilance noté le soir même** : en appel API, du code tente d'ouvrir la page du
document enregistré après l'enregistrement d'une facture, ce qui est impossible sans interface.
L'auteur n'a pas pu être identifié : ce n'est ni notre extension, ni l'une des quatre du
verticalisateur, dont les abonnements ont été vérifiés dans les symboles. Restent `ECR`, `ECR001`,
`Purge Table` et `AjoutNumCmdSurListBL`, que BC16 ne permet pas d'exporter pour inspection. La
1.1.27.0 contourne le problème en jugeant l'enregistrement sur le document présent en base. Si un
jour une de ces extensions est republiée depuis ses sources, c'est l'occasion de regarder.
