/* =====================================================================
   Essai : accélérer l'encours de la liste clients par un index.

   Le probleme. La liste clients recalcule l'encours de chaque client
   affiche. Le champ "Shipped Not Invoiced BL" somme les lignes vente avec
   deux filtres qui interdisent a Business Central d'utiliser ses sommes
   precalculees : un filtre sur le montant qu'il somme, et un filtre sur
   "Expédition type", qui est un champ calcule de la ligne. Il lit donc
   les lignes une a une. Mesure du 30/09/2026 : 58 executions, 1 467 709
   pages lues, 3,91 s pour une seule ouverture de la liste.

   L'idee. Un index sur les lignes vente par client et type de document.
   Rien ne change dans le code, ni dans les chiffres affiches : seul le
   chemin d'acces change.

   Sur DEV, societe SOPIQ PROD. Mode d'emploi : bloc par bloc, en lisant
   l'onglet Messages pour les lectures logiques.
   ===================================================================== */

USE SOPIQ_DEV;
GO

SET STATISTICS IO ON;
SET STATISTICS TIME ON;
GO

/* ---------------------------------------------------------------------
   BLOC 1 : la situation actuelle.

   Reproduit ce que fait la page pour les cinquante premiers clients :
   pour chacun, la somme des lignes de commande livrees non facturees.
   Relever les lectures logiques sur "Sales Line".
   --------------------------------------------------------------------- */
SELECT C.[No_] AS Client,
       ISNULL(SUM(L.[Shipped Not Invoiced (LCY)]), 0) AS LivreNonFacture
FROM (SELECT TOP 50 [No_]
      FROM [SOPIQ PROD$Customer$437dbf0e-84ff-417a-965d-ed2bb9650972]
      ORDER BY [No_]) AS C
LEFT JOIN [SOPIQ PROD$Sales Line$437dbf0e-84ff-417a-965d-ed2bb9650972] AS L
    ON  L.[Bill-to Customer No_] = C.[No_]
    AND L.[Document Type] = 1
    AND L.[Shipped Not Invoiced (LCY)] > 0
GROUP BY C.[No_];
GO

/* ---------------------------------------------------------------------
   BLOC 2 : l'index. Seule ecriture de ce script.

   Il porte sur deux colonnes ordinaires des lignes vente, et embarque les
   deux montants dont la liste a besoin. Il ne change ni les donnees, ni le
   schema connu de Business Central. Retour arriere au bloc 4.

   La creation en ligne n'existe pas en edition Standard : la table des
   lignes vente est brievement verrouillee. A lancer en heure creuse.
   --------------------------------------------------------------------- */
CREATE NONCLUSTERED INDEX IDX_PERF_SalesLine_BillTo
    ON [SOPIQ PROD$Sales Line$437dbf0e-84ff-417a-965d-ed2bb9650972]
       ([Bill-to Customer No_], [Document Type])
    INCLUDE ([Shipped Not Invoiced (LCY)], [Return Rcd_ Not Invd_ (LCY)])
    WITH (DATA_COMPRESSION = PAGE);
GO

/* ---------------------------------------------------------------------
   BLOC 3 : la meme mesure, avec l'index.

   Comparer les lectures logiques sur "Sales Line" avec le bloc 1. Les
   valeurs rendues doivent etre identiques, client par client.
   --------------------------------------------------------------------- */
SELECT C.[No_] AS Client,
       ISNULL(SUM(L.[Shipped Not Invoiced (LCY)]), 0) AS LivreNonFacture
FROM (SELECT TOP 50 [No_]
      FROM [SOPIQ PROD$Customer$437dbf0e-84ff-417a-965d-ed2bb9650972]
      ORDER BY [No_]) AS C
LEFT JOIN [SOPIQ PROD$Sales Line$437dbf0e-84ff-417a-965d-ed2bb9650972] AS L
    ON  L.[Bill-to Customer No_] = C.[No_]
    AND L.[Document Type] = 1
    AND L.[Shipped Not Invoiced (LCY)] > 0
GROUP BY C.[No_];
GO

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
GO

/* ---------------------------------------------------------------------
   BLOC 4 : RETOUR ARRIERE, si l'essai ne convainc pas.
   --------------------------------------------------------------------- */
-- DROP INDEX IDX_PERF_SalesLine_BillTo
--     ON [SOPIQ PROD$Sales Line$437dbf0e-84ff-417a-965d-ed2bb9650972];
-- GO
