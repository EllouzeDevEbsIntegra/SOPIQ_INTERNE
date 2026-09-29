/* =====================================================================
   Essai : rendre indexable le filtre le plus utilisé de ELVA_ITEM.

   Le probleme. Les applications connectees filtrent ainsi :

       SELECT [Vendor Item No_], [Reference Origine Lié], [Tecdoc id fabricant]
       FROM ELVA_ITEM WHERE [Vendor Item No_] IN (...)

   Or dans la vue, cette colonne n'est pas une colonne mais un calcul :

       CASE IX.Produit WHEN 1 THEN REPLACE(I.No_, 'MASTER', '')
                       WHEN 0 THEN I.[Vendor Item No_] END

   SQL Server doit donc le refaire pour chacun des 193 305 articles avant de
   pouvoir filtrer. Mesure du 29/09/2026 : 47 214 pages lues par appel, et une
   quinzaine d'appels en vingt secondes.

   L'idee. Couper la lecture en deux selon Produit. Pour les 161 834 articles
   en Produit = 0, soit 84 %, le filtre retombe sur la vraie colonne
   [Vendor Item No_], qu'un index peut servir. Les 31 471 autres gardent le
   REPLACE, mais sur un sixieme des lignes.

   Rien ne changerait pour les applications : meme nom de vue, memes colonnes,
   memes lignes. Ce script ne modifie PAS la vue, il verifie seulement que
   l'idee tient avant d'y toucher.

   Mode d'emploi, bloc par bloc, en lisant les messages de l'onglet Messages.
   ===================================================================== */

USE SOPIQ_PROD_BC16;
GO

SET STATISTICS IO ON;
SET STATISTICS TIME ON;
GO

/* ---------------------------------------------------------------------
   BLOC 1 : la situation actuelle, pour avoir le chiffre de depart.
   Relever le nombre de lectures logiques dans l'onglet Messages.
   --------------------------------------------------------------------- */
SELECT [Vendor Item No_], [Reference Origine Lié], [Tecdoc id fabricant]
FROM Amiral_LS.dbo.ELVA_ITEM
WHERE [Vendor Item No_] IN (
    '003-30-12724','B3512125','B3512126','88-085-A','200823','200972','BMDS-G20',
    '04435','09203','43470','43488','43489','865303001','41-0020','41-0037',
    '41-2071','41-2093','41-2109','1695001','4416401','3141522110/HD',
    '3141523102/HD','F8-6763','22782','773000810','20860007','20860012',
    '20943470','20943488','20943489','500292','V20-1065','V20-18003','V20-18005');
GO

/* ---------------------------------------------------------------------
   BLOC 2 : l'index. C'est la seule ecriture de ce script.

   Il porte sur une colonne ordinaire de la table article. Il ne change ni
   les donnees, ni le schema connu de Business Central. Retour arriere en
   une ligne, voir le bloc 5.

   La creation en ligne n'existe pas en edition Standard : l'index se
   construit donc hors ligne, en verrouillant brievement la table article.
   Quelques secondes sur 193 000 articles, a lancer en heure creuse.
   --------------------------------------------------------------------- */
CREATE NONCLUSTERED INDEX IDX_PERF_Item_VendorItemNo
    ON dbo.[SOPIQ PROD$Item$437dbf0e-84ff-417a-965d-ed2bb9650972] ([Vendor Item No_])
    INCLUDE ([Manufacturer Code])
    WITH (DATA_COMPRESSION = PAGE);
GO

/* ---------------------------------------------------------------------
   BLOC 3 : la lecture coupee en deux, ecrite a la main.

   Elle rend exactement les memes colonnes que le bloc 1. La premiere
   moitie peut desormais utiliser l'index, la seconde garde le REPLACE
   mais sur les seuls articles en Produit = 1.
   --------------------------------------------------------------------- */
SELECT I.[Vendor Item No_] AS [Vendor Item No_],
       IX.[Reference Origine Lié],
       MX.[ID TechDOC] AS [Tecdoc id fabricant]
FROM dbo.[SOPIQ PROD$Item$437dbf0e-84ff-417a-965d-ed2bb9650972] AS I
INNER JOIN dbo.[SOPIQ PROD$Item$ad36f199-c652-4e8e-9c9a-ca851e424760] AS IX
    ON IX.No_ = I.No_
INNER JOIN dbo.[SOPIQ PROD$Manufacturer$437dbf0e-84ff-417a-965d-ed2bb9650972] AS M
    ON M.Code = I.[Manufacturer Code]
INNER JOIN dbo.[SOPIQ PROD$Manufacturer$ad36f199-c652-4e8e-9c9a-ca851e424760] AS MX
    ON MX.Code = M.Code
WHERE IX.Produit = 0
  AND I.[Vendor Item No_] IN (
    '003-30-12724','B3512125','B3512126','88-085-A','200823','200972','BMDS-G20',
    '04435','09203','43470','43488','43489','865303001','41-0020','41-0037',
    '41-2071','41-2093','41-2109','1695001','4416401','3141522110/HD',
    '3141523102/HD','F8-6763','22782','773000810','20860007','20860012',
    '20943470','20943488','20943489','500292','V20-1065','V20-18003','V20-18005')

UNION ALL

SELECT REPLACE(I.No_, 'MASTER', '') AS [Vendor Item No_],
       IX.[Reference Origine Lié],
       MX.[ID TechDOC] AS [Tecdoc id fabricant]
