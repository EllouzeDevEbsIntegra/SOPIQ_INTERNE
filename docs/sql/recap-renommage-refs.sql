-- Recapitulatif du renommage des references fabricants, LECTURE SEULE.
-- A executer apres le passage de outils\renommer-refs.ps1, sur la base concernee
-- (SOPIQ_PROD_BC16 en production).
--
-- Resultat 1 : par societe, par execution et par statut, le nombre de references.
-- Resultat 2 : les collisions, references non traitees, a regarder une par une.

SET NOCOUNT ON;

DECLARE @app nvarchar(50) = N'fe610c13-6229-4f65-9f57-05b0ea985881';  -- SOPIQ INTERNE

IF OBJECT_ID('tempdb..#log') IS NOT NULL DROP TABLE #log;
CREATE TABLE #log (
    Societe nvarchar(50), DateHeure datetime, Fabricant nvarchar(20),
    AncienNo nvarchar(20), NouveauNo nvarchar(20), Statut int, Simulation tinyint
);

DECLARE @sql nvarchar(max), @t nvarchar(200), @co nvarchar(50);
DECLARE c CURSOR LOCAL FAST_FORWARD FOR
    SELECT name, LEFT(name, CHARINDEX('$Log Renommage Refs$', name) - 1)
    FROM sys.tables
    WHERE name LIKE '%$Log Renommage Refs$' + @app;

OPEN c;
FETCH NEXT FROM c INTO @t, @co;
WHILE @@FETCH_STATUS = 0
BEGIN
    SET @sql = N'INSERT #log SELECT [Societe], [Date Heure], [Fabricant], [Ancien No_],
                 [Nouveau No_], [Statut], [Simulation] FROM ' + QUOTENAME(@t) + N';';
    EXEC sp_executesql @sql;
    FETCH NEXT FROM c INTO @t, @co;
END
CLOSE c;
DEALLOCATE c;

-- Resultat 1 : compte par societe, execution et statut
SELECT Societe,
       CAST(DateHeure AS date) AS Jour,
       CASE Statut WHEN 0 THEN 'Renomme' WHEN 1 THEN 'Collision' ELSE 'Simule' END AS Statut,
       Simulation,
       COUNT(*) AS References_,
       MIN(DateHeure) AS Debut,
       MAX(DateHeure) AS Fin
FROM #log
GROUP BY Societe, CAST(DateHeure AS date),
         CASE Statut WHEN 0 THEN 'Renomme' WHEN 1 THEN 'Collision' ELSE 'Simule' END,
         Simulation
ORDER BY Societe, Jour, Statut;

-- Resultat 2 : les collisions, a traiter a la main
SELECT Societe, Fabricant, AncienNo, NouveauNo, DateHeure, Simulation
FROM #log
WHERE Statut = 1
ORDER BY Societe, Fabricant, AncienNo;

DROP TABLE #log;
