-- Index temporaires pour accelerer le renommage des articles.
--
-- Le renommage d'un article fait parcourir a Business Central toutes les tables qui
-- referencent le n d'article. Les tables de lignes validees et archivees n'ont pas
-- d'index sur ce champ : chacune est lue en entier, pour chaque article renomme.
-- Ces index sont ceux remontes par sys.dm_db_missing_index_details.
--
-- Ils sont prefixes IDX_TMP_RENOM_ et peuvent etre supprimes ensuite : passer
-- @Action = 'DROP'. Ils ne font pas partie du modele Business Central, une
-- synchronisation d'extension peut les supprimer, ce n'est pas grave.
--
-- A executer societe par societe, quand aucun traitement ne tourne dessus.
-- La creation prend un verrou exclusif sur chaque table le temps de la construire.

SET NOCOUNT ON;

DECLARE @Action varchar(10) = 'DROP';   -- 'CREATE' ou 'DROP'
DECLARE @base nvarchar(50) = N'437dbf0e-84ff-417a-965d-ed2bb9650972';

IF OBJECT_ID('tempdb..#societes') IS NOT NULL DROP TABLE #societes;
CREATE TABLE #societes (Nom nvarchar(50));
INSERT #societes VALUES ('STE COPIM'), ('STE MPAA PROD'), ('SOPIQ PROD');

IF OBJECT_ID('tempdb..#tables') IS NOT NULL DROP TABLE #tables;
CREATE TABLE #tables (Suffixe nvarchar(80), Colonnes nvarchar(200));
INSERT #tables VALUES
    ('Purchase Line Archive',  '[Type], [No_]'),
    ('Sales Line Archive',     '[Type], [No_]'),
    ('Purch_ Rcpt_ Line',      '[Type], [No_]'),
    ('Purch_ Inv_ Line',       '[Type], [No_]'),
    ('Purch_ Cr_ Memo Line',   '[Type], [No_]'),
    ('Return Shipment Line',   '[Type], [No_]'),
    ('Sales Shipment Line',    '[Type], [No_]'),
    ('Sales Invoice Line',     '[Type], [No_]'),
    ('Sales Cr_Memo Line',     '[Type], [No_]'),
    ('Return Receipt Line',    '[Type], [No_]'),
    ('Sales Line',             '[Type], [No_]'),
    ('Purchase Line',          '[Type], [No_]');

DECLARE @co nvarchar(50), @suf nvarchar(80), @cols nvarchar(200),
        @tbl nvarchar(200), @idx nvarchar(128), @sql nvarchar(max), @debut datetime;

DECLARE c CURSOR LOCAL FAST_FORWARD FOR
    SELECT s.Nom, t.Suffixe, t.Colonnes FROM #societes s CROSS JOIN #tables t;

OPEN c;
FETCH NEXT FROM c INTO @co, @suf, @cols;
WHILE @@FETCH_STATUS = 0
BEGIN
    SET @tbl = @co + '$' + @suf + '$' + @base;
    SET @idx = 'IDX_TMP_RENOM_' + REPLACE(REPLACE(@suf, ' ', '_'), '_', '_');

    IF OBJECT_ID(QUOTENAME(@tbl)) IS NULL
        PRINT 'Table absente, ignoree : ' + @tbl;
    ELSE IF @Action = 'CREATE'
    BEGIN
        IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = @idx AND object_id = OBJECT_ID(QUOTENAME(@tbl)))
            PRINT 'Index deja present : ' + @tbl;
        ELSE
        BEGIN
            SET @debut = GETDATE();
            SET @sql = N'CREATE NONCLUSTERED INDEX ' + QUOTENAME(@idx) + N' ON ' + QUOTENAME(@tbl) + N' (' + @cols + N');';
            EXEC sp_executesql @sql;
            PRINT 'Cree en ' + CAST(DATEDIFF(second, @debut, GETDATE()) AS varchar) + ' s : ' + @tbl;
        END
    END
    ELSE IF @Action = 'DROP'
    BEGIN
        IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = @idx AND object_id = OBJECT_ID(QUOTENAME(@tbl)))
        BEGIN
            SET @sql = N'DROP INDEX ' + QUOTENAME(@idx) + N' ON ' + QUOTENAME(@tbl) + N';';
            EXEC sp_executesql @sql;
            PRINT 'Supprime : ' + @tbl;
        END
    END

    FETCH NEXT FROM c INTO @co, @suf, @cols;
END
CLOSE c;
DEALLOCATE c;

DROP TABLE #societes;
DROP TABLE #tables;
