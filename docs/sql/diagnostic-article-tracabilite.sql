/* =====================================================================
   Pourquoi le traitement des Item Master reclame un code tracabilite.

   Message rencontre le 28/09/2026 :
     "Code tracabilite doit avoir une valeur dans Article: N°=204002."

   "Code tracabilite" est la traduction francaise du champ standard
   "Item Tracking Code" de la fiche article. Notre code ne le teste
   jamais : le controle vient de Business Central, et il ne se declenche
   que dans trois cas, tous portes par la table Article standard :

     - "Costing Method" vaut Specific (valeur 2) et le code tracabilite
       est vide ;
     - on renseigne "Serial Nos." alors que le code tracabilite est vide ;
     - on vide le code tracabilite alors que la methode est Specific.

   Le traitement recopie la fiche de la societe de base vers les autres.
   Ce script montre, societe par societe, l'etat des champs concernes,
   pour voir laquelle cloche.

   Ce script ne fait que LIRE. Il ne modifie rien.
   ===================================================================== */

USE SOPIQ_PROD_BC16;
GO

SET NOCOUNT ON;

DECLARE @Article nvarchar(20) = N'204002';   -- le numero signale par l'erreur
DECLARE @base nvarchar(50) = N'437dbf0e-84ff-417a-965d-ed2bb9650972';
DECLARE @sql nvarchar(max) = N'';

IF OBJECT_ID('tempdb..#societes') IS NOT NULL DROP TABLE #societes;
CREATE TABLE #societes (Nom nvarchar(50));
INSERT #societes VALUES ('SOPIQ PROD'), ('STE COPIM'), ('3S AGENCE'), ('STE MPAA PROD');

/* --- 1. L'article, societe par societe ------------------------------- */
SELECT @sql = @sql + N'
SELECT ' + QUOTENAME(s.Nom, '''') + N' AS Societe,
       I.[No_]                    AS Article,
       I.[Description],
       CASE I.[Costing Method] WHEN 0 THEN ''FIFO'' WHEN 1 THEN ''LIFO''
            WHEN 2 THEN ''Specifique'' WHEN 3 THEN ''Moyen'' WHEN 4 THEN ''Standard''
            ELSE CAST(I.[Costing Method] AS varchar) END AS MethodeValorisation,
       I.[Item Tracking Code]     AS CodeTracabilite,
       I.[Item Category Code]     AS CategorieArticle,
       I.[Serial Nos_]            AS SoucheNoSerie,
       I.[Lot Nos_]               AS SoucheNoLot,
       CASE I.[Type] WHEN 0 THEN ''Stock'' WHEN 1 THEN ''Service''
            WHEN 2 THEN ''Hors stock'' ELSE CAST(I.[Type] AS varchar) END AS TypeArticle
FROM ' + QUOTENAME(s.Nom + '$Item$' + @base) + N' AS I
WHERE I.[No_] = @Article
UNION ALL'
FROM #societes AS s
WHERE OBJECT_ID(QUOTENAME(s.Nom + '$Item$' + @base)) IS NOT NULL;

IF LEN(@sql) > 0
BEGIN
    SET @sql = LEFT(@sql, LEN(@sql) - LEN('UNION ALL')) + N' ORDER BY Societe;';
    EXEC sys.sp_executesql @sql, N'@Article nvarchar(20)', @Article = @Article;
END
ELSE
    SELECT 'Aucune table article trouvee' AS Resultat;

/* --- 2. La categorie de l'article porte-t-elle un code tracabilite ? -- */
/*     Utile si la recopie passe par la categorie.                       */
SET @sql = N'';

SELECT @sql = @sql + N'
SELECT ' + QUOTENAME(s.Nom, '''') + N' AS Societe,
       C.[Code]                AS Categorie,
       C.[Description],
       C.[Item Tracking Code]  AS CodeTracabiliteCategorie
FROM ' + QUOTENAME(s.Nom + '$Item Category$' + @base) + N' AS C
WHERE C.[Code] IN (SELECT I.[Item Category Code]
                   FROM ' + QUOTENAME(s.Nom + '$Item$' + @base) + N' AS I
                   WHERE I.[No_] = @Article)
UNION ALL'
FROM #societes AS s
WHERE OBJECT_ID(QUOTENAME(s.Nom + '$Item Category$' + @base)) IS NOT NULL
  AND OBJECT_ID(QUOTENAME(s.Nom + '$Item$' + @base)) IS NOT NULL;

IF LEN(@sql) > 0
BEGIN
    SET @sql = LEFT(@sql, LEN(@sql) - LEN('UNION ALL')) + N' ORDER BY Societe;';
    EXEC sys.sp_executesql @sql, N'@Article nvarchar(20)', @Article = @Article;
END

/* --- 3. Combien d'articles sont dans le meme cas ? ------------------- */
/*     Methode Specifique et code tracabilite vide : ceux-la feront
       echouer le traitement de la meme facon.                           */
SET @sql = N'';

SELECT @sql = @sql + N'
SELECT ' + QUOTENAME(s.Nom, '''') + N' AS Societe,
       COUNT(*) AS NbArticlesSpecifiqueSansTracabilite
FROM ' + QUOTENAME(s.Nom + '$Item$' + @base) + N' AS I
WHERE I.[Costing Method] = 2 AND ISNULL(I.[Item Tracking Code], '''') = ''''
UNION ALL'
FROM #societes AS s
WHERE OBJECT_ID(QUOTENAME(s.Nom + '$Item$' + @base)) IS NOT NULL;

IF LEN(@sql) > 0
BEGIN
    SET @sql = LEFT(@sql, LEN(@sql) - LEN('UNION ALL')) + N' ORDER BY Societe;';
    EXEC sys.sp_executesql @sql;
END
GO
