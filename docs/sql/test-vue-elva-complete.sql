/* =====================================================================
   Vue ELVA_Item, version complete : mesure et controle d'identite sur
   les vingt-neuf colonnes.

   Le test precedent ne portait que sur les trois sommes, et il a donne
   sur SOPIQ_DEV, pour 179 847 articles :

       version actuelle : 12 000 000 pages, 22,3 s UC, 17,2 s
       version reecrite :    138 000 pages,  3,1 s UC,  1,8 s

   Mais la vraie vue contient aussi trois sous-requetes par article :
   isKit sur les nomenclatures, HaveInfo sur les attributs, HavePicture
   sur les images. Elles n'etaient pas dans la maquette. Ce script
   reproduit la vue entiere, telle qu'elle est definie en production, et
   compare les deux versions colonne par colonne.

   Seule difference entre les deux : les trois OUTER APPLY deviennent des
   jointures externes sur des sommes deja groupees par article. Tout le
   reste est recopie a l'identique.

   Ce script ne fait que LIRE. La vue de production n'est pas touchee.
   ===================================================================== */

USE SOPIQ_DEV;
GO

SET NOCOUNT ON;
GO

/* ---------------------------------------------------------------------
   BLOC 1 : la vue complete, version ACTUELLE, mesuree.
   Long : c'est la requete qui coute 34 a 81 secondes en production.
   --------------------------------------------------------------------- */
SET STATISTICS IO ON;
SET STATISTICS TIME ON;

SELECT COUNT(*) AS NbLignes,
       SUM(CAST(X.Quantité AS bigint)) AS SommeQuantite,
       SUM(CAST(X.HaveInfo AS bigint)) AS SommeHaveInfo,
       SUM(CASE WHEN X.isKit = 'OUI' THEN 1 ELSE 0 END) AS NbKits,
       SUM(CAST(X.HavePicture AS bigint)) AS NbAvecImage
FROM (
    SELECT ILE.Qty - ISNULL(REC.Qty, 0) - ISNULL(RES.QtyHors37, 0) AS Quantité,
           CASE WHEN EXISTS (
                SELECT 1 FROM dbo.[SOPIQ PROD$BOM Component$437dbf0e-84ff-417a-965d-ed2bb9650972] AS B
                WHERE B.[Parent Item No_] = I.No_) THEN 'OUI' ELSE 'NON' END AS isKit,
           CASE WHEN EXISTS (
                SELECT 1 FROM dbo.[SOPIQ PROD$Item Attribute Value Mapping$437dbf0e-84ff-417a-965d-ed2bb9650972] AS A
                WHERE A.No_ = I.No_) THEN 1 ELSE 0 END
           + CASE WHEN I.Picture = '00000000-0000-0000-0000-000000000000' THEN 0 ELSE 2 END AS HaveInfo,
           CASE WHEN EXISTS (
                SELECT 1 FROM dbo.[Tenant Media Set] AS TMS
                WHERE TMS.ID = I.Picture) THEN 1 ELSE 0 END AS HavePicture
    FROM dbo.[SOPIQ PROD$Item$437dbf0e-84ff-417a-965d-ed2bb9650972] AS I
    INNER JOIN dbo.[SOPIQ PROD$Item$ad36f199-c652-4e8e-9c9a-ca851e424760] AS IX ON IX.No_ = I.No_
    INNER JOIN dbo.[SOPIQ PROD$Manufacturer$437dbf0e-84ff-417a-965d-ed2bb9650972] AS M ON M.Code = I.[Manufacturer Code]
    INNER JOIN dbo.[SOPIQ PROD$Manufacturer$ad36f199-c652-4e8e-9c9a-ca851e424760] AS MX ON MX.Code = M.Code
    OUTER APPLY (
        SELECT SUM(E.Quantity) AS Qty
        FROM dbo.[SOPIQ PROD$Item Ledger Entry$437dbf0e-84ff-417a-965d-ed2bb9650972] AS E
        WHERE E.[Item No_] = I.No_
          AND E.[Location Code] NOT IN ('IMPORT', 'LITIGE', 'RESERVER')) AS ILE
    OUTER APPLY (
        SELECT SUM(W.Quantity) AS Qty
        FROM dbo.[SOPIQ PROD$Warehouse Entry$437dbf0e-84ff-417a-965d-ed2bb9650972] AS W
        WHERE W.[Item No_] = I.No_ AND W.[Location Code] = 'CENTRAL' AND W.[Bin Code] = 'RECEPTION') AS REC
    OUTER APPLY (
        SELECT SUM(CASE WHEN R.[Source Type] <> 37 THEN R.Quantity END) AS QtyHors37,
               SUM(CASE WHEN R.[Source Type] = 32 THEN R.Quantity END) AS Qty32
        FROM dbo.[SOPIQ PROD$Reservation Entry$437dbf0e-84ff-417a-965d-ed2bb9650972] AS R
        WHERE R.[Item No_] = I.No_) AS RES
    WHERE I.Type IN (0, 1) AND M.Code NOT IN ('FAB0278', 'FAB0281')
) AS X;

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
GO

