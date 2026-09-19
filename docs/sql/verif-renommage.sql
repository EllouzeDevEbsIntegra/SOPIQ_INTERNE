-- Verification apres un renommage reel, LECTURE SEULE.
-- A executer sur SOPIQ_PROD_BC16 apres le passage de outils\renommer-refs.ps1 -Reel.
--
-- Pour chaque reference reellement renommee (statut Renomme dans le journal), on
-- controle que plus rien ne porte l'ancien n et que tout porte le nouveau :
--   - la fiche article ;
--   - les ecritures article et les ecritures valeur ;
--   - les lignes de facture vente et les lignes de BS archives.
--
-- Resultat attendu : toutes les colonnes "Ancien" a 0, "ArticlesNouveau" egal au
-- nombre de references renommees.

SET NOCOUNT ON;

DECLARE @base nvarchar(50) = N'437dbf0e-84ff-417a-965d-ed2bb9650972';  -- Base Application
DECLARE @sopicbc nvarchar(50) = N'ad36f199-c652-4e8e-9c9a-ca851e424760';  -- SOPICBC16A
DECLARE @app nvarchar(50) = N'fe610c13-6229-4f65-9f57-05b0ea985881';  -- SOPIQ INTERNE

IF OBJECT_ID('tempdb..#ctrl') IS NOT NULL DROP TABLE #ctrl;
CREATE TABLE #ctrl (
    Societe nvarchar(50), Refs int,
    ArticlesAncien int, ArticlesNouveau int,
    EcrArticleAncien int, EcrArticleNouveau int,
    EcrValeurAncien int, EcrValeurNouveau int,
    LignesFactureAncien int, LignesFactureNouveau int,
    LignesBSAncien int, LignesBSNouveau int
);

DECLARE @sql nvarchar(max), @co nvarchar(50);
DECLARE c CURSOR LOCAL FAST_FORWARD FOR
    SELECT LEFT(name, CHARINDEX('$Log Renommage Refs$', name) - 1)
    FROM sys.tables
    WHERE name LIKE '%$Log Renommage Refs$' + @app;

OPEN c;
FETCH NEXT FROM c INTO @co;
WHILE @@FETCH_STATUS = 0
BEGIN
    SET @sql = N'
    WITH renommees AS (
        SELECT [Ancien No_] AS AncienNo, [Nouveau No_] AS NouveauNo
        FROM ' + QUOTENAME(@co + '$Log Renommage Refs$' + @app) + N'
        WHERE [Statut] = 0
    )
    INSERT #ctrl
    SELECT @co,
           (SELECT COUNT(*) FROM renommees),
           (SELECT COUNT(*) FROM renommees r JOIN ' + QUOTENAME(@co + '$Item$' + @base) + N' i
                   ON i.[No_] = r.AncienNo),
           (SELECT COUNT(*) FROM renommees r JOIN ' + QUOTENAME(@co + '$Item$' + @base) + N' i
                   ON i.[No_] = r.NouveauNo),
           (SELECT COUNT(*) FROM renommees r JOIN ' + QUOTENAME(@co + '$Item Ledger Entry$' + @base) + N' e
                   ON e.[Item No_] = r.AncienNo),
           (SELECT COUNT(*) FROM renommees r JOIN ' + QUOTENAME(@co + '$Item Ledger Entry$' + @base) + N' e
                   ON e.[Item No_] = r.NouveauNo),
           (SELECT COUNT(*) FROM renommees r JOIN ' + QUOTENAME(@co + '$Value Entry$' + @base) + N' v
                   ON v.[Item No_] = r.AncienNo),
           (SELECT COUNT(*) FROM renommees r JOIN ' + QUOTENAME(@co + '$Value Entry$' + @base) + N' v
                   ON v.[Item No_] = r.NouveauNo),
           (SELECT COUNT(*) FROM renommees r JOIN ' + QUOTENAME(@co + '$Sales Invoice Line$' + @base) + N' l
                   ON l.[No_] = r.AncienNo),
           (SELECT COUNT(*) FROM renommees r JOIN ' + QUOTENAME(@co + '$Sales Invoice Line$' + @base) + N' l
                   ON l.[No_] = r.NouveauNo),
           (SELECT COUNT(*) FROM renommees r JOIN ' + QUOTENAME(@co + '$Ligne archive BS$' + @sopicbc) + N' b
                   ON b.[No_] = r.AncienNo),
           (SELECT COUNT(*) FROM renommees r JOIN ' + QUOTENAME(@co + '$Ligne archive BS$' + @sopicbc) + N' b
                   ON b.[No_] = r.NouveauNo);';
    EXEC sp_executesql @sql, N'@co nvarchar(50)', @co = @co;

    FETCH NEXT FROM c INTO @co;
END
CLOSE c;
DEALLOCATE c;

SELECT * FROM #ctrl ORDER BY Societe;

DROP TABLE #ctrl;
