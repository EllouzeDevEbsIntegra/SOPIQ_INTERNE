/* =====================================================================
   Avoirs non soldes portant un timbre fiscal, en PRODUCTION.

   Un avoir ne porte pas de timbre fiscal : ceux qui en portent un sont des
   erreurs de saisie, et tant que le timbre y figure ils ne peuvent pas se
   solder. Ce recensement a ete demande par l'equipe de developpement le
   28/09/2026 avant de decider quoi en faire. Aucune donnee n'est corrigee
   ici.

   Les trois morceaux d'un avoir vivent dans trois tables :
     - le document, application de base ;
     - "solde", extension SOPIQ INTERNE ;
     - "STStamp Amount", extension StandardTunisien.

   Ecrit sans CROSS APPLY : une premiere version en utilisait un et comptait
   quatre fois les memes lignes. Ici, un sous-select par nombre, rien
   d'autre, et chaque table est nommee avec sa base devant : le script ne
   peut pas se tromper de base.

   Ce script ne fait que LIRE.
   ===================================================================== */

SET NOCOUNT ON;

DECLARE @base nvarchar(50) = N'437dbf0e-84ff-417a-965d-ed2bb9650972';
DECLARE @interne nvarchar(50) = N'fe610c13-6229-4f65-9f57-05b0ea985881';
DECLARE @st nvarchar(50) = N'840d69c1-a2ae-4b41-bfb1-4b23af2cf237';
DECLARE @bd nvarchar(50) = N'SOPIQ_PROD_BC16';   -- mettre SOPIQ_DEV pour comparer
DECLARE @sql nvarchar(max) = N'';

IF OBJECT_ID('tempdb..#societes') IS NOT NULL DROP TABLE #societes;
CREATE TABLE #societes (Nom nvarchar(50) COLLATE DATABASE_DEFAULT);
INSERT #societes VALUES ('SOPIQ PROD'), ('STE COPIM'), ('3S AGENCE'), ('STE MPAA PROD');

SELECT @sql = @sql + N'
SELECT ' + QUOTENAME(s.Nom, '''') + N' AS Societe,
       COUNT(*) AS AvoirsNonSoldes,
       SUM(CASE WHEN ISNULL(T.[STStamp Amount], 0) <> 0 THEN 1 ELSE 0 END) AS DontAvecTimbre,
       SUM(ISNULL(T.[STStamp Amount], 0)) AS TotalTimbres,
       SUM(CASE WHEN EXISTS (SELECT 1
                             FROM ' + QUOTENAME(@bd) + N'.dbo.' + QUOTENAME(s.Nom + '$Recu Caisse Document$' + @interne) + N' AS D
                             WHERE D.[Document No] COLLATE DATABASE_DEFAULT = A.[No_] COLLATE DATABASE_DEFAULT)
                THEN 1 ELSE 0 END) AS DontVusEnCaisse,
       MIN(CASE WHEN ISNULL(T.[STStamp Amount], 0) <> 0 THEN A.[Posting Date] END) AS PlusAncienTimbre,
       MAX(CASE WHEN ISNULL(T.[STStamp Amount], 0) <> 0 THEN A.[Posting Date] END) AS PlusRecentTimbre
FROM ' + QUOTENAME(@bd) + N'.dbo.' + QUOTENAME(s.Nom + '$Sales Cr_Memo Header$' + @base) + N' AS A
JOIN ' + QUOTENAME(@bd) + N'.dbo.' + QUOTENAME(s.Nom + '$Sales Cr_Memo Header$' + @interne) + N' AS I
    ON I.[No_] = A.[No_]
LEFT JOIN ' + QUOTENAME(@bd) + N'.dbo.' + QUOTENAME(s.Nom + '$Sales Cr_Memo Header$' + @st) + N' AS T
    ON T.[No_] = A.[No_]
WHERE I.[solde] = 0
UNION ALL'
FROM #societes AS s;

SET @sql = LEFT(@sql, LEN(@sql) - LEN('UNION ALL')) + N' ORDER BY Societe;';
EXEC sys.sp_executesql @sql;
GO
