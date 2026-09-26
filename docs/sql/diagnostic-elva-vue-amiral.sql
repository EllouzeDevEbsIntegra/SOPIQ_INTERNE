/* =====================================================================
   Ce que lisent reellement les vues de l'interface Reapro, dans la base
   Amiral_LS.

   Contexte : les applications externes interrogent ELVA_ITEM, qui est
   une vue. Une vue ne stocke rien : SQL remplace la vue par sa
   definition et execute le tout sur les tables sous-jacentes. Les
   2 345 522 pages lues par appel viennent donc de ces tables, et si ce
   sont celles de Business Central, la charge retombe sur le meme
   serveur, la meme memoire et les memes disques que BC.

   But du script : savoir quelles tables sont lues et quelles colonnes
   sont filtrees, pour dire si un index cote Business Central suffit.

   Ce script ne fait que LIRE. Il ne cree, ne modifie et ne supprime
   rien. Aucun objet n'est touche.
   ===================================================================== */

USE Amiral_LS;
GO

/* --- 1. Les objets ELVA : vues, tables, fonctions ? ------------------ */
SELECT
    s.name AS Schema_,
    o.name AS Objet,
    o.type_desc AS Type_,
    o.create_date AS Creele,
    o.modify_date AS Modifiele
FROM sys.objects AS o
JOIN sys.schemas AS s ON s.schema_id = o.schema_id
WHERE o.name LIKE 'ELVA%'
ORDER BY o.type_desc, o.name;

/* --- 2. Les tables que ces vues vont lire --------------------------- */
/*     Y compris dans d'autres bases : la colonne BaseReferencee dira
       si l'on tombe sur les bases de Business Central.                  */
SELECT
    v.name AS Vue,
    ISNULL(re.referenced_database_name, DB_NAME()) AS BaseReferencee,
    ISNULL(re.referenced_schema_name, 'dbo') AS SchemaReference,
    re.referenced_entity_name AS ObjetReference
FROM sys.views AS v
CROSS APPLY sys.dm_sql_referenced_entities(
    QUOTENAME(SCHEMA_NAME(v.schema_id)) + '.' + QUOTENAME(v.name), 'OBJECT') AS re
WHERE v.name LIKE 'ELVA%'
  AND re.referenced_minor_name IS NULL
ORDER BY v.name, BaseReferencee, ObjetReference;

/* --- 3. La definition de la vue principale --------------------------- */
/*     Une ligne par ligne de code. Si le resultat est tronque dans la
       grille, passer en resultats texte avec Ctrl+T avant d'executer.    */
EXEC sys.sp_helptext N'dbo.ELVA_ITEM';
GO

/* --- 4. La deuxieme vue la plus sollicitee --------------------------- */
/*     675 secondes cumulees a elle seule, 25 117 pages par appel.        */
IF OBJECT_ID('dbo.ELVA_ITEM_KIT') IS NOT NULL
    EXEC sys.sp_helptext N'dbo.ELVA_ITEM_KIT';
GO
