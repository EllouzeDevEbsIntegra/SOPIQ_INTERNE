/* =====================================================================
   Vue Amiral_LS.dbo.ELVA_Item : reecriture des trois sommes.

   MODIFICATION D'UN OBJET UTILISE PAR LES APPLICATIONS EXTERNES.
   A ne lancer qu'apres decision, en periode creuse.

   Ce qui change : les trois OUTER APPLY, qui demandaient a SQL une somme
   par article, deviennent des jointures externes sur des sommes deja
   groupees par article. SQL calcule alors chaque total en une passe.

   Ce qui ne change pas : les vingt-neuf colonnes, leurs noms, leur type,
   leur ordre, et les valeurs qu'elles portent, NULL compris. Les
   applications externes ne verront aucune difference.

   Mesures du 26/09/2026 sur SOPIQ_DEV, copie des memes donnees,
   179 847 articles :

       version actuelle : 12 000 000 pages, 22,3 s UC, 17,2 s
       version reecrite :  1 941 000 pages,  6,1 s UC,  3,4 s

   Controle d'identite passe : comparaison des deux versions par EXCEPT,
   dans les deux sens, sur les vingt-neuf colonnes. Zero difference.
   Script du controle : docs/sql/test-vue-elva-complete.sql

   En production, cette requete a ete relevee a 257 executions pour
   14 300 secondes cumulees, sur une base partagee avec Business Central.

   RETOUR ARRIERE : la definition actuelle est conservee integralement en
   fin de fichier. La remettre en place rend l'etat d'avant a la seconde.
   ===================================================================== */

USE Amiral_LS;
GO

ALTER VIEW dbo.ELVA_Item
AS
SELECT I.No_,
       I.Description,
       IX.[Search Description2] AS [Search Description],
       CONCAT(I.[Description 2], I.No_) AS [Description 2],
       I.[Base Unit of Measure],
       I.Type,
       I.[Inventory Posting Group],
       I.[Unit Price],
       I.[Unit Cost],
       I.[Last Direct Cost],
       I.[Vendor No_],
       CASE IX.Produit WHEN 1 THEN REPLACE(I.No_, 'MASTER', '')
                       WHEN 0 THEN I.[Vendor Item No_] END AS [Vendor Item No_],
       I.Blocked,
       I.[Item Category Code],
       I.[Make Code],
       IX.[Description structurée],
       IX.[Item Product Code],
       IX.[Item Sub Product Code],
       IX.Groupe,
       IX.[Sous Groupe],
       IX.[Reference Origine Lié],
       M.Code AS [code Fabricant],
       M.Name AS Fabricant,
       MX.[ID TechDOC] AS [Tecdoc id fabricant],
       CASE WHEN M.Name LIKE 'ORIGINE%' THEN 1 ELSE 0 END AS isOEM,
       /* NULL si aucune écriture stock (comme avant) ; sinon stock - réception - réservations hors type 37 */
       ILE.Qty - ISNULL(REC.Qty, 0) - ISNULL(RES.QtyHors37, 0) AS Quantité,
       ISNULL(RES.Qty32, 0) AS ReservedQuantity,
       ISNULL(REC.Qty, 0) AS reception_qty,
       I.Id,
       IX.Produit,
       CASE WHEN EXISTS
           (SELECT 1
            FROM SOPIQ_PROD_BC16.dbo.[SOPIQ PROD$BOM Component$437dbf0e-84ff-417a-965d-ed2bb9650972] AS B
            WHERE B.[Parent Item No_] = I.No_) THEN 'OUI' ELSE 'NON' END AS isKit,
       CASE WHEN EXISTS
           (SELECT 1
            FROM SOPIQ_PROD_BC16.dbo.[SOPIQ PROD$Item Attribute Value Mapping$437dbf0e-84ff-417a-965d-ed2bb9650972] AS A
            WHERE A.No_ = I.No_) THEN 1 ELSE 0 END
       + CASE WHEN I.Picture = '00000000-0000-0000-0000-000000000000' THEN 0 ELSE 2 END AS HaveInfo,
       IX.[Champs libre],
       CASE WHEN EXISTS
           (SELECT 1
            FROM SOPIQ_PROD_BC16.dbo.[Tenant Media Set] AS TMS
            WHERE TMS.ID = I.Picture) THEN 1 ELSE 0 END AS HavePicture