/* ---------------------------------------------------------------------
   BLOC 2 : la meme vue, version REECRITE, mesuree.
   --------------------------------------------------------------------- */
SET STATISTICS IO ON;
SET STATISTICS TIME ON;

SELECT COUNT(*) AS NbLignes,
       SUM(CAST(X.Quantité AS bigint)) AS SommeQuantite,
       SUM(CAST(X.HaveInfo AS bigint)) AS SommeHaveInfo,
       SUM(CASE WHEN X.isKit = 'OUI' THEN 1 ELSE 0 END) AS NbKits,
       SUM(CAST(X.HavePicture AS bigint)) AS NbAvecImage
FROM (
    SELECT ILE.Qty - ISNULL(REC.Qty, 0) - ISNULL(RES.QtyHors37, 0) AS Quantité,
           CASE WHEN EXISTS (
                SELECT 1 FROM dbo.[SOPIQ PROD$BOM Component$437dbf0e-84ff-417a-965d-ed2bb9650972] AS B
                WHERE B.[Parent Item No_] = I.No_) THEN 'OUI' ELSE 'NON' END AS isKit,
           CASE WHEN EXISTS (
                SELECT 1 FROM dbo.[SOPIQ PROD$Item Attribute Value Mapping$437dbf0e-84ff-417a-965d-ed2bb9650972] AS A
                WHERE A.No_ = I.No_) THEN 1 ELSE 0 END
           + CASE WHEN I.Picture = '00000000-0000-0000-0000-000000000000' THEN 0 ELSE 2 END AS HaveInfo,
           CASE WHEN EXISTS (
                SELECT 1 FROM dbo.[Tenant Media Set] AS TMS
                WHERE TMS.ID = I.Picture) THEN 1 ELSE 0 END AS HavePicture
    FROM dbo.[SOPIQ PROD$Item$437dbf0e-84ff-417a-965d-ed2bb9650972] AS I
    INNER JOIN dbo.[SOPIQ PROD$Item$ad36f199-c652-4e8e-9c9a-ca851e424760] AS IX ON IX.No_ = I.No_
    INNER JOIN dbo.[SOPIQ PROD$Manufacturer$437dbf0e-84ff-417a-965d-ed2bb9650972] AS M ON M.Code = I.[Manufacturer Code]
    INNER JOIN dbo.[SOPIQ PROD$Manufacturer$ad36f199-c652-4e8e-9c9a-ca851e424760] AS MX ON MX.Code = M.Code
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
    WHERE I.Type IN (0, 1) AND M.Code NOT IN ('FAB0278', 'FAB0281')
) AS X;

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
GO

/* ---------------------------------------------------------------------
   BLOC 3 : le controle d'identite sur toutes les colonnes de la vue.

   EXCEPT compare les lignes entieres, colonne par colonne, en traitant
   NULL comme une valeur a part entiere. On le fait dans les deux sens :
   ce qui est dans l'une sans etre dans l'autre, et l'inverse.

   Resultat attendu : deux zeros. Toute autre valeur interdit de toucher
   a la vue.
   --------------------------------------------------------------------- */
