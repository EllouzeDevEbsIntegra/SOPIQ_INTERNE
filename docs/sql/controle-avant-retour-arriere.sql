/* =====================================================================
   A lancer AVANT un retour arriere de 1.1.10.0 vers 1.0.9.0.

   Le retour arriere supprime les colonnes ajoutees par 1.1.x. Elles ne
   sont ecrites que par l'API appelee par Reapro, qui n'appelle pas encore
   la production : elles doivent donc etre vides.

   Si ce script rend autre chose que des zeros, c'est que Reapro ecrit en
   production. ARRETER, et en parler avant de supprimer quoi que ce soit.

   Ce script ne fait que LIRE.
   ===================================================================== */

USE SOPIQ_PROD_BC16;
GO

SET NOCOUNT ON;
GO

DECLARE @interne nvarchar(50) = N'fe610c13-6229-4f65-9f57-05b0ea985881';
DECLARE @sql nvarchar(max) = N'';

SELECT @sql = @sql + N'
SELECT ' + QUOTENAME(s.Nom, '''') + N' AS Societe,
       (SELECT COUNT(*) FROM ' + QUOTENAME(s.Nom + '$Recu Caisse$' + @interne) + N'
        WHERE [Id Brouillon Reapro] <> '''') AS RecusVenusDeReapro,
       (SELECT COUNT(*) FROM ' + QUOTENAME(s.Nom + '$Recu Caisse$' + @interne) + N'
        WHERE DATALENGTH([Contenu Reapro]) > 0) AS RecusAvecContenuReapro,
       (SELECT COUNT(*) FROM ' + QUOTENAME(s.Nom + '$Recu Caisse Document$' + @interne) + N'
        WHERE [Date Document] <> ''1753-01-01''
           OR [Reste A Payer] <> 0
           OR [Signe] <> 0
           OR [Est Fournisseur] <> 0
           OR [Type Nom] <> '''') AS LignesAvecChampsDeLApi
UNION ALL'
FROM (SELECT LEFT(name, CHARINDEX('$Recu Caisse$', name) - 1) AS Nom
      FROM sys.tables
      WHERE name LIKE '%$Recu Caisse$' + @interne) AS s;

/* Retirer le dernier UNION ALL */
SET @sql = LEFT(@sql, LEN(@sql) - LEN('UNION ALL')) + N';';

EXEC sys.sp_executesql @sql;
GO