FROM SOPIQ_PROD_BC16.dbo.[SOPIQ PROD$Item$437dbf0e-84ff-417a-965d-ed2bb9650972] AS I
INNER JOIN SOPIQ_PROD_BC16.dbo.[SOPIQ PROD$Item$ad36f199-c652-4e8e-9c9a-ca851e424760] AS IX
    ON IX.No_ = I.No_
INNER JOIN SOPIQ_PROD_BC16.dbo.[SOPIQ PROD$Manufacturer$437dbf0e-84ff-417a-965d-ed2bb9650972] AS M
    ON M.Code = I.[Manufacturer Code]
INNER JOIN SOPIQ_PROD_BC16.dbo.[SOPIQ PROD$Manufacturer$ad36f199-c652-4e8e-9c9a-ca851e424760] AS MX
    ON MX.Code = M.Code
/* Les trois sommes, calculees une fois chacune, groupees par article,
   puis rattachees par jointure externe. Une jointure externe sur une
   somme groupee rend exactement ce que rendait l'OUTER APPLY : la valeur
   si l'article a des ecritures, NULL sinon. */
LEFT JOIN (
    SELECT E.[Item No_] AS No_, SUM(E.Quantity) AS Qty
    FROM SOPIQ_PROD_BC16.dbo.[SOPIQ PROD$Item Ledger Entry$437dbf0e-84ff-417a-965d-ed2bb9650972] AS E
    WHERE E.[Location Code] NOT IN ('IMPORT', 'LITIGE', 'RESERVER')
    GROUP BY E.[Item No_]) AS ILE ON ILE.No_ = I.No_
LEFT JOIN (
    SELECT W.[Item No_] AS No_, SUM(W.Quantity) AS Qty
    FROM SOPIQ_PROD_BC16.dbo.[SOPIQ PROD$Warehouse Entry$437dbf0e-84ff-417a-965d-ed2bb9650972] AS W
    WHERE W.[Location Code] = 'CENTRAL' AND W.[Bin Code] = 'RECEPTION'
    GROUP BY W.[Item No_]) AS REC ON REC.No_ = I.No_
LEFT JOIN (
    SELECT R.[Item No_] AS No_,
           SUM(CASE WHEN R.[Source Type] <> 37 THEN R.Quantity END) AS QtyHors37,
           SUM(CASE WHEN R.[Source Type] = 32 THEN R.Quantity END) AS Qty32
    FROM SOPIQ_PROD_BC16.dbo.[SOPIQ PROD$Reservation Entry$437dbf0e-84ff-417a-965d-ed2bb9650972] AS R
    GROUP BY R.[Item No_]) AS RES ON RES.No_ = I.No_
WHERE I.Type IN (0, 1)
  AND M.Code NOT IN ('FAB0278', 'FAB0281');
GO

/* ---------------------------------------------------------------------
   Controle apres modification, a executer dans la foulee.
   Lecture seule. Les nombres doivent etre ceux d'avant.
   --------------------------------------------------------------------- */
SET STATISTICS TIME ON;

SELECT COUNT(*) AS NbLignes,
       SUM(CAST(Quantité AS bigint)) AS SommeQuantite,
       SUM(CAST(HaveInfo AS bigint)) AS SommeHaveInfo,
       SUM(CASE WHEN isKit = 'OUI' THEN 1 ELSE 0 END) AS NbKits,
       SUM(CAST(HavePicture AS bigint)) AS NbAvecImage
FROM dbo.ELVA_Item;

SET STATISTICS TIME OFF;
GO

