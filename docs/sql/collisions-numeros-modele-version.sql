/* =====================================================================
   Combien de numeros designent un vehicule dans une societe et une piece
   dans une autre.

   Contexte du 28/09/2026 : la reference 204002 vaut "Vanne EGR" dans
   SOPIQ PROD et "C 220 CDI" dans 3S AGENCE, ou elle est une version de
   modele de vehicule ("Item Type" = 2). Le traitement des Item Master
   allait recopier la piece sur le vehicule.

   Le correctif de la version 1.0.8.0 empeche l'ecrasement, mais il ne
   cree pas la piece dans la societe ou le numero est deja pris : c'est
   impossible, un numero d'article est unique par societe. Il faut donc
   savoir combien de numeros sont dans ce cas avant de decider quoi faire.

   Valeurs du champ "Item Type" : 0 vide, 1 Article, 2 Modele Version.

   Ce script ne fait que LIRE. Il ne modifie rien.
   ===================================================================== */

USE SOPIQ_PROD_BC16;
GO

SET NOCOUNT ON;

DECLARE @base nvarchar(50) = N'437dbf0e-84ff-417a-965d-ed2bb9650972';
DECLARE @sql nvarchar(max) = N'';

IF OBJECT_ID('tempdb..#societes') IS NOT NULL DROP TABLE #societes;
CREATE TABLE #societes (Nom nvarchar(50));
INSERT #societes VALUES ('SOPIQ PROD'), ('STE COPIM'), ('3S AGENCE'), ('STE MPAA PROD');

IF OBJECT_ID('tempdb..#articles') IS NOT NULL DROP TABLE #articles;
CREATE TABLE #articles (
    Societe nvarchar(50),
    No_ nvarchar(20),
    Description nvarchar(100),
    TypeArticle int
);

/* --- Rassembler les articles des quatre societes --------------------- */
SELECT @sql = @sql + N'
INSERT #articles (Societe, No_, Description, TypeArticle)
SELECT ' + QUOTENAME(s.Nom, '''') + N', I.[No_], I.[Description], I.[Item Type]
FROM ' + QUOTENAME(s.Nom + '$Item$' + @base) + N' AS I;'
FROM #societes AS s
WHERE OBJECT_ID(QUOTENAME(s.Nom + '$Item$' + @base)) IS NOT NULL;

EXEC sys.sp_executesql @sql;

/* --- 1. Combien de versions de modele, et ou ? ----------------------- */
SELECT Societe,
       SUM(CASE WHEN TypeArticle = 2 THEN 1 ELSE 0 END) AS NbVersionsDeModele,
       SUM(CASE WHEN TypeArticle <> 2 THEN 1 ELSE 0 END) AS NbArticles
FROM #articles
GROUP BY Societe
ORDER BY Societe;

/* --- 2. Les numeros en collision ------------------------------------- */
/*     Un meme numero, version de modele quelque part, article ailleurs.  */
SELECT COUNT(*) AS NbNumerosEnCollision
FROM (
    SELECT No_
    FROM #articles
    GROUP BY No_
    HAVING SUM(CASE WHEN TypeArticle = 2 THEN 1 ELSE 0 END) > 0
       AND SUM(CASE WHEN TypeArticle <> 2 THEN 1 ELSE 0 END) > 0
) AS C;

/* --- 3. Le detail, cent premiers ------------------------------------- */
SELECT TOP 100
    A.No_ AS Numero,
    MAX(CASE WHEN A.TypeArticle = 2 THEN A.Societe END) AS SocieteVehicule,
    MAX(CASE WHEN A.TypeArticle = 2 THEN A.Description END) AS LibelleVehicule,
    MAX(CASE WHEN A.TypeArticle <> 2 THEN A.Societe END) AS SocietePiece,
    MAX(CASE WHEN A.TypeArticle <> 2 THEN A.Description END) AS LibellePiece
FROM #articles AS A
WHERE A.No_ IN (
    SELECT No_
    FROM #articles
    GROUP BY No_
    HAVING SUM(CASE WHEN TypeArticle = 2 THEN 1 ELSE 0 END) > 0
       AND SUM(CASE WHEN TypeArticle <> 2 THEN 1 ELSE 0 END) > 0
)
GROUP BY A.No_
ORDER BY A.No_;

/* --- 4. Celles qui attendent dans la liste des Item Master ----------- */
/*     Ce sont celles qui poseront probleme au prochain traitement.       */
IF OBJECT_ID(QUOTENAME('items Master$fe610c13-6229-4f65-9f57-05b0ea985881')) IS NOT NULL
    SELECT M.[No] AS Numero,
           M.[Company] AS SocieteOrigine,
           M.[Verified] AS DejaValide,
           A.Societe AS SocieteOuLeNumeroEstUnVehicule,
           A.Description AS LibelleVehicule
    FROM [items Master$fe610c13-6229-4f65-9f57-05b0ea985881] AS M
    JOIN #articles AS A ON A.No_ = M.[No] AND A.TypeArticle = 2
    ORDER BY M.[Verified], M.[No];
ELSE
    SELECT 'Table items Master introuvable sous ce nom' AS Resultat;
GO
