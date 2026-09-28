/* =====================================================================
   Le point est-il libre comme separateur des numeros de version de
   modele ?

   Proposition du 28/09/2026 : renommer les versions de modele de
   3S AGENCE en intercalant un point, 204002 devient 204.002, 177051
   devient 177.051. Objectif : qu'un numero de vehicule ne puisse plus
   jamais tomber sur un numero de piece.

   Avant de renommer, il faut verifier trois choses :
     - qu'aucun article ne porte deja la forme pointee visee ;
     - que le point n'est pas deja employe dans les numeros d'article,
       auquel cas la convention ne distinguerait rien ;
     - quelles lignes suivront le renommage, et lesquelles ne le
       suivront pas.

   Ce script ne fait que LIRE. Il ne renomme rien.
   ===================================================================== */

USE SOPIQ_PROD_BC16;
GO

SET NOCOUNT ON;

DECLARE @base nvarchar(50) = N'437dbf0e-84ff-417a-965d-ed2bb9650972';
DECLARE @sql nvarchar(max) = N'';

IF OBJECT_ID('tempdb..#societes') IS NOT NULL DROP TABLE #societes;
CREATE TABLE #societes (Nom nvarchar(50) COLLATE DATABASE_DEFAULT);
INSERT #societes VALUES ('SOPIQ PROD'), ('STE COPIM'), ('3S AGENCE'), ('STE MPAA PROD');

IF OBJECT_ID('tempdb..#articles') IS NOT NULL DROP TABLE #articles;
CREATE TABLE #articles (
    Societe nvarchar(50) COLLATE DATABASE_DEFAULT,
    No_ nvarchar(20) COLLATE DATABASE_DEFAULT,
    Description nvarchar(100) COLLATE DATABASE_DEFAULT,
    TypeArticle int
);

SELECT @sql = @sql + N'
INSERT #articles (Societe, No_, Description, TypeArticle)
SELECT ' + QUOTENAME(s.Nom, '''') + N' COLLATE DATABASE_DEFAULT,
       I.[No_] COLLATE DATABASE_DEFAULT,
       I.[Description] COLLATE DATABASE_DEFAULT,
       I.[Item Type]
FROM ' + QUOTENAME(s.Nom + '$Item$' + @base) + N' AS I;'
FROM #societes AS s
WHERE OBJECT_ID(QUOTENAME(s.Nom + '$Item$' + @base)) IS NOT NULL;

EXEC sys.sp_executesql @sql;

/* --- 1. Le point est-il deja utilise dans les numeros d'article ? ---- */
SELECT Societe,
       COUNT(*) AS NbNumerosContenantUnPoint
FROM #articles
WHERE No_ LIKE '%.%'
GROUP BY Societe
ORDER BY Societe;

/* --- 2. Des exemples, s'il y en a ------------------------------------ */
SELECT TOP 30 Societe, No_, Description,
       CASE TypeArticle WHEN 2 THEN 'Version de modele' ELSE 'Article' END AS Type_
FROM #articles
WHERE No_ LIKE '%.%'
ORDER BY Societe, No_;

/* --- 3. La forme pointee visee est-elle libre ? ---------------------- */
/*     Pour chaque version de modele de 3S AGENCE dont le numero fait six
       chiffres, on calcule la forme pointee et on regarde si quelqu'un la
       porte deja, dans n'importe quelle societe.                         */
WITH Vehicules AS (
    SELECT No_,
           Description,
           LEFT(No_, 3) + '.' + SUBSTRING(No_, 4, 3) AS NouveauNo
    FROM #articles
    WHERE Societe = '3S AGENCE'
      AND TypeArticle = 2
      AND LEN(No_) = 6
      AND No_ NOT LIKE '%[^0-9]%'
)
SELECT COUNT(*) AS NbVehiculesRenommables,
       SUM(CASE WHEN EXISTS (SELECT 1 FROM #articles AS A
                             WHERE A.No_ = V.NouveauNo) THEN 1 ELSE 0 END) AS NbFormesPointeesDejaPrises
FROM Vehicules AS V;

/* --- 4. Le detail des formes pointees deja prises, s'il y en a ------- */
WITH Vehicules AS (
    SELECT No_,
           Description,
           LEFT(No_, 3) + '.' + SUBSTRING(No_, 4, 3) AS NouveauNo
    FROM #articles
    WHERE Societe = '3S AGENCE'
      AND TypeArticle = 2
      AND LEN(No_) = 6
      AND No_ NOT LIKE '%[^0-9]%'
)
SELECT V.No_ AS AncienNo, V.Description AS Vehicule,
       V.NouveauNo, A.Societe AS DejaPortePar, A.Description AS LibelleExistant
FROM Vehicules AS V
JOIN #articles AS A ON A.No_ = V.NouveauNo
ORDER BY V.No_;

/* --- 5. Les vehicules qui ne rentrent pas dans la regle -------------- */
/*     Numero non numerique ou pas de six chiffres : DS7, A200, GOLF 6,
       T-CROSS... La convention ne peut pas s'y appliquer telle quelle.   */
SELECT COUNT(*) AS NbVehiculesHorsRegle
FROM #articles
WHERE Societe = '3S AGENCE'
  AND TypeArticle = 2
  AND (LEN(No_) <> 6 OR No_ LIKE '%[^0-9]%');

SELECT TOP 30 No_, Description
FROM #articles
WHERE Societe = '3S AGENCE'
  AND TypeArticle = 2
  AND (LEN(No_) <> 6 OR No_ LIKE '%[^0-9]%')
ORDER BY No_;
GO
