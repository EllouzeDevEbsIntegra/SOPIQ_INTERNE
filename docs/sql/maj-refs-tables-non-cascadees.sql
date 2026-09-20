-- Mise a jour des n d'article dans les tables que le renommage n'a pas touchees.
--
-- Business Central ne repercute un renommage que sur les tables dont le champ porte
-- une relation vers Item. Les tables maison alimentees en SQL direct, comme
-- "Specific Item Ledger Entry", gardent l'ancien numero.
--
-- @Action = 'DETECT' : ne fait que compter, table par table, les lignes restees sur un
--                      ancien numero. A lancer en premier.
-- @Action = 'UPDATE' : applique la correction, uniquement aux tables listees dans
--                      #aTraiter. Chaque table est traitee dans sa propre instruction.
--
-- La correspondance ancien / nouveau vient du journal 50024, statut Renomme.
-- Collation : COLLATE DATABASE_DEFAULT des deux cotes de chaque comparaison de texte.

SET NOCOUNT ON;

DECLARE @Action varchar(10) = 'DETECT';   -- 'DETECT' ou 'UPDATE'
DECLARE @app nvarchar(50) = N'fe610c13-6229-4f65-9f57-05b0ea985881';  -- SOPIQ INTERNE

-- Tables effectivement mises a jour quand @Action = 'UPDATE'.
-- Le repere est le nom sans prefixe societe ni suffixe application.
IF OBJECT_ID('tempdb..#aTraiter') IS NOT NULL DROP TABLE #aTraiter;
CREATE TABLE #aTraiter (Nom nvarchar(200));
INSERT #aTraiter VALUES ('Specific Item Ledger Entry');

IF OBJECT_ID('tempdb..#resultat') IS NOT NULL DROP TABLE #resultat;
CREATE TABLE #resultat (Societe nvarchar(50), Table_ nvarchar(300), Colonne nvarchar(128), Lignes int, Action_ varchar(20));

DECLARE @co nvarchar(50), @journal nvarchar(300), @tbl nvarchar(300), @col nvarchar(128),
        @sql nvarchar(max), @traiter bit;

DECLARE cSoc CURSOR LOCAL FAST_FORWARD FOR
    SELECT LEFT(name, CHARINDEX('$Log Renommage Refs$', name) - 1)
    FROM sys.tables
    WHERE name LIKE '%$Log Renommage Refs$' + @app;

OPEN cSoc;
FETCH NEXT FROM cSoc INTO @co;
WHILE @@FETCH_STATUS = 0
BEGIN
    SET @journal = @co + '$Log Renommage Refs$' + @app;

    -- Toutes les tables de cette societe qui portent une colonne de n d'article
    DECLARE cTbl CURSOR LOCAL FAST_FORWARD FOR
        SELECT o.name, c.name
        FROM sys.objects o
        JOIN sys.columns c ON c.object_id = o.object_id
        WHERE o.type = 'U'
          AND o.name COLLATE DATABASE_DEFAULT LIKE @co COLLATE DATABASE_DEFAULT + '$%'
          AND c.name COLLATE DATABASE_DEFAULT IN (N'Item No_' COLLATE DATABASE_DEFAULT,
                                                  N'Article' COLLATE DATABASE_DEFAULT)
          AND o.name COLLATE DATABASE_DEFAULT NOT LIKE '%$Log Renommage Refs$%';

    OPEN cTbl;
    FETCH NEXT FROM cTbl INTO @tbl, @col;
    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @traiter = CASE WHEN EXISTS (
                SELECT 1 FROM #aTraiter a
                WHERE @tbl COLLATE DATABASE_DEFAULT LIKE '%$' + a.Nom COLLATE DATABASE_DEFAULT + '$%')
            THEN 1 ELSE 0 END;

        -- Comptage, toujours
        SET @sql = N'
            INSERT #resultat
            SELECT @co, @tbl, @col, COUNT(*), @act
            FROM ' + QUOTENAME(@tbl) + N' t
            JOIN ' + QUOTENAME(@journal) + N' l
              ON l.[Ancien No_] COLLATE DATABASE_DEFAULT = t.' + QUOTENAME(@col) + N' COLLATE DATABASE_DEFAULT
            WHERE l.[Statut] = 0;';
        EXEC sp_executesql @sql,
             N'@co nvarchar(50), @tbl nvarchar(300), @col nvarchar(128), @act varchar(20)',
             @co = @co, @tbl = @tbl, @col = @col,
             @act = 'Compte';

        IF @Action = 'UPDATE' AND @traiter = 1
        BEGIN
            SET @sql = N'
                UPDATE t SET t.' + QUOTENAME(@col) + N' = l.[Nouveau No_]
                FROM ' + QUOTENAME(@tbl) + N' t
                JOIN ' + QUOTENAME(@journal) + N' l
                  ON l.[Ancien No_] COLLATE DATABASE_DEFAULT = t.' + QUOTENAME(@col) + N' COLLATE DATABASE_DEFAULT
                WHERE l.[Statut] = 0;';
            EXEC sp_executesql @sql;

            INSERT #resultat VALUES (@co, @tbl, @col, @@ROWCOUNT, 'Mis a jour');
        END

        FETCH NEXT FROM cTbl INTO @tbl, @col;
    END
    CLOSE cTbl;
    DEALLOCATE cTbl;

    FETCH NEXT FROM cSoc INTO @co;
END
CLOSE cSoc;
DEALLOCATE cSoc;

SELECT Societe, Table_, Colonne, Lignes, Action_
FROM #resultat
WHERE Lignes > 0
ORDER BY Action_, Lignes DESC;

DROP TABLE #aTraiter;
DROP TABLE #resultat;
