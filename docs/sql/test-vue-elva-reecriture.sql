/* =====================================================================
   Vue ELVA_Item : essai d'une reecriture des trois sommes.

   Etat des lieux, mesure du 26/09/2026 sur SOPIQ_DEV, 179 847 articles :

       version actuelle, sans index      : 12,0 millions de pages, 22,3 s UC
       version actuelle, avec l'index
       de Reservation Entry              :  8,5 millions de pages, 16,2 s UC

   Ce qui reste : 7 948 508 lectures sur la table de travail, en 359 694
   analyses, soit deux par article. Les trois OUTER APPLY demandent a SQL
   une somme par article ; il calcule bien les totaux une fois, mais
   revient ensuite y repiocher article par article.

   L'idee testee ici : calculer chaque somme une seule fois, groupee par
   article, puis rattacher le resultat par une jointure externe. SQL fait
   alors trois regroupements en une passe et trois jointures, sans boucle.

   Les resultats doivent etre IDENTIQUES a ceux de la version actuelle,
   y compris le NULL laisse aux articles sans ecriture de stock, que la
   vue conserve volontairement. Le bloc 3 le verifie ligne par ligne.

   Ce script ne fait que LIRE. Il ne cree ni ne modifie aucun objet, et
   surtout il ne touche pas a la vue de production.
   ===================================================================== */

USE SOPIQ_DEV;
GO

SET NOCOUNT ON;
GO

/* ---------------------------------------------------------------------
   BLOC 1 : la version reecrite, mesuree.
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
    LEFT JOIN (
        SELECT E.[Item No_] AS No_, SUM(E.Quantity) AS Qty
        FROM dbo.[SOPIQ PROD$Item Ledger Entry$437dbf0e-84ff-417a-965d-ed2bb9650972] AS E
        WHERE E.[Location Code] NOT IN ('IMPORT', 'LITIGE', 'RESERVER')
        GROUP BY E.[Item No_]) AS ILE ON ILE.No_ = I.No_
    LEFT JOIN (
        SELECT W.[Item No_] AS No_, SUM(W.Quantity) AS Qty
        FROM dbo.[SOPIQ PROD$Warehouse Entry$437dbf0e-84ff-417a-965d-ed2bb9650972] AS W
        WHERE W.[Location Code] = 'CENTRAL' AND W.[Bin Code] = 'RECEPTION'
        GROUP BY W.[Item No_]) AS REC ON REC.No_ = I.No_
    LEFT JOIN (
        SELECT R.[Item No_] AS No_,
               SUM(CASE WHEN R.[Source Type] <> 37 THEN R.Quantity END) AS QtyHors37
        FROM dbo.[SOPIQ PROD$Reservation Entry$437dbf0e-84ff-417a-965d-ed2bb9650972] AS R
        GROUP BY R.[Item No_]) AS RES ON RES.No_ = I.No_
    WHERE I.Type IN (0, 1)
      AND M.Code NOT IN ('FAB0278', 'FAB0281')
) AS X;

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
GO

/* ---------------------------------------------------------------------
   BLOC 2 : le controle d'identite, article par article.

   On rejoue les deux versions et on ne garde que les articles ou elles
   ne disent pas la meme chose, NULL compris. Le resultat attendu est
   vide : zero ligne, zero difference.
   --------------------------------------------------------------------- */
WITH Actuelle AS (
    SELECT I.No_,
           ILE.Qty - ISNULL(REC.Qty, 0) - ISNULL(RES.QtyHors37, 0) AS Quantité,
           ISNULL(RES.Qty32, 0) AS ReservedQuantity,
           ISNULL(REC.Qty, 0) AS reception_qty
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
        SELECT SUM(CASE WHEN R.[Source Type] <> 37 THEN R.Quantity END) AS QtyHors37,
               SUM(CASE WHEN R.[Source Type] = 32 THEN R.Quantity END) AS Qty32
        FROM dbo.[SOPIQ PROD$Reservation Entry$437dbf0e-84ff-417a-965d-ed2bb9650972] AS R
        WHERE R.[Item No_] = I.No_) AS RES
    WHERE I.Type IN (0, 1)
      AND M.Code NOT IN ('FAB0278', 'FAB0281')
),
Reecrite AS (
    SELECT I.No_,
           ILE.Qty - ISNULL(REC.Qty, 0) - ISNULL(RES.QtyHors37, 0) AS Quantité,
           ISNULL(RES.Qty32, 0) AS ReservedQuantity,
           ISNULL(REC.Qty, 0) AS reception_qty
    FROM dbo.[SOPIQ PROD$Item$437dbf0e-84ff-417a-965d-ed2bb9650972] AS I
    INNER JOIN dbo.[SOPIQ PROD$Item$ad36f199-c652-4e8e-9c9a-ca851e424760] AS IX
        ON IX.No_ = I.No_
    INNER JOIN dbo.[SOPIQ PROD$Manufacturer$437dbf0e-84ff-417a-965d-ed2bb9650972] AS M
        ON M.Code = I.[Manufacturer Code]
    INNER JOIN dbo.[SOPIQ PROD$Manufacturer$ad36f199-c652-4e8e-9c9a-ca851e424760] AS MX
        ON MX.Code = M.Code
    LEFT JOIN (
        SELECT E.[Item No_] AS No_, SUM(E.Quantity) AS Qty
        FROM dbo.[SOPIQ PROD$Item Ledger Entry$437dbf0e-84ff-417a-965d-ed2bb9650972] AS E
        WHERE E.[Location Code] NOT IN ('IMPORT', 'LITIGE', 'RESERVER')
        GROUP BY E.[Item No_]) AS ILE ON ILE.No_ = I.No_
    LEFT JOIN (
        SELECT W.[Item No_] AS No_, SUM(W.Quantity) AS Qty
        FROM dbo.[SOPIQ PROD$Warehouse Entry$437dbf0e-84ff-417a-965d-ed2bb9650972] AS W
        WHERE W.[Location Code] = 'CENTRAL' AND W.[Bin Code] = 'RECEPTION'
        GROUP BY W.[Item No_]) AS REC ON REC.No_ = I.No_
    LEFT JOIN (
        SELECT R.[Item No_] AS No_,
               SUM(CASE WHEN R.[Source Type] <> 37 THEN R.Quantity END) AS QtyHors37,
               SUM(CASE WHEN R.[Source Type] = 32 THEN R.Quantity END) AS Qty32
        FROM dbo.[SOPIQ PROD$Reservation Entry$437dbf0e-84ff-417a-965d-ed2bb9650972] AS R
        GROUP BY R.[Item No_]) AS RES ON RES.No_ = I.No_
    WHERE I.Type IN (0, 1)
      AND M.Code NOT IN ('FAB0278', 'FAB0281')
)
SELECT TOP 50
    A.No_ AS Article,
    A.Quantité AS QuantiteActuelle,
    R.Quantité AS QuantiteReecrite,
    A.ReservedQuantity AS ReserveeActuelle,
    R.ReservedQuantity AS ReserveeReecrite,
    A.reception_qty AS ReceptionActuelle,
    R.reception_qty AS ReceptionReecrite
FROM Actuelle AS A
JOIN Reecrite AS R ON R.No_ = A.No_
WHERE EXISTS (SELECT A.Quantité, A.ReservedQuantity, A.reception_qty
              EXCEPT
              SELECT R.Quantité, R.ReservedQuantity, R.reception_qty);
GO
