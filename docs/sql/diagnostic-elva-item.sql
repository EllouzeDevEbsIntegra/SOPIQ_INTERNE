/* =====================================================================
   Diagnostic des tables de l'interface Reapro (ELVA_ITEM, ELVA_ORDER).

   Pourquoi : la mesure du 26/09/2026 sur SOPIQ_DEV montre que chaque
   appel de l'interface lit 48 239 pages de ELVA_ITEM, soit la table
   entiere, pour ne ramener que quelques references. Sur la fenetre de
   mesure, cela represente pres de 28 secondes de travail SQL, en
   continu, sur le meme serveur que Business Central.

   Ces tables ne sont pas des tables Business Central : pas de prefixe
   societe, pas d'identifiant d'extension. On peut donc les indexer sans
   toucher a l'application ni aux extensions.

   Ce script ne fait que LIRE. Il ne cree rien.
   A executer sur SOPIQ_DEV, puis sur la base de production.
   ===================================================================== */

USE SOPIQ_DEV;
GO

/* --- 1. Les tables existent-elles, et quelle taille font-elles ? ----- */
SELECT
    t.name AS Tablename,
    p.rows AS NbLignes,
    CAST(SUM(a.total_pages) * 8.0 / 1024 AS DECIMAL(10, 1)) AS TailleMo
FROM sys.tables AS t
JOIN sys.indexes AS i ON i.object_id = t.object_id
JOIN sys.partitions AS p ON p.object_id = t.object_id AND p.index_id = i.index_id
JOIN sys.allocation_units AS a ON a.container_id = p.partition_id
WHERE t.name IN ('ELVA_ITEM', 'ELVA_ORDER')
  AND i.index_id IN (0, 1)
GROUP BY t.name, p.rows
ORDER BY t.name;

/* --- 2. Quels index existent deja ? ---------------------------------- */
SELECT
    t.name AS Tablename,
    ISNULL(i.name, '(tas, aucun index)') AS Nomindex,
    i.type_desc AS Typeindex,
    i.is_unique AS Unique_,
    STUFF((
        SELECT ', ' + c.name
        FROM sys.index_columns AS ic
        JOIN sys.columns AS c
            ON c.object_id = ic.object_id AND c.column_id = ic.column_id
        WHERE ic.object_id = i.object_id
          AND ic.index_id = i.index_id
          AND ic.is_included_column = 0
        ORDER BY ic.key_ordinal
        FOR XML PATH('')
    ), 1, 2, '') AS Colonnesdecle,
    STUFF((
        SELECT ', ' + c.name
        FROM sys.index_columns AS ic
        JOIN sys.columns AS c
            ON c.object_id = ic.object_id AND c.column_id = ic.column_id
        WHERE ic.object_id = i.object_id
          AND ic.index_id = i.index_id
          AND ic.is_included_column = 1
        ORDER BY ic.index_column_id
        FOR XML PATH('')
    ), 1, 2, '') AS Colonnesincluses
FROM sys.tables AS t
JOIN sys.indexes AS i ON i.object_id = t.object_id
WHERE t.name IN ('ELVA_ITEM', 'ELVA_ORDER')
ORDER BY t.name, i.index_id;

/* --- 3. Type exact des colonnes filtrees ----------------------------- */
/*     Le type compte : un index sur une colonne de type different de
       celui du parametre envoye par l'application ne sera pas utilise.  */
SELECT
    t.name AS Tablename,
    c.name AS Colonne,
    ty.name AS Type_,
    c.max_length AS LongueurMax,
    c.collation_name AS Classement,
    c.is_nullable AS Nullable
FROM sys.tables AS t
JOIN sys.columns AS c ON c.object_id = t.object_id
JOIN sys.types AS ty ON ty.user_type_id = c.user_type_id
WHERE t.name IN ('ELVA_ITEM', 'ELVA_ORDER')
  AND c.name IN ('No_', 'Vendor Item No_', 'Reference Origine Lié',
                 'Tecdoc id fabricant', 'Item', 'Code Statut', 'Posting Date')
ORDER BY t.name, c.column_id;

/* --- 4. Ce que ces requetes ont deja coute au serveur ---------------- */
/*     Chiffres cumules depuis le dernier demarrage de SQL Server.       */
SELECT TOP 20
    CAST(qs.total_elapsed_time / 1000000.0 AS DECIMAL(12, 1)) AS SecondesTotal,
    qs.execution_count AS NbExecutions,
    CAST(qs.total_elapsed_time / 1000.0 / qs.execution_count AS DECIMAL(12, 1)) AS MsParExecution,
    qs.total_logical_reads / qs.execution_count AS PagesParExecution,
    SUBSTRING(t.text, 1, 200) AS DebutRequete
FROM sys.dm_exec_query_stats AS qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS t
WHERE t.text LIKE '%ELVA_%'
ORDER BY qs.total_elapsed_time DESC;
GO
