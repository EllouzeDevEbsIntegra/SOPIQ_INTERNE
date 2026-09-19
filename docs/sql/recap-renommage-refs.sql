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
    Societe nvarchar(50), DateHeure datetime, Execution datetime, Fabricant nvarchar(20),
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
    SET @sql = N'INSERT #log SELECT [Societe], [Date Heure], [Execution], [Fabricant], [Ancien No_],
                 [Nouveau No_], [Statut], [Simulation] FROM ' + QUOTENAME(@t) + N';';
    EXEC sp_executesql @sql;
    FETCH NEXT FROM c INTO @t, @co;
END
CLOSE c;
DEALLOCATE c;

-- Resultat 1 : compte par execution, societe et statut (dernier passage en haut)
SELECT Execution, Societe,
       CASE Statut WHEN 0 THEN 'Renomme' WHEN 1 THEN 'Collision' ELSE 'Simule' END AS Statut,
       Simulation,
       COUNT(*) AS References_,
       MAX(DateHeure) AS Fin
FROM #log
GROUP BY Execution, Societe,
         CASE Statut WHEN 0 THEN 'Renomme' WHEN 1 THEN 'Collision' ELSE 'Simule' END,
         Simulation
ORDER BY Execution DESC, Societe, Statut;

-- Resultat 2 : les collisions du dernier passage, a traiter a la main
SELECT Societe, Fabricant, AncienNo, NouveauNo, Execution, Simulation
FROM #log
WHERE Statut = 1
  AND Execution >= DATEADD(minute, -5, (SELECT MAX(Execution) FROM #log))
ORDER BY Societe, Fabricant, AncienNo;

-- Resultat 3 : references contenant une lettre ailleurs qu'en premiere position,
-- parmi celles retenues au dernier passage. Doit etre vide si la regle ne doit
-- porter que sur des references entierement numeriques.
SELECT Societe, Fabricant, AncienNo, NouveauNo
FROM #log
WHERE Execution >= DATEADD(minute, -5, (SELECT MAX(Execution) FROM #log))
  AND AncienNo LIKE '%[A-Za-z]%'
ORDER BY Societe, Fabricant, AncienNo;

DROP TABLE #log;
