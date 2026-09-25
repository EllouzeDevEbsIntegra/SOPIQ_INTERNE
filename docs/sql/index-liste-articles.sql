-- Index au service des champs calcules de la liste articles.
--
-- Mesure faite le 25/09/2026 sur la requete de la liste articles de STE COPIM :
-- 1,88 million de pages lues par execution, apres le chantier 2 qui a deja ramene
-- le champ NbJourRupture de 775 925 pages a 2.
--
-- Ce qui reste coute cher, ce sont trois OUTER APPLY dont la colonne de recherche
-- n'est pas en tete d'un index :
--   Last Purch Price Devise -> "Purch_ Rcpt_ Line" (No_, Posting Date)
--   Default Bin             -> "Bin Content" (Item No_)
--   Stockkeeping Unit Exists-> "Stockkeeping Unit" (Item No_)
--
-- Ces index ne font pas partie du modele Business Central : une synchronisation
-- d'extension peut les supprimer, il suffira de relancer ce script.
-- Prefixe IDX_PERF_. Passer @Action = 'DROP' pour les retirer.

SET NOCOUNT ON;

DECLARE @Action varchar(10) = 'CREATE';   -- 'CREATE' ou 'DROP'
DECLARE @base nvarchar(50) = N'437dbf0e-84ff-417a-965d-ed2bb9650972';

IF OBJECT_ID('tempdb..#societes') IS NOT NULL DROP TABLE #societes;
CREATE TABLE #societes (Nom nvarchar(50));
INSERT #societes VALUES ('STE COPIM'), ('SOPIQ PROD'), ('3S AGENCE'), ('STE MPAA PROD');

IF OBJECT_ID('tempdb..#index') IS NOT NULL DROP TABLE #index;
CREATE TABLE #index (Suffixe nvarchar(80), Nom nvarchar(80), Colonnes nvarchar(200), Inclus nvarchar(200));
INSERT #index VALUES
    ('Purch_ Rcpt_ Line',  'IDX_PERF_PurchRcpt_No_Date', '[No_], [Posting Date]', '[Direct Unit Cost], [Quantity]'),
    ('Bin Content',        'IDX_PERF_BinContent_Item',   '[Item No_], [Location Code]', '[Bin Code]'),
    ('Stockkeeping Unit',  'IDX_PERF_SKU_Item',          '[Item No_]', NULL);

DECLARE @co nvarchar(50), @suf nvarchar(80), @idx nvarchar(80), @cols nvarchar(200), @inc nvarchar(200),
        @tbl nvarchar(200), @sql nvarchar(max), @debut datetime, @lignes bigint;

DECLARE c CURSOR LOCAL FAST_FORWARD FOR
    SELECT s.Nom, i.Suffixe, i.Nom, i.Colonnes, i.Inclus FROM #societes s CROSS JOIN #index i;

OPEN c;
FETCH NEXT FROM c INTO @co, @suf, @idx, @cols, @inc;
WHILE @@FETCH_STATUS = 0
BEGIN
    SET @tbl = @co + '$' + @suf + '$' + @base;

    IF OBJECT_ID(QUOTENAME(@tbl)) IS NULL
        PRINT 'Table absente, ignoree : ' + @tbl;
    ELSE IF @Action = 'CREATE'
    BEGIN
        IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = @idx AND object_id = OBJECT_ID(QUOTENAME(@tbl)))
            PRINT 'Deja present : ' + @tbl;
        ELSE
        BEGIN
            SET @debut = GETDATE();
            SET @lignes = (SELECT SUM(p.rows) FROM sys.partitions p
                           WHERE p.object_id = OBJECT_ID(QUOTENAME(@tbl)) AND p.index_id IN (0, 1));
            SET @sql = N'CREATE NONCLUSTERED INDEX ' + QUOTENAME(@idx) + N' ON ' + QUOTENAME(@tbl)
                       + N' (' + @cols + N')'
                       + CASE WHEN @inc IS NULL THEN N'' ELSE N' INCLUDE (' + @inc + N')' END + N';';
            EXEC sp_executesql @sql;
            PRINT 'Cree en ' + CAST(DATEDIFF(second, @debut, GETDATE()) AS varchar) + ' s : '
                  + @tbl + ' (' + CAST(@lignes AS varchar) + ' lignes)';
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

    FETCH NEXT FROM c INTO @co, @suf, @idx, @cols, @inc;
END
CLOSE c;
DEALLOCATE c;

DROP TABLE #societes;
DROP TABLE #index;
