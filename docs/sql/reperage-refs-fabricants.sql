-- Reperage des references article de 10 caracteres se terminant par 0, LECTURE SEULE.
-- A executer dans SSMS sur la base de PRODUCTION (SOPIQ_PROD_BC16).
-- Aucune ecriture : que des SELECT, sur toutes les societes de la base.
--
-- Regle envisagee : reference de 10 caracteres finissant par '0' -> on retire ce '0',
-- la reference passe a 9 caracteres. Le champ vise est le n d'article (No_).
--
-- Resultat 1 : par societe et par fabricant, nombre d'articles concernes et nombre de
--              collisions (la reference a 9 caracteres existe deja comme article).
-- Resultat 2 : exemples ancien / nouveau pour les fabricants LUK, INA, FAG, VITESCO,
--              avec l'etat du stock et de l'historique de chaque article.

SET NOCOUNT ON;

-- Le suffixe est un GUID de 36 caracteres : ne pas le declarer plus court, il serait
-- tronque et aucune societe ne serait trouvee.
DECLARE @base nvarchar(50) = N'437dbf0e-84ff-417a-965d-ed2bb9650972';  -- Base Application

IF OBJECT_ID('tempdb..#res') IS NOT NULL DROP TABLE #res;
IF OBJECT_ID('tempdb..#ex') IS NOT NULL DROP TABLE #ex;
CREATE TABLE #res (
    Societe nvarchar(50), Fabricant nvarchar(50), NomFabricant nvarchar(100),
    Articles int, RefsConcernees int, Collisions int, RefsBloquees int
);
CREATE TABLE #ex (
    Societe nvarchar(50), Fabricant nvarchar(50), AncienneRef nvarchar(50),
    NouvelleRef nvarchar(50), Description nvarchar(100),
    RefCibleExiste int, Stock decimal(38, 20), Ecritures int
);

DECLARE @sql nvarchar(max), @co nvarchar(50);
DECLARE c CURSOR LOCAL FAST_FORWARD FOR
    SELECT LEFT(name, CHARINDEX('$Item$', name) - 1)
    FROM sys.tables
    WHERE name LIKE '%$Item$' + @base;

OPEN c;
FETCH NEXT FROM c INTO @co;
WHILE @@FETCH_STATUS = 0
BEGIN
    -- Resultat 1 : comptages par fabricant
    -- La collision est calculee par une jointure et non par un EXISTS : SQL Server
    -- refuse une sous-requete a l'interieur d'un SUM.
    SET @sql = N'
    INSERT #res
    SELECT @co, t.Fabricant, MAX(t.NomFabricant), COUNT(*),
           SUM(t.Concerne), SUM(t.Collision), SUM(t.Bloque)
    FROM (
        SELECT CASE WHEN ISNULL(i.[Manufacturer Code], '''') = '''' THEN ''(sans fabricant)''
                    ELSE i.[Manufacturer Code] END AS Fabricant,
               ISNULL(m.[Name], '''') AS NomFabricant,
               CASE WHEN LEN(RTRIM(i.[No_])) = 10 AND RIGHT(RTRIM(i.[No_]), 1) = ''0''
                    THEN 1 ELSE 0 END AS Concerne,
               CASE WHEN LEN(RTRIM(i.[No_])) = 10 AND RIGHT(RTRIM(i.[No_]), 1) = ''0''
                     AND x.[No_] IS NOT NULL THEN 1 ELSE 0 END AS Collision,
               CASE WHEN LEN(RTRIM(i.[No_])) = 10 AND RIGHT(RTRIM(i.[No_]), 1) = ''0''
                     AND (i.[Blocked] = 1 OR i.[Sales Blocked] = 1 OR i.[Purchasing Blocked] = 1)
                    THEN 1 ELSE 0 END AS Bloque
        FROM ' + QUOTENAME(@co + '$Item$' + @base) + N' i
        LEFT JOIN ' + QUOTENAME(@co + '$Manufacturer$' + @base) + N' m ON m.[Code] = i.[Manufacturer Code]
        LEFT JOIN ' + QUOTENAME(@co + '$Item$' + @base) + N' x ON x.[No_] = LEFT(RTRIM(i.[No_]), 9)
    ) t
    GROUP BY t.Fabricant
    HAVING SUM(t.Concerne) > 0;';
    EXEC sp_executesql @sql, N'@co nvarchar(50)', @co = @co;

    -- Resultat 2 : exemples pour les quatre fabricants demandes
    SET @sql = N'
    INSERT #ex
    SELECT TOP 8 @co, i.[Manufacturer Code], RTRIM(i.[No_]), LEFT(RTRIM(i.[No_]), 9), i.[Description],
           CASE WHEN EXISTS (SELECT 1 FROM ' + QUOTENAME(@co + '$Item$' + @base) + N' x
                             WHERE x.[No_] = LEFT(RTRIM(i.[No_]), 9)) THEN 1 ELSE 0 END,
           (SELECT ISNULL(SUM(ile.[Quantity]), 0) FROM ' + QUOTENAME(@co + '$Item Ledger Entry$' + @base) + N' ile
            WHERE ile.[Item No_] = i.[No_]),
           (SELECT COUNT(*) FROM ' + QUOTENAME(@co + '$Item Ledger Entry$' + @base) + N' ile
            WHERE ile.[Item No_] = i.[No_])
    FROM ' + QUOTENAME(@co + '$Item$' + @base) + N' i
    LEFT JOIN ' + QUOTENAME(@co + '$Manufacturer$' + @base) + N' m ON m.[Code] = i.[Manufacturer Code]
    WHERE LEN(RTRIM(i.[No_])) = 10 AND RIGHT(RTRIM(i.[No_]), 1) = ''0''
      AND (i.[Manufacturer Code] IN (''LUK'', ''INA'', ''FAG'', ''VITESCO'')
           OR m.[Name] LIKE ''%LUK%'' OR m.[Name] LIKE ''%INA%''
           OR m.[Name] LIKE ''%FAG%'' OR m.[Name] LIKE ''%VITESCO%'')
    ORDER BY i.[No_];';
    EXEC sp_executesql @sql, N'@co nvarchar(50)', @co = @co;

    FETCH NEXT FROM c INTO @co;
END
CLOSE c;
DEALLOCATE c;

-- Resultat 1
SELECT Societe, Fabricant, NomFabricant, Articles, RefsConcernees, Collisions, RefsBloquees
FROM #res
ORDER BY Societe, RefsConcernees DESC, Fabricant;

-- Resultat 2
SELECT Societe, Fabricant, AncienneRef, NouvelleRef, Description, RefCibleExiste,
       CAST(Stock AS decimal(18, 2)) AS Stock, Ecritures
FROM #ex
ORDER BY Societe, Fabricant, AncienneRef;

DROP TABLE #res;
DROP TABLE #ex;
