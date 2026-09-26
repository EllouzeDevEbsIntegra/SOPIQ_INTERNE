/* =====================================================================
   Mesure de ce que coute reellement l'ouverture d'une page BC.

   Principe : les compteurs de sys.dm_exec_query_stats sont cumulatifs
   depuis le demarrage de SQL Server. On ne peut donc pas les lire tels
   quels, il faut comparer deux photos, avant et apres l'action mesuree.
   C'est l'erreur commise le 26/09/2026 au matin, qui avait donne un
   total absurde de 3 503 secondes pour une page.

   Mode d'emploi, dans UNE SEULE fenetre de requete, sans la fermer
   entre les etapes, car la table temporaire y est attachee :

     1. selectionner le BLOC 1, l'executer ;
     2. ouvrir la page a mesurer dans BC, attendre l'affichage complet ;
     3. selectionner le BLOC 2, l'executer.

   Base : SOPIQ_DEV sur SRV-DEV, ou la base de production concernee.
   ===================================================================== */

USE SOPIQ_DEV;
GO

/* ---------------------------------------------------------------------
   BLOC 1 : photo avant. A executer juste avant d'ouvrir la page.
   --------------------------------------------------------------------- */
IF OBJECT_ID('tempdb..#avant') IS NOT NULL DROP TABLE #avant;

SELECT
    qs.sql_handle,
    qs.statement_start_offset,
    qs.statement_end_offset,
    qs.plan_handle,
    qs.execution_count,
    qs.total_elapsed_time,
    qs.total_logical_reads
INTO #avant
FROM sys.dm_exec_query_stats AS qs;

SELECT COUNT(*) AS RequetesEnCache, SYSDATETIME() AS PhotoAvant FROM #avant;
GO

/* ---------------------------------------------------------------------
   BLOC 2 : photo apres, et ecart. A executer apres l'affichage complet
   de la page. Une ligne par requete, du plus couteux au moins couteux.
   --------------------------------------------------------------------- */
SELECT TOP 40
    CAST(ROUND((qs.total_elapsed_time - ISNULL(a.total_elapsed_time, 0)) / 1000000.0, 2) AS DECIMAL(10, 2)) AS Secondes,
    qs.execution_count - ISNULL(a.execution_count, 0) AS NbExecutions,
    qs.total_logical_reads - ISNULL(a.total_logical_reads, 0) AS PagesLues,
    SUBSTRING(
        t.text,
        (qs.statement_start_offset / 2) + 1,
        CASE qs.statement_end_offset
            WHEN -1 THEN DATALENGTH(t.text)
            ELSE (qs.statement_end_offset - qs.statement_start_offset) / 2
        END + 1
    ) AS Requete
FROM sys.dm_exec_query_stats AS qs
LEFT JOIN #avant AS a
    ON  a.sql_handle = qs.sql_handle
    AND a.statement_start_offset = qs.statement_start_offset
    AND a.statement_end_offset = qs.statement_end_offset
    AND a.plan_handle = qs.plan_handle
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS t
WHERE qs.execution_count > ISNULL(a.execution_count, 0)
ORDER BY (qs.total_elapsed_time - ISNULL(a.total_elapsed_time, 0)) DESC;
GO
