-- Index temporaires, deuxieme jeu : les champs qui referencent un article autrement
-- que par le champ "No.".
--
-- Mesure faite pendant le renommage (sys.dm_exec_query_stats) : la cascade de
-- Business Central filtre sur ces colonnes, aucune n'est indexee, chaque appel lit
-- donc la table entiere. "Alternative Item No." coute a lui seul plus d'une seconde
-- par appel sur la table Item.
--
-- Le script cherche lui-meme, dans chaque societe, les tables qui portent ces
-- colonnes, y compris les tables d'extension, et n'indexe que celles de plus de
-- 5 000 lignes.
--
-- Index prefixes IDX_TMP_RENOM2_. Passer @Action = 'DROP' pour les retirer.
-- A executer quand aucun renommage ne tourne : la creation prend un verrou exclusif.

SET NOCOUNT ON;

DECLARE @Action varchar(10) = 'CREATE';   -- 'CREATE' ou 'DROP'

IF OBJECT_ID('tempdb..#societes') IS NOT NULL DROP TABLE #societes;
CREATE TABLE #societes (Nom nvarchar(50));
INSERT #societes VALUES ('STE COPIM'), ('STE MPAA PROD'), ('SOPIQ PROD');

IF OBJECT_ID('tempdb..#colonnes') IS NOT NULL DROP TABLE #colonnes;
CREATE TABLE #colonnes (Colonne nvarchar(128));
INSERT #colonnes VALUES
    ('Alternative Item No_'),
    ('Item Replacement No_'),
    ('BOM Item No_'),
    ('Originally Ordered No_'),
    ('Order Line Type No_'),
    ('Rent Item No_'),
    ('Item No_ for Print');

IF OBJECT_ID('tempdb..#cibles') IS NOT NULL DROP TABLE #cibles;
SELECT o.object_id, o.name AS Table_, c.Colonne,
       (SELECT SUM(p.rows) FROM sys.partitions p WHERE p.object_id = o.object_id AND p.index_id IN (0, 1)) AS Lignes
INTO #cibles
FROM sys.objects o
JOIN sys.columns col ON col.object_id = o.object_id
JOIN #colonnes c ON c.Colonne = col.name
JOIN #societes s ON o.name LIKE s.Nom + '$%'
WHERE o.type = 'U';

DELETE FROM #cibles WHERE Lignes < 5000;

DECLARE @tbl nvarchar(300), @col nvarchar(128), @idx nvarchar(128),
        @sql nvarchar(max), @debut datetime, @lignes bigint;

DECLARE c CURSOR LOCAL FAST_FORWARD FOR
    SELECT Table_, Colonne, Lignes FROM #cibles ORDER BY Lignes DESC;

OPEN c;
FETCH NEXT FROM c INTO @tbl, @col, @lignes;
WHILE @@FETCH_STATUS = 0
BEGIN
    SET @idx = 'IDX_TMP_RENOM2_' + REPLACE(@col, ' ', '_');

    IF @Action = 'CREATE'
    BEGIN
        IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = @idx AND object_id = OBJECT_ID(QUOTENAME(@tbl)))
            PRINT 'Deja present : ' + @tbl + ' (' + @col + ')';
        ELSE
        BEGIN
            SET @debut = GETDATE();
            SET @sql = N'CREATE NONCLUSTERED INDEX ' + QUOTENAME(@idx) + N' ON ' + QUOTENAME(@tbl) + N' (' + QUOTENAME(@col) + N');';
            EXEC sp_executesql @sql;
            PRINT 'Cree en ' + CAST(DATEDIFF(second, @debut, GETDATE()) AS varchar) + ' s : '
                  + @tbl + ' (' + @col + ', ' + CAST(@lignes AS varchar) + ' lignes)';
        END
    END
    ELSE IF @Action = 'DROP'
    BEGIN
        IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = @idx AND object_id = OBJECT_ID(QUOTENAME(@tbl)))
        BEGIN
            SET @sql = N'DROP INDEX ' + QUOTENAME(@idx) + N' ON ' + QUOTENAME(@tbl) + N';';
            EXEC sp_executesql @sql;
            PRINT 'Supprime : ' + @tbl + ' (' + @col + ')';
        END
    END

    FETCH NEXT FROM c INTO @tbl, @col, @lignes;
END
CLOSE c;
DEALLOCATE c;

DROP TABLE #societes;
DROP TABLE #colonnes;
DROP TABLE #cibles;
