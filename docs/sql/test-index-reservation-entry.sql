/* =====================================================================
   Test de l'index couvrant sur Reservation Entry, sur SOPIQ_DEV.

   Mesure de depart, chargement complet du catalogue via la copie de la
   vue ELVA_Item, le 26/09/2026 sur SOPIQ_DEV :

       Worktable         359 694 analyses, 7 948 508 lectures
       Reservation Entry 179 847 analyses, 3 956 634 lectures
       Item Ledger Entry       1 analyse,     52 642 lectures
       Warehouse Entry         1 analyse,     47 518 lectures
       total : environ 12 millions de pages, 17 secondes

   Lecture de ces chiffres : pour les ecritures article et les mouvements
   de stock, SQL a calcule toutes les sommes en une seule passe. Pour les
   reservations, il a recommence une fois par article, 179 847 fois, a 22
   pages le passage.

   Pourquoi : la vue lit R.[Source Type] et R.Quantity. Les index Business
   Central de cette table commencent bien par [Item No_], mais aucun ne
   porte ces deux colonnes. SQL trouve donc vite les lignes de l'article,
   puis va rechercher les valeurs dans la table elle-meme, ligne par
   ligne. Un index couvrant supprime ce second voyage.

   Deroulement : etat des lieux, creation, remesure. Le retrait est donne
   a la fin. Rien n'est touche en production.
   ===================================================================== */

USE SOPIQ_DEV;
GO

SET NOCOUNT ON;
GO

/* ---------------------------------------------------------------------
   BLOC 1 : etat des lieux de la table des reservations.
   --------------------------------------------------------------------- */
SELECT
    ISNULL(i.name, '(index groupe sans nom)') AS Nomindex,
    i.type_desc AS Type_,
    p.rows AS NbLignes,
    CAST(SUM(a.used_pages) * 8.0 / 1024 AS DECIMAL(10, 1)) AS TailleMo,
    STUFF((
        SELECT ', ' + c.name
        FROM sys.index_columns AS ic
        JOIN sys.columns AS c ON c.object_id = ic.object_id AND c.column_id = ic.column_id
        WHERE ic.object_id = i.object_id AND ic.index_id = i.index_id AND ic.is_included_column = 0
        ORDER BY ic.key_ordinal
        FOR XML PATH('')), 1, 2, '') AS Colonnesdecle
FROM sys.indexes AS i
JOIN sys.partitions AS p ON p.object_id = i.object_id AND p.index_id = i.index_id
JOIN sys.allocation_units AS a ON a.container_id = p.partition_id
WHERE i.object_id = OBJECT_ID('dbo.[SOPIQ PROD$Reservation Entry$437dbf0e-84ff-417a-965d-ed2bb9650972]')
GROUP BY i.name, i.type_desc, p.rows, i.object_id, i.index_id
ORDER BY i.index_id;
GO

/* ---------------------------------------------------------------------
   BLOC 2 : creation de l'index couvrant, sur DEV.

   Les deux colonnes lues par la vue sont placees en colonnes incluses :
   elles ne servent pas a chercher, seulement a repondre. L'index reste
   donc etroit, et SQL n'a plus a retourner dans la table.
   --------------------------------------------------------------------- */
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = 'IDX_PERF_ReservEntry_Item'
      AND object_id = OBJECT_ID('dbo.[SOPIQ PROD$Reservation Entry$437dbf0e-84ff-417a-965d-ed2bb9650972]'))
BEGIN
    DECLARE @debut datetime = GETDATE();

    CREATE NONCLUSTERED INDEX IDX_PERF_ReservEntry_Item
        ON dbo.[SOPIQ PROD$Reservation Entry$437dbf0e-84ff-417a-965d-ed2bb9650972] ([Item No_])
        INCLUDE ([Source Type], [Quantity]);

    PRINT 'Index cree en ' + CAST(DATEDIFF(SECOND, @debut, GETDATE()) AS varchar) + ' secondes.';
END
ELSE
    PRINT 'Index deja present, rien a faire.';
GO

/* ---------------------------------------------------------------------
   BLOC 3 : la remesure. Exactement la meme requete que le bloc 5 du
   script test-index-reference-origine.sql, ni plus ni moins.

   A comparer : les analyses et les lectures de Reservation Entry et de
   Worktable. Le temps ecoule, lui, depend de ce que fait le serveur au
   meme moment, il est moins fiable.
   --------------------------------------------------------------------- */
SET STATISTICS IO ON;
SET STATISTICS TIME ON;

SELECT COUNT(*) AS NbLignes, SUM(CAST(X.Quantité AS bigint)) AS SommeControle
FROM (
    SELECT ILE.Qty - ISNULL(REC.Qty, 0) - ISNULL(RES.QtyHors37, 0) AS Quantité
    FROM dbo.[SOPIQ PROD$Item$437dbf0e-84ff-417a-965d-ed2bb9650972] AS I
    INNER JOIN dbo.[SOPIQ PROD$Item$ad36f199-c652-4e8e-9c9a-ca851e424760] AS IX
        ON IX.No_ = I.No_
    INNER JOIN dbo.[SOPIQ PROD$Manufacturer$437dbf0e-84ff-417a-965d-ed2bb9650972] AS M
        ON M.Code = I.[Manufacturer Code]
    INNER JOIN dbo.[SOPIQ PROD$Manufacturer$ad36f199-c652-4e8e-9c9a-ca851e424760] AS MX
        ON MX.Code = M.Code
    OUTER APPLY (
        SELECT SUM(E.Quantity) AS Qty
        FROM dbo.[SOPIQ PROD$Item Ledger Entry$437dbf0e-84ff-417a-965d-ed2bb9650972] AS E
        WHERE E.[Item No_] = I.No_
          AND E.[Location Code] NOT IN ('IMPORT', 'LITIGE', 'RESERVER')) AS ILE
    OUTER APPLY (
        SELECT SUM(W.Quantity) AS Qty
        FROM dbo.[SOPIQ PROD$Warehouse Entry$437dbf0e-84ff-417a-965d-ed2bb9650972] AS W
        WHERE W.[Item No_] = I.No_
          AND W.[Location Code] = 'CENTRAL'
          AND W.[Bin Code] = 'RECEPTION') AS REC
    OUTER APPLY (
        SELECT SUM(CASE WHEN R.[Source Type] <> 37 THEN R.Quantity END) AS QtyHors37
        FROM dbo.[SOPIQ PROD$Reservation Entry$437dbf0e-84ff-417a-965d-ed2bb9650972] AS R
        WHERE R.[Item No_] = I.No_) AS RES
    WHERE I.Type IN (0, 1)
      AND M.Code NOT IN ('FAB0278', 'FAB0281')
) AS X;

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
GO

/* ---------------------------------------------------------------------
   Retrait de l'index, si l'on veut revenir en arriere.
   --------------------------------------------------------------------- */
/*
DROP INDEX IDX_PERF_ReservEntry_Item
    ON dbo.[SOPIQ PROD$Reservation Entry$437dbf0e-84ff-417a-965d-ed2bb9650972];
*/
