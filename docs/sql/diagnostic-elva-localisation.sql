/* =====================================================================
   Ou vivent les tables de l'interface Reapro, et depuis quand ces
   compteurs tournent.

   Le diagnostic precedent a montre que ELVA_ITEM n'est pas dans
   SOPIQ_DEV. Les statistiques de requetes de SQL Server couvrent toute
   l'instance, pas une base : les requetes vues viennent donc d'une
   autre base hebergee sur le meme serveur, qui partage la memoire, le
   processeur et les disques de Business Central.

   Ce script ne fait que LIRE. Il ne cree rien.
   A executer n'importe ou sur l'instance, le contexte de base n'a pas
   d'importance.
   ===================================================================== */

/* --- 1. Depuis quand les compteurs tournent -------------------------- */
/*     Sans cette duree, les temps cumules ne veulent rien dire.         */
SELECT
    sqlserver_start_time AS DemarrageSqlServer,
    DATEDIFF(HOUR, sqlserver_start_time, SYSDATETIME()) AS HeuresDepuisDemarrage,
    DATEDIFF(DAY, sqlserver_start_time, SYSDATETIME()) AS JoursDepuisDemarrage
FROM sys.dm_os_sys_info;

/* --- 2. De quelle base viennent les requetes de l'interface ? -------- */
SELECT
    DB_NAME(CAST(pa.value AS INT)) AS BaseDeDonnees,
    COUNT(*) AS NbRequetesEnCache,
    SUM(qs.execution_count) AS NbExecutions,
    CAST(SUM(qs.total_elapsed_time) / 1000000.0 AS DECIMAL(12, 1)) AS SecondesCumulees,
    SUM(qs.total_logical_reads) AS PagesLuesCumulees
FROM sys.dm_exec_query_stats AS qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS t
CROSS APPLY sys.dm_exec_plan_attributes(qs.plan_handle) AS pa
WHERE pa.attribute = 'dbid'
  AND t.text LIKE '%ELVA%'
GROUP BY DB_NAME(CAST(pa.value AS INT))
ORDER BY SecondesCumulees DESC;

/* --- 3. Meme question, pour TOUTES les requetes de l'instance -------- */
/*     Pour situer la part de Business Central dans le total.            */
SELECT TOP 20
    DB_NAME(CAST(pa.value AS INT)) AS BaseDeDonnees,
    SUM(qs.execution_count) AS NbExecutions,
    CAST(SUM(qs.total_elapsed_time) / 1000000.0 AS DECIMAL(12, 1)) AS SecondesCumulees,
    CAST(SUM(qs.total_worker_time) / 1000000.0 AS DECIMAL(12, 1)) AS SecondesProcesseur,
    SUM(qs.total_logical_reads) AS PagesLuesCumulees
FROM sys.dm_exec_query_stats AS qs
CROSS APPLY sys.dm_exec_plan_attributes(qs.plan_handle) AS pa
WHERE pa.attribute = 'dbid'
GROUP BY DB_NAME(CAST(pa.value AS INT))
ORDER BY SecondesCumulees DESC;

/* --- 4. Les tables ELVA, dans toutes les bases de l'instance --------- */
DECLARE @sql NVARCHAR(MAX) = N'';

SELECT @sql = @sql + N'
SELECT ' + QUOTENAME(d.name, '''') + N' AS BaseDeDonnees,
       t.name AS Tablename,
       SUM(CASE WHEN i.index_id IN (0, 1) THEN p.rows ELSE 0 END) AS NbLignes,
       COUNT(DISTINCT CASE WHEN i.index_id > 1 THEN i.index_id END) AS NbIndexSecondaires
FROM ' + QUOTENAME(d.name) + N'.sys.tables AS t
JOIN ' + QUOTENAME(d.name) + N'.sys.indexes AS i ON i.object_id = t.object_id
JOIN ' + QUOTENAME(d.name) + N'.sys.partitions AS p
     ON p.object_id = t.object_id AND p.index_id = i.index_id
WHERE t.name LIKE ''ELVA%''
GROUP BY t.name
UNION ALL'
FROM sys.databases AS d
WHERE d.state = 0
  AND d.database_id > 4
  AND HAS_DBACCESS(d.name) = 1;

IF LEN(@sql) > 0
BEGIN
    SET @sql = LEFT(@sql, LEN(@sql) - LEN('UNION ALL')) + N' ORDER BY BaseDeDonnees, Tablename;';
    EXEC sys.sp_executesql @sql;
END
ELSE
    SELECT 'Aucune base accessible pour la recherche' AS Resultat;
GO
