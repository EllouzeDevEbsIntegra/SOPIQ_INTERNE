-- Diagnostic, lecture seule, a executer sur la base de PRODUCTION (SOPIQ_PROD_BC16).
-- Objectif : comprendre pourquoi le reperage ne remonte rien.

-- 1. Comment s'appellent reellement les tables Item, et combien de lignes
SELECT t.name AS Table_, SUM(p.rows) AS Lignes
FROM sys.tables t
JOIN sys.partitions p ON p.object_id = t.object_id AND p.index_id IN (0, 1)
WHERE t.name LIKE '%$Item$%' OR t.name LIKE '%$Manufacturer$%'
GROUP BY t.name
ORDER BY t.name;

-- 2. Longueur des n d'article et dernier caractere, sur la plus grosse table Item
DECLARE @t nvarchar(200), @sql nvarchar(max);

SELECT TOP 1 @t = t.name
FROM sys.tables t
JOIN sys.partitions p ON p.object_id = t.object_id AND p.index_id IN (0, 1)
WHERE t.name LIKE '%$Item$%'
GROUP BY t.name
ORDER BY SUM(p.rows) DESC;

SELECT @t AS TableAnalysee;

SET @sql = N'
SELECT LEN(RTRIM([No_])) AS Longueur,
       SUM(CASE WHEN RIGHT(RTRIM([No_]), 1) = ''0'' THEN 1 ELSE 0 END) AS FinissentPar0,
       COUNT(*) AS Articles
FROM ' + QUOTENAME(@t) + N'
GROUP BY LEN(RTRIM([No_]))
ORDER BY Longueur;';
EXEC sp_executesql @sql;

-- 3. Dix exemples de n d'article de cette table
SET @sql = N'SELECT TOP 10 [No_], [Description], [Manufacturer Code] FROM ' + QUOTENAME(@t) + N' ORDER BY [No_];';
EXEC sp_executesql @sql;

-- 4. Codes fabricants utilises, les 30 plus frequents
SET @sql = N'
SELECT TOP 30 [Manufacturer Code], COUNT(*) AS Articles
FROM ' + QUOTENAME(@t) + N'
GROUP BY [Manufacturer Code]
ORDER BY COUNT(*) DESC;';
EXEC sp_executesql @sql;