/* =====================================================================
   RETOUR ARRIERE : definition d'origine, telle qu'elle etait au
   26/09/2026 avant modification. Enlever les marqueurs de commentaire
   et executer pour revenir a l'etat anterieur.
   =====================================================================

ALTER VIEW dbo.ELVA_Item
AS
SELECT I.No_, I.Description, IX.[Search Description2] AS [Search Description], { fn CONCAT(I.[Description 2], I.No_) } AS [Description 2], I.[Base Unit of Measure], I.Type, I.[Inventory Posting Group], I.[Unit Price], I.[Unit Cost], I.[Last Direct Cost],
                  I.[Vendor No_], CASE IX.Produit WHEN 1 THEN REPLACE(I.No_, 'MASTER', '') WHEN 0 THEN I.[Vendor Item No_] END AS [Vendor Item No_], I.Blocked, I.[Item Category Code], I.[Make Code], IX.[Description structurée], IX.[Item Product Code],
                  IX.[Item Sub Product Code], IX.Groupe, IX.[Sous Groupe], IX.[Reference Origine Lié], M.Code AS [code Fabricant], M.Name AS Fabricant, MX.[ID TechDOC] AS [Tecdoc id fabricant],
                  CASE WHEN M.Name LIKE 'ORIGINE%' THEN 1 ELSE 0 END AS isOEM, ILE.Qty - ISNULL(REC.Qty, 0) - ISNULL(RES.QtyHors37, 0)
                  AS Quantité, ISNULL(RES.Qty32, 0) AS ReservedQuantity, ISNULL(REC.Qty, 0) AS reception_qty, I.Id, IX.Produit, CASE WHEN EXISTS
                      (SELECT 1
                       FROM      SOPIQ_PROD_BC16.dbo.[SOPIQ PROD$BOM Component$437dbf0e-84ff-417a-965d-ed2bb9650972] AS B
                       WHERE   B.[Parent Item No_] = I.No_) THEN 'OUI' ELSE 'NON' END AS isKit, CASE WHEN EXISTS
                      (SELECT 1
                       FROM      SOPIQ_PROD_BC16.dbo.[SOPIQ PROD$Item Attribute Value Mapping$437dbf0e-84ff-417a-965d-ed2bb9650972] AS A
                       WHERE   A.No_ = I.No_) THEN 1 ELSE 0 END + CASE WHEN I.Picture = '00000000-0000-0000-0000-000000000000' THEN 0 ELSE 2 END AS HaveInfo, IX.[Champs libre],
                  CASE WHEN EXISTS
                      (SELECT 1
                       FROM      SOPIQ_PROD_BC16.dbo.[Tenant Media Set] AS TMS
                       WHERE   TMS.ID = I.Picture) THEN 1 ELSE 0 END AS HavePicture
FROM     SOPIQ_PROD_BC16.dbo.[SOPIQ PROD$Item$437dbf0e-84ff-417a-965d-ed2bb9650972] AS I INNER JOIN
                  SOPIQ_PROD_BC16.dbo.[SOPIQ PROD$Item$ad36f199-c652-4e8e-9c9a-ca851e424760] AS IX ON IX.No_ = I.No_ INNER JOIN
                  SOPIQ_PROD_BC16.dbo.[SOPIQ PROD$Manufacturer$437dbf0e-84ff-417a-965d-ed2bb9650972] AS M ON M.Code = I.[Manufacturer Code] INNER JOIN
                  SOPIQ_PROD_BC16.dbo.[SOPIQ PROD$Manufacturer$ad36f199-c652-4e8e-9c9a-ca851e424760] AS MX ON MX.Code = M.Code OUTER APPLY
                      (SELECT SUM(E.Quantity) AS Qty
                       FROM      SOPIQ_PROD_BC16.dbo.[SOPIQ PROD$Item Ledger Entry$437dbf0e-84ff-417a-965d-ed2bb9650972] AS E
                       WHERE   E.[Item No_] = I.No_ AND E.[Location Code] NOT IN ('IMPORT', 'LITIGE', 'RESERVER')) AS ILE OUTER APPLY
                      (SELECT SUM(W.Quantity) AS Qty
                       FROM      SOPIQ_PROD_BC16.dbo.[SOPIQ PROD$Warehouse Entry$437dbf0e-84ff-417a-965d-ed2bb9650972] AS W
                       WHERE   W.[Item No_] = I.No_ AND W.[Location Code] = 'CENTRAL' AND W.[Bin Code] = 'RECEPTION') AS REC OUTER APPLY
                      (SELECT SUM(CASE WHEN R.[Source Type] <> 37 THEN R.Quantity END) AS QtyHors37, SUM(CASE WHEN R.[Source Type] = 32 THEN R.Quantity END) AS Qty32
                       FROM      SOPIQ_PROD_BC16.dbo.[SOPIQ PROD$Reservation Entry$437dbf0e-84ff-417a-965d-ed2bb9650972] AS R
                       WHERE   R.[Item No_] = I.No_) AS RES
WHERE  I.Type IN (0, 1) AND M.Code NOT IN ('FAB0278', 'FAB0281');

===================================================================== */
