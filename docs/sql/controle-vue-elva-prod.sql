/* =====================================================================
   Controle d'identite de la vue ELVA_Item, sur les donnees de
   PRODUCTION, apres sa reecriture du 26/09/2026.

   La preuve d'identite avait ete faite sur SOPIQ_DEV, dont la copie
   date. Ce script la refait sur les donnees reelles : il compare la vue
   telle qu'elle est maintenant avec une requete qui reproduit sa
   definition d'avant, sur les vingt-neuf colonnes, dans les deux sens.

   EXCEPT compare les lignes entieres et traite NULL comme une valeur.
   Resultat attendu : deux zeros.

   Ce script ne fait que LIRE. Il ne modifie rien.

   Duree : plusieurs minutes. L'ancienne forme coute 34 a 81 secondes par
   passage, et il y en a deux. A lancer en periode creuse.
   ===================================================================== */

USE Amiral_LS;
GO

SET NOCOUNT ON;
GO

WITH AncienneForme AS (
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
                SELECT 1 FROM SOPIQ_PROD_BC16.dbo.[SOPIQ PROD$BOM Component$437dbf0e-84ff-417a-965d-ed2bb9650972] AS B
                WHERE B.[Parent Item No_] = I.No_) THEN 'OUI' ELSE 'NON' END AS isKit,
           CASE WHEN EXISTS (
                SELECT 1 FROM SOPIQ_PROD_BC16.dbo.[SOPIQ PROD$Item Attribute Value Mapping$437dbf0e-84ff-417a-965d-ed2bb9650972] AS A
                WHERE A.No_ = I.No_) THEN 1 ELSE 0 END
           + CASE WHEN I.Picture = '00000000-0000-0000-0000-000000000000' THEN 0 ELSE 2 END AS HaveInfo,
           IX.[Champs libre],
           CASE WHEN EXISTS (
                SELECT 1 FROM SOPIQ_PROD_BC16.dbo.[Tenant Media Set] AS TMS
                WHERE TMS.ID = I.Picture) THEN 1 ELSE 0 END AS HavePicture
    FROM SOPIQ_PROD_BC16.dbo.[SOPIQ PROD$Item$437dbf0e-84ff-417a-965d-ed2bb9650972] AS I
    INNER JOIN SOPIQ_PROD_BC16.dbo.[SOPIQ PROD$Item$ad36f199-c652-4e8e-9c9a-ca851e424760] AS IX
        ON IX.No_ = I.No_
    INNER JOIN SOPIQ_PROD_BC16.dbo.[SOPIQ PROD$Manufacturer$437dbf0e-84ff-417a-965d-ed2bb9650972] AS M
        ON M.Code = I.[Manufacturer Code]
    INNER JOIN SOPIQ_PROD_BC16.dbo.[SOPIQ PROD$Manufacturer$ad36f199-c652-4e8e-9c9a-ca851e424760] AS MX
        ON MX.Code = M.Code
    OUTER APPLY (
        SELECT SUM(E.Quantity) AS Qty
        FROM SOPIQ_PROD_BC16.dbo.[SOPIQ PROD$Item Ledger Entry$437dbf0e-84ff-417a-965d-ed2bb9650972] AS E
        WHERE E.[Item No_] = I.No_
          AND E.[Location Code] NOT IN ('IMPORT', 'LITIGE', 'RESERVER')) AS ILE
    OUTER APPLY (
        SELECT SUM(W.Quantity) AS Qty
        FROM SOPIQ_PROD_BC16.dbo.[SOPIQ PROD$Warehouse Entry$437dbf0e-84ff-417a-965d-ed2bb9650972] AS W
        WHERE W.[Item No_] = I.No_ AND W.[Location Code] = 'CENTRAL' AND W.[Bin Code] = 'RECEPTION') AS REC
    OUTER APPLY (
        SELECT SUM(CASE WHEN R.[Source Type] <> 37 THEN R.Quantity END) AS QtyHors37,
               SUM(CASE WHEN R.[Source Type] = 32 THEN R.Quantity END) AS Qty32
        FROM SOPIQ_PROD_BC16.dbo.[SOPIQ PROD$Reservation Entry$437dbf0e-84ff-417a-965d-ed2bb9650972] AS R
        WHERE R.[Item No_] = I.No_) AS RES
    WHERE I.Type IN (0, 1) AND M.Code NOT IN ('FAB0278', 'FAB0281')
),
VueActuelle AS (
    SELECT No_, Description, [Search Description], [Description 2], [Base Unit of Measure],
           Type, [Inventory Posting Group], [Unit Price], [Unit Cost], [Last Direct Cost],
           [Vendor No_], [Vendor Item No_], Blocked, [Item Category Code], [Make Code],
           [Description structurée], [Item Product Code], [Item Sub Product Code], Groupe,
           [Sous Groupe], [Reference Origine Lié], [code Fabricant], Fabricant,
           [Tecdoc id fabricant], isOEM, Quantité, ReservedQuantity, reception_qty, Id,
           Produit, isKit, HaveInfo, [Champs libre], HavePicture
    FROM dbo.ELVA_Item
)
SELECT 'Dans l ancienne forme, absent de la vue' AS Sens,
       COUNT(*) AS NbLignesDifferentes
FROM (SELECT * FROM AncienneForme EXCEPT SELECT * FROM VueActuelle) AS D1
UNION ALL
SELECT 'Dans la vue, absent de l ancienne forme',
       COUNT(*)
FROM (SELECT * FROM VueActuelle EXCEPT SELECT * FROM AncienneForme) AS D2;
GO
