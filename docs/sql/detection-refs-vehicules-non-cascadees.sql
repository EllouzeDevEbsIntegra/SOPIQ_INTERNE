/* =====================================================================
   Avant de renommer : qui d'autre porte ces 850 numeros dans 3S AGENCE ?

   Business Central ne repercute un renommage que sur les tables dont la
   colonne porte une relation vers l'article. Les tables alimentees en SQL
   direct, ou dont le champ n'a pas de TableRelation, gardent l'ancien
   numero, sans le moindre message. C'est ce qui a coute deux jours en
   septembre sur le renommage des references fabricants.

   Ce script balaye toutes les colonnes de la societe 3S AGENCE qui
   portent un numero d'article, et compte celles qui contiennent un des
   850 numeros a renommer. Il ne suffit pas de regarder
   "Specific Item Ledger Entry" : on veut la liste complete.

   Il verifie aussi que cette table n'est pas simplement vide, car un zero
   peut vouloir dire deux choses tres differentes.

   Ce script ne fait que LIRE. Il ne renomme ni ne modifie rien.
   ===================================================================== */

USE SOPIQ_PROD_BC16;
GO

SET NOCOUNT ON;
GO

/* --- Les 850 numeros vises ------------------------------------------- */
IF OBJECT_ID('tempdb..#cibles') IS NOT NULL DROP TABLE #cibles;

SELECT [No_] COLLATE DATABASE_DEFAULT AS AncienNo,
       LEFT([No_], 3) + '.' + SUBSTRING([No_], 4, 3) COLLATE DATABASE_DEFAULT AS NouveauNo
INTO #cibles
FROM [3S AGENCE$Item$437dbf0e-84ff-417a-965d-ed2bb9650972]
WHERE [Item Type] = 2
  AND [Make Code] LIKE '%MERCEDES%'
  AND LEN([No_]) = 6
  AND [No_] NOT LIKE '%[^0-9]%';

CREATE CLUSTERED INDEX IX_cibles ON #cibles (AncienNo);
GO

/* --- Le zero de tout a l'heure : table vide, ou vraiment sans lien ? -- */
SELECT COUNT(*) AS NbLignesTotalSpecificILE3S,
       COUNT(DISTINCT [Item No_]) AS NbArticlesDistincts
FROM [3S AGENCE$Specific Item Ledger Entry$fe610c13-6229-4f65-9f57-05b0ea985881];

SELECT TOP 10 [Item No_] AS ArticleVu, COUNT(*) AS NbEcritures
FROM [3S AGENCE$Specific Item Ledger Entry$fe610c13-6229-4f65-9f57-05b0ea985881]
GROUP BY [Item No_]
ORDER BY COUNT(*) DESC;
GO

/* --- Le balayage ----------------------------------------------------- */
SET NOCOUNT ON;

IF OBJECT_ID('tempdb..#resultat') IS NOT NULL DROP TABLE #resultat;
CREATE TABLE #resultat (
    Table_ nvarchar(300) COLLATE DATABASE_DEFAULT,
    Colonne nvarchar(128) COLLATE DATABASE_DEFAULT,
    NbLignesConcernees int
);

DECLARE @tbl nvarchar(300), @col nvarchar(128), @sql nvarchar(max);

DECLARE cCol CURSOR LOCAL FAST_FORWARD FOR
    SELECT o.name, c.name
    FROM sys.objects AS o
    JOIN sys.columns AS c ON c.object_id = o.object_id
    JOIN sys.types AS ty ON ty.user_type_id = c.user_type_id
    WHERE o.type = 'U'
      AND o.name COLLATE DATABASE_DEFAULT LIKE '3S AGENCE$%'
      AND ty.name IN ('nvarchar', 'varchar', 'nchar', 'char')
      AND (c.name COLLATE DATABASE_DEFAULT LIKE '%Item No#_%' ESCAPE '#'
           OR c.name COLLATE DATABASE_DEFAULT IN (N'Article', N'Item', N'No_ 2',
                                                  N'Parent Item No_', N'Substitute No_'))
    ORDER BY o.name, c.name;

OPEN cCol;
FETCH NEXT FROM cCol INTO @tbl, @col;
WHILE @@FETCH_STATUS = 0
BEGIN
    SET @sql = N'
        INSERT #resultat (Table_, Colonne, NbLignesConcernees)
        SELECT @tbl, @col, COUNT(*)
        FROM ' + QUOTENAME(@tbl) + N' AS t
        JOIN #cibles AS c
          ON c.AncienNo = t.' + QUOTENAME(@col) + N' COLLATE DATABASE_DEFAULT;';

    BEGIN TRY
        EXEC sys.sp_executesql @sql,
             N'@tbl nvarchar(300), @col nvarchar(128)',
             @tbl = @tbl, @col = @col;
    END TRY
    BEGIN CATCH
        INSERT #resultat VALUES (@tbl, @col, -1);   -- -1 : colonne illisible, a regarder
    END CATCH

    FETCH NEXT FROM cCol INTO @tbl, @col;
END

CLOSE cCol;
DEALLOCATE cCol;

/* --- Ce qui contient vraiment un de ces numeros ---------------------- */
SELECT Table_, Colonne, NbLignesConcernees
FROM #resultat
WHERE NbLignesConcernees <> 0
ORDER BY NbLignesConcernees DESC, Table_;

SELECT COUNT(*) AS NbColonnesBalayees,
       SUM(CASE WHEN NbLignesConcernees > 0 THEN 1 ELSE 0 END) AS NbColonnesConcernees
FROM #resultat;
GO