WITH Actuelle AS (
    SELECT I.No_, I.Description, IX.[Search Description2] AS [Search Description],
           CONCAT(I.[Description 2], I.No_) AS [Description 2],
           I.[Base Unit of Measure], I.Type, I.[Inventory Posting Group],
           I.[Unit Price], I.[Unit Cost], I.[Last Direct Cost], I.[Vendor No_],
           CASE IX.Produit WHEN 1 THEN REPLACE(I.No_, 'MASTER', '')
                           WHEN 0 THEN I.[Vendor Item No_] END AS [Vendor Item No_],
           I.Blocked, I.[Item Category Code], I.[Make Code], IX.[Description structurée],
           IX.[Item Product Code], IX.[Item Sub Product Code], IX.Groupe, IX.[Sous Groupe],
           IX.[Reference Origine Lié], M.Code AS [code Fabricant], M.Name AS Fabricant,
           MX.[ID TechDOC] AS [Tecdoc id fabricant],
           CASE WHEN M.Name LIKE 'ORIGINE%' THEN 1 ELSE 0 END AS isOEM,
           ILE.Qty - ISNULL(REC.Qty, 0) - ISNULL(RES.QtyHors37, 0) AS Quantité,
           ISNULL(RES.Qty32, 0) AS ReservedQuantity, ISNULL(REC.Qty, 0) AS reception_qty,
           I.Id, IX.Produit,
           CASE WHEN EXISTS (
                SELECT 1 FROM dbo.[SOPIQ PROD$BOM Component$437dbf0e-84ff-417a-965d-ed2bb9650972] AS B
                WHERE B.[Parent Item No_] = I.No_) THEN 'OUI' ELSE 'NON' END AS isKit,
           CASE WHEN EXISTS (
                SELECT 1 FROM dbo.[SOPIQ PROD$Item Attribute Value Mapping$437dbf0e-84ff-417a-965d-ed2bb9650972] AS A
                WHERE A.No_ = I.No_) THEN 1 ELSE 0 END
           + CASE WHEN I.Picture = '00000000-0000-0000-0000-000000000000' THEN 0 ELSE 2 END AS HaveInfo,
           IX.[Champs libre],
           CASE WHEN EXISTS (
                SELECT 1 FROM dbo.[Tenant Media Set] AS TMS
                WHERE TMS.ID = I.Picture) THEN 1 ELSE 0 END AS HavePicture
    FROM dbo.[SOPIQ PROD$Item$437dbf0e-84ff-417a-965d-ed2bb9650972] AS I
    INNER JOIN dbo.[SOPIQ PROD$Item$ad36f199-c652-4e8e-9c9a-ca851e424760] AS IX ON IX.No_ = I.No_
    INNER JOIN dbo.[SOPIQ PROD$Manufacturer$437dbf0e-84ff-417a-965d-ed2bb9650972] AS M ON M.Code = I.[Manufacturer Code]
    INNER JOIN dbo.[SOPIQ PROD$Manufacturer$ad36f199-c652-4e8e-9c9a-ca851e424760] AS MX ON MX.Code = M.Code
    OUTER APPLY (
        SELECT SUM(E.Quantity) AS Qty
        FROM dbo.[SOPIQ PROD$Item Ledger Entry$437dbf0e-84ff-417a-965d-ed2bb9650972] AS E
        WHERE E.[Item No_] = I.No_
          AND E.[Location Code] NOT IN ('IMPORT', 'LITIGE', 'RESERVER')) AS ILE
    OUTER APPLY (
        SELECT SUM(W.Quantity) AS Qty
        FROM dbo.[SOPIQ PROD$Warehouse Entry$437dbf0e-84ff-417a-965d-ed2bb9650972] AS W
        WHERE W.[Item No_] = I.No_ AND W.[Location Code] = 'CENTRAL' AND W.[Bin Code] = 'RECEPTION') AS REC
    OUTER APPLY (
        SELECT SUM(CASE WHEN R.[Source Type] <> 37 THEN R.Quantity END) AS QtyHors37,
               SUM(CASE WHEN R.[Source Type] = 32 THEN R.Quantity END) AS Qty32
        FROM dbo.[SOPIQ PROD$Reservation Entry$437dbf0e-84ff-417a-965d-ed2bb9650972] AS R
        WHERE R.[Item No_] = I.No_) AS RES
    WHERE I.Type IN (0, 1) AND M.Code NOT IN ('FAB0278', 'FAB0281')
),
Reecrite AS (
    SELECT I.No_, I.Description, IX.[Search Description2] AS [Search Description],
           CONCAT(I.[Description 2], I.No_) AS [Description 2],
           I.[Base Unit of Measure], I.Type, I.[Inventory Posting Group],
           I.[Unit Price], I.[Unit Cost], I.[Last Direct Cost], I.[Vendor No_],
           CASE IX.Produit WHEN 1 THEN REPLACE(I.No_, 'MASTER', '')
                           WHEN 0 THEN I.[Vendor Item No_] END AS [Vendor Item No_],
           I.Blocked, I.[Item Category Code], I.[Make Code], IX.[Description structurée],
           IX.[Item Product Code], IX.[Item Sub Product Code], IX.Groupe, IX.[Sous Groupe],
           IX.[Reference Origine Lié], M.Code AS [code Fabricant], M.Name AS Fabricant,
           MX.[ID TechDOC] AS [Tecdoc id fabricant],
           CASE WHEN M.Name LIKE 'ORIGINE%' THEN 1 ELSE 0 END AS isOEM,
           ILE.Qty - ISNULL(REC.Qty, 0) - ISNULL(RES.QtyHors37, 0) AS Quantité,
           ISNULL(RES.Qty32, 0) AS ReservedQuantity, ISNULL(REC.Qty, 0) AS reception_qty,
           I.Id, IX.Produit,
           CASE WHEN EXISTS (
                SELECT 1 FROM dbo.[SOPIQ PROD$BOM Component$437dbf0e-84ff-417a-965d-ed2bb9650972] AS B
                WHERE B.[Parent Item No_] = I.No_) THEN 'OUI' ELSE 'NON' END AS isKit,
           CASE WHEN EXISTS (
                SELECT 1 FROM dbo.[SOPIQ PROD$Item Attribute Value Mapping$437dbf0e-84ff-417a-965d-ed2bb9650972] AS A
                WHERE A.No_ = I.No_) THEN 1 ELSE 0 END
           + CASE WHEN I.Picture = '00000000-0000-0000-0000-000000000000' THEN 0 ELSE 2 END AS HaveInfo,
           IX.[Champs libre],
           CASE WHEN EXISTS (
                SELECT 1 FROM dbo.[Tenant Media Set] AS TMS
                WHERE TMS.ID = I.Picture) THEN 1 ELSE 0 END AS HavePicture
    FROM dbo.[SOPIQ PROD$Item$437dbf0e-84ff-417a-965d-ed2bb9650972] AS I
    INNER JOIN dbo.[SOPIQ PROD$Item$ad36f199-c652-4e8e-9c9a-ca851e424760] AS IX ON IX.No_ = I.No_
    INNER JOIN dbo.[SOPIQ PROD$Manufacturer$437dbf0e-84ff-417a-965d-ed2bb9650972] AS M ON M.Code = I.[Manufacturer Code]
    INNER JOIN dbo.[SOPIQ PROD$Manufacturer$ad36f199-c652-4e8e-9c9a-ca851e424760] AS MX ON MX.Code = M.Code
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
    WHERE I.Type IN (0, 1) AND M.Code NOT IN ('FAB0278', 'FAB0281')
)
SELECT 'Dans l actuelle, absent de la reecrite' AS Sens,
       COUNT(*) AS NbLignesDifferentes
FROM (SELECT * FROM Actuelle EXCEPT SELECT * FROM Reecrite) AS D1
UNION ALL
SELECT 'Dans la reecrite, absent de l actuelle',
       COUNT(*)
FROM (SELECT * FROM Reecrite EXCEPT SELECT * FROM Actuelle) AS D2;
GO
