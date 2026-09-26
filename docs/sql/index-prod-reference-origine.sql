/* =====================================================================
   Index sur [Reference Origine Lié], base de PRODUCTION.

   Mesure faite le 26/09/2026 sur SOPIQ_DEV, meme table, memes donnees :

       avant  : 12 810 lectures logiques, 3 analyses completes, 32 ms
       apres  :      4 lectures logiques, 1 recherche ciblee,     0 ms

   La requete concernee est celle que les applications externes envoient
   a la vue Amiral_LS.dbo.ELVA_Item :

       SELECT count(*) FROM ELVA_ITEM WHERE [Reference Origine Lié] = @P0

   relevee a 20 514 executions et 924 secondes cumulees, chacune lisant
   les 182 809 articles pour n'en retenir qu'une poignee.

   Cet index ne fait pas partie du modele Business Central. Une
   synchronisation d'extension peut le supprimer : il suffit alors de
   relancer ce script. Il ne change aucun comportement fonctionnel, il
   ne fait qu'offrir a SQL un chemin d'acces direct.

   Portee : la seule societe lue par les vues de l'interface, SOPIQ PROD.
   Duree observee sur DEV : une seconde.
   La commande de retrait est donnee a la fin.
   ===================================================================== */

USE SOPIQ_PROD_BC16;
GO

SET NOCOUNT ON;
GO

DECLARE @table sysname = N'SOPIQ PROD$Item$ad36f199-c652-4e8e-9c9a-ca851e424760';
DECLARE @index sysname = N'IDX_PERF_ItemExt_RefOrigine';
DECLARE @sql nvarchar(max);
DECLARE @debut datetime;

IF OBJECT_ID(QUOTENAME(@table)) IS NULL
    PRINT 'Table introuvable, rien de fait : ' + @table;
ELSE IF EXISTS (SELECT 1 FROM sys.indexes
                WHERE name = @index AND object_id = OBJECT_ID(QUOTENAME(@table)))
    PRINT 'Index deja present, rien de fait.';
ELSE
BEGIN
    SET @debut = GETDATE();
    SET @sql = N'CREATE NONCLUSTERED INDEX ' + QUOTENAME(@index)
             + N' ON ' + QUOTENAME(@table) + N' ([Reference Origine Lié]);';
    EXEC sys.sp_executesql @sql;
    PRINT 'Index cree en ' + CAST(DATEDIFF(SECOND, @debut, GETDATE()) AS varchar) + ' secondes.';
END
GO

/* --- Controle : l'index est-il la, et de quelle taille ? ------------- */
SELECT
    i.name AS Nomindex,
    i.type_desc AS Type_,
    p.rows AS NbLignes,
    CAST(SUM(a.used_pages) * 8.0 / 1024 AS DECIMAL(10, 1)) AS TailleMo
FROM sys.indexes AS i
JOIN sys.partitions AS p ON p.object_id = i.object_id AND p.index_id = i.index_id
JOIN sys.allocation_units AS a ON a.container_id = p.partition_id
WHERE i.name = 'IDX_PERF_ItemExt_RefOrigine'
GROUP BY i.name, i.type_desc, p.rows;
GO

/* ---------------------------------------------------------------------
   Retrait, si l'on veut revenir en arriere.
   --------------------------------------------------------------------- */
/*
USE SOPIQ_PROD_BC16;
DROP INDEX IDX_PERF_ItemExt_RefOrigine
    ON dbo.[SOPIQ PROD$Item$ad36f199-c652-4e8e-9c9a-ca851e424760];
*/
