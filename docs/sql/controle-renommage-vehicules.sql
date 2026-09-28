/* =====================================================================
   Lecture du journal et controle du renommage des versions de modele.

   A utiliser apres chaque passage du codeunit 50034, en simulation comme
   en reel, sur DEV puis sur la production.

   Changer la base a la premiere ligne :
       SOPIQ_DEV        pour la repetition
       SOPIQ_PROD_BC16  pour la production

   Ce script ne fait que LIRE.
   ===================================================================== */

USE SOPIQ_DEV;
GO

SET NOCOUNT ON;

DECLARE @journal nvarchar(300) = N'3S AGENCE$Log Renommage Refs$fe610c13-6229-4f65-9f57-05b0ea985881';
DECLARE @article nvarchar(300) = N'3S AGENCE$Item$437dbf0e-84ff-417a-965d-ed2bb9650972';
DECLARE @sql nvarchar(max);

/* --- 1. Les passages enregistres ------------------------------------- */
/*     Statut : 0 Renomme, 1 Collision, 2 Simule.                        */
SET @sql = N'
SELECT [Execution] AS Passage,
       CASE [Statut] WHEN 0 THEN ''Renomme'' WHEN 1 THEN ''Collision''
                     WHEN 2 THEN ''Simule'' END AS Statut,
       [Simulation],
       COUNT(*) AS NbLignes,
       MIN([Date Heure]) AS Debut,
       MAX([Date Heure]) AS Fin
FROM ' + QUOTENAME(@journal) + N'
GROUP BY [Execution], [Statut], [Simulation]
ORDER BY [Execution] DESC, [Statut];';
EXEC sys.sp_executesql @sql;

/* --- 2. Un echantillon du dernier passage ---------------------------- */
SET @sql = N'
SELECT TOP 20 [Ancien No_] AS AncienNo, [Nouveau No_] AS NouveauNo,
       CASE [Statut] WHEN 0 THEN ''Renomme'' WHEN 1 THEN ''Collision''
                     WHEN 2 THEN ''Simule'' END AS Statut,
       [Date Heure] AS Horodatage
FROM ' + QUOTENAME(@journal) + N'
WHERE [Execution] = (SELECT MAX([Execution]) FROM ' + QUOTENAME(@journal) + N')
ORDER BY [Ancien No_];';
EXEC sys.sp_executesql @sql;

/* --- 3. Les collisions, s'il y en a ---------------------------------- */
SET @sql = N'
SELECT [Ancien No_] AS AncienNo, [Nouveau No_] AS NouveauNoDejaPris, [Date Heure] AS Horodatage
FROM ' + QUOTENAME(@journal) + N'
WHERE [Statut] = 1
ORDER BY [Date Heure] DESC;';
EXEC sys.sp_executesql @sql;

/* --- 4. Apres le renommage reel : reste-t-il des candidats ? --------- */
/*     Doit renvoyer zero. Toute fiche restante n'a pas ete traitee.     */
SET @sql = N'
SELECT COUNT(*) AS NbFichesEncoreEnSixChiffres
FROM ' + QUOTENAME(@article) + N'
WHERE [Item Type] = 2
  AND [Make Code] LIKE ''%MERCEDES%''
  AND LEN([No_]) = 6
  AND [No_] NOT LIKE ''%[^0-9]%'';';
EXEC sys.sp_executesql @sql;

/* --- 5. Le champ N 2 suit-il le nouveau numero ? --------------------- */
/*     Doit renvoyer zero : aucune fiche pointee ne doit garder un N 2
       different de son propre numero.                                    */
SET @sql = N'
SELECT COUNT(*) AS NbFichesDontLeNo2NeSuitPas
FROM ' + QUOTENAME(@article) + N'
WHERE [Item Type] = 2
  AND [Make Code] LIKE ''%MERCEDES%''
  AND [No_] LIKE ''[0-9][0-9][0-9].[0-9][0-9][0-9]''
  AND [No_ 2] <> '''' AND [No_ 2] <> [No_];';
EXEC sys.sp_executesql @sql;

/* --- 6. Un apercu des fiches renommees ------------------------------- */
SET @sql = N'
SELECT TOP 20 [No_] AS Numero, [No_ 2] AS No2, [Description], [Make Code] AS Marque
FROM ' + QUOTENAME(@article) + N'
WHERE [Item Type] = 2
  AND [No_] LIKE ''[0-9][0-9][0-9].[0-9][0-9][0-9]''
ORDER BY [No_];';
EXEC sys.sp_executesql @sql;
GO
