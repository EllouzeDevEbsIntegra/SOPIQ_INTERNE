/* =====================================================================
   Index des lignes vente par client, pour la liste clients. PRODUCTION.

   Pourquoi. La liste clients recalcule l'encours de chaque client affiche.
   Le champ "Shipped Not Invoiced BL" somme les lignes vente avec deux
   filtres qui interdisent a Business Central d'utiliser ses sommes
   precalculees : un filtre sur le montant qu'il somme, et un filtre sur
   "Expédition type", un champ calcule de la ligne. Il lit donc les lignes
   une a une.

   Mesure du 30/09/2026 a l'ouverture de la liste : 58 executions,
   1 467 709 pages lues, 3,91 s.

   Essai sur DEV le meme jour, sur cinquante clients :
       avant   55 639 pages, 94 ms
       apres      340 pages, 11 ms
   Valeurs identiques client par client. Apres publication sur DEV, la
   boucle a disparu de la mesure et l'utilisateur a confirme le gain a
   l'usage.

   Ce que fait ce script : il pose le meme index sur les lignes vente de
   chaque societe de la production. Il ne change ni les donnees, ni le
   schema connu de Business Central, ni aucun chiffre affiche. Seul le
   chemin d'acces change.

   A lancer en heure creuse : l'edition Standard ne sait pas construire un
   index en ligne, la table des lignes vente est donc brievement
   verrouillee. Quelques secondes par societe.

   Retour arriere au bloc 3.
   ===================================================================== */

USE SOPIQ_PROD_BC16;
GO

SET NOCOUNT ON;
GO

/* ---------------------------------------------------------------------
   BLOC 1 : etat des lieux. Les tables concernees, leur taille, et
   l'index est-il deja pose.
   --------------------------------------------------------------------- */
SELECT t.name AS Table_,
       CAST(SUM(p.rows) AS bigint) AS NbLignes,
       CAST(SUM(a.total_pages) * 8.0 / 1024 AS decimal(10, 1)) AS TailleMo,
       CASE WHEN EXISTS (SELECT 1 FROM sys.indexes i
                         WHERE i.object_id = t.object_id
                           AND i.name = 'IDX_PERF_SalesLine_BillTo')
            THEN 'deja pose' ELSE 'absent' END AS Index_
FROM sys.tables AS t
JOIN sys.partitions AS p ON p.object_id = t.object_id AND p.index_id IN (0, 1)
JOIN sys.allocation_units AS a ON a.container_id = p.partition_id
WHERE t.name LIKE '%$Sales Line$437dbf0e-84ff-417a-965d-ed2bb9650972'
GROUP BY t.name, t.object_id
ORDER BY NbLignes DESC;
GO

/* ---------------------------------------------------------------------
   BLOC 2 : poser l'index sur chaque societe.

   Il ne fait rien la ou l'index existe deja, le script est donc
   relancable sans risque.
   --------------------------------------------------------------------- */
DECLARE @sql nvarchar(max) = N'';

SELECT @sql = @sql + N'
PRINT ''Index sur ' + t.name + N'...'';
CREATE NONCLUSTERED INDEX IDX_PERF_SalesLine_BillTo
    ON ' + QUOTENAME(t.name) + N' ([Bill-to Customer No_], [Document Type])
    INCLUDE ([Shipped Not Invoiced (LCY)], [Return Rcd_ Not Invd_ (LCY)])
    WITH (DATA_COMPRESSION = PAGE);'
FROM sys.tables AS t
WHERE t.name LIKE '%$Sales Line$437dbf0e-84ff-417a-965d-ed2bb9650972'
  AND NOT EXISTS (SELECT 1 FROM sys.indexes i
                  WHERE i.object_id = t.object_id
                    AND i.name = 'IDX_PERF_SalesLine_BillTo');

IF @sql = N''
    PRINT 'Rien a faire : l''index est deja pose partout.';
ELSE
    EXEC sys.sp_executesql @sql;
GO

/* Relancer le bloc 1 pour verifier : toutes les lignes doivent afficher
   "deja pose". */

/* ---------------------------------------------------------------------
   BLOC 3 : RETOUR ARRIERE. Supprime l'index sur toutes les societes.
   --------------------------------------------------------------------- */
-- DECLARE @sqlDrop nvarchar(max) = N'';
-- SELECT @sqlDrop = @sqlDrop + N'
-- DROP INDEX IDX_PERF_SalesLine_BillTo ON ' + QUOTENAME(t.name) + N';'
-- FROM sys.tables AS t
-- JOIN sys.indexes AS i ON i.object_id = t.object_id
-- WHERE t.name LIKE '%$Sales Line$437dbf0e-84ff-417a-965d-ed2bb9650972'
--   AND i.name = 'IDX_PERF_SalesLine_BillTo';
-- EXEC sys.sp_executesql @sqlDrop;
-- GO
