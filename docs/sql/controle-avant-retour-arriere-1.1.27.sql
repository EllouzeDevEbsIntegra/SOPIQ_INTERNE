/* =====================================================================
   A lancer AVANT un retour arriere de 1.1.27.0 vers 1.1.13.0.

   Le retour arriere supprime les deux colonnes ajoutees depuis 1.1.13 :
   [Version Correction] et [Historique Corrections] sur le recu de caisse.
   Elles portent l'historique des corrections de recu envoyees par Reapro.

   Depuis le 01/10/2026, Reapro appelle la PRODUCTION. Ces colonnes peuvent
   donc contenir des donnees reelles, contrairement au retour arriere du
   29/09. Si ce script rend autre chose que des zeros, le retour arriere
   DETRUIT l'historique des corrections : en parler avant de le lancer, et
   exporter ces lignes au prealable.

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
        WHERE [Version Correction] <> 0) AS RecusCorriges,
       (SELECT COUNT(*) FROM ' + QUOTENAME(s.Nom + '$Recu Caisse$' + @interne) + N'
        WHERE DATALENGTH([Historique Corrections]) > 0) AS RecusAvecHistorique,
       (SELECT ISNULL(MAX([Version Correction]), 0) FROM ' + QUOTENAME(s.Nom + '$Recu Caisse$' + @interne) + N'
        ) AS PlusGrandNoDeVersion
UNION ALL'
FROM (SELECT LEFT(name, CHARINDEX('$Recu Caisse$', name) - 1) AS Nom
      FROM sys.tables
      WHERE name LIKE '%$Recu Caisse$' + @interne) AS s;

/* Retirer le dernier UNION ALL */
SET @sql = LEFT(@sql, LEN(@sql) - LEN('UNION ALL')) + N';';

EXEC sys.sp_executesql @sql;
GO

/* ---------------------------------------------------------------------
   Si des lignes sont corrigees, les lister avant de decider. Remplacer
   le nom de societe par celui qui ressort du controle ci-dessus.
   --------------------------------------------------------------------- */
-- SELECT [No_], [Version Correction], DATALENGTH([Historique Corrections]) AS TailleHistorique
-- FROM [STE COPIM$Recu Caisse$fe610c13-6229-4f65-9f57-05b0ea985881]
-- WHERE [Version Correction] <> 0
-- ORDER BY [No_];