FROM dbo.[SOPIQ PROD$Item$437dbf0e-84ff-417a-965d-ed2bb9650972] AS I
INNER JOIN dbo.[SOPIQ PROD$Item$ad36f199-c652-4e8e-9c9a-ca851e424760] AS IX
    ON IX.No_ = I.No_
INNER JOIN dbo.[SOPIQ PROD$Manufacturer$437dbf0e-84ff-417a-965d-ed2bb9650972] AS M
    ON M.Code = I.[Manufacturer Code]
INNER JOIN dbo.[SOPIQ PROD$Manufacturer$ad36f199-c652-4e8e-9c9a-ca851e424760] AS MX
    ON MX.Code = M.Code
WHERE IX.Produit = 1
  AND REPLACE(I.No_, 'MASTER', '') IN (
    '003-30-12724','B3512125','B3512126','88-085-A','200823','200972','BMDS-G20',
    '04435','09203','43470','43488','43489','865303001','41-0020','41-0037',
    '41-2071','41-2093','41-2109','1695001','4416401','3141522110/HD',
    '3141523102/HD','F8-6763','22782','773000810','20860007','20860012',
    '20943470','20943488','20943489','500292','V20-1065','V20-18003','V20-18005');
GO

/* ---------------------------------------------------------------------
   BLOC 4 : la preuve que les deux rendent la meme chose.

   Les deux EXCEPT doivent rendre zero ligne chacun. S'ils en rendent une
   seule, l'idee est fausse et on s'arrete la.
   --------------------------------------------------------------------- */
SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
GO

WITH Actuel AS (
    SELECT [Vendor Item No_], [Reference Origine Lié], [Tecdoc id fabricant]
    FROM Amiral_LS.dbo.ELVA_ITEM
), Coupee AS (
    SELECT I.[Vendor Item No_] AS [Vendor Item No_], IX.[Reference Origine Lié],
           MX.[ID TechDOC] AS [Tecdoc id fabricant]
    FROM dbo.[SOPIQ PROD$Item$437dbf0e-84ff-417a-965d-ed2bb9650972] AS I
    INNER JOIN dbo.[SOPIQ PROD$Item$ad36f199-c652-4e8e-9c9a-ca851e424760] AS IX ON IX.No_ = I.No_
    INNER JOIN dbo.[SOPIQ PROD$Manufacturer$437dbf0e-84ff-417a-965d-ed2bb9650972] AS M ON M.Code = I.[Manufacturer Code]
    INNER JOIN dbo.[SOPIQ PROD$Manufacturer$ad36f199-c652-4e8e-9c9a-ca851e424760] AS MX ON MX.Code = M.Code
    WHERE IX.Produit = 0
    UNION ALL
    SELECT REPLACE(I.No_, 'MASTER', ''), IX.[Reference Origine Lié], MX.[ID TechDOC]
    FROM dbo.[SOPIQ PROD$Item$437dbf0e-84ff-417a-965d-ed2bb9650972] AS I
    INNER JOIN dbo.[SOPIQ PROD$Item$ad36f199-c652-4e8e-9c9a-ca851e424760] AS IX ON IX.No_ = I.No_
    INNER JOIN dbo.[SOPIQ PROD$Manufacturer$437dbf0e-84ff-417a-965d-ed2bb9650972] AS M ON M.Code = I.[Manufacturer Code]
    INNER JOIN dbo.[SOPIQ PROD$Manufacturer$ad36f199-c652-4e8e-9c9a-ca851e424760] AS MX ON MX.Code = M.Code
    WHERE IX.Produit = 1
    UNION ALL
    SELECT NULL, IX.[Reference Origine Lié], MX.[ID TechDOC]
    FROM dbo.[SOPIQ PROD$Item$437dbf0e-84ff-417a-965d-ed2bb9650972] AS I
    INNER JOIN dbo.[SOPIQ PROD$Item$ad36f199-c652-4e8e-9c9a-ca851e424760] AS IX ON IX.No_ = I.No_
    INNER JOIN dbo.[SOPIQ PROD$Manufacturer$437dbf0e-84ff-417a-965d-ed2bb9650972] AS M ON M.Code = I.[Manufacturer Code]
    INNER JOIN dbo.[SOPIQ PROD$Manufacturer$ad36f199-c652-4e8e-9c9a-ca851e424760] AS MX ON MX.Code = M.Code
    WHERE IX.Produit NOT IN (0, 1) OR IX.Produit IS NULL
)
SELECT 'Dans la vue, absent de la version coupee' AS Controle, COUNT(*) AS NbLignes
FROM (SELECT * FROM Actuel EXCEPT SELECT * FROM Coupee) AS D
UNION ALL
SELECT 'Dans la version coupee, absent de la vue', COUNT(*)
FROM (SELECT * FROM Coupee EXCEPT SELECT * FROM Actuel) AS D;
GO

/* ---------------------------------------------------------------------
   BLOC 5 : RETOUR ARRIERE, si l'essai ne convainc pas.
   --------------------------------------------------------------------- */
-- DROP INDEX IDX_PERF_Item_VendorItemNo
--     ON dbo.[SOPIQ PROD$Item$437dbf0e-84ff-417a-965d-ed2bb9650972];
-- GO
