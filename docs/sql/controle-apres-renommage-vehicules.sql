/* =====================================================================
   Apres le renommage : reste-t-il quelque part un ancien numero ?

   A lancer en entier : Ctrl+A puis F5. Rien a modifier.

   Business Central ne repercute un renommage que sur les colonnes qui
   portent une relation vers l'article. Les autres gardent l'ancien
   numero, sans le moindre message. Ce script cherche les 850 anciens
   numeros dans toutes les colonnes de numero d'article de 3S AGENCE.

   Les anciens numeros viennent du journal du renommage, et non des
   fiches : apres l'operation, plus aucune fiche ne porte l'ancienne
   forme, chercher a partir d'elles reviendrait a chercher une liste
   vide et a se rassurer a tort.

   Trois resultats :
     1. le nombre d'anciens numeros retrouves dans le journal, 850 attendu
     2. la liste des colonnes qui en contiennent encore, vide attendue
     3. le compte des colonnes balayees et des colonnes concernees

   Ce script ne fait que LIRE.
   ===================================================================== */

USE SOPIQ_PROD_BC16;
GO

SET NOCOUNT ON;
GO

/* --- 1. Les anciens numeros, pris dans le journal -------------------- */
IF OBJECT_ID('tempdb..#anciens') IS NOT NULL DROP TABLE #anciens;

SELECT DISTINCT [Ancien No_] COLLATE DATABASE_DEFAULT AS AncienNo
INTO #anciens
FROM [3S AGENCE$Log Renommage Refs$fe610c13-6229-4f65-9f57-05b0ea985881]
WHERE [Statut] = 0
  AND [Date Heure] >= '20260928';

CREATE CLUSTERED INDEX IX_anciens ON #anciens (AncienNo);
GO

SELECT NbAnciensNumeros = COUNT(*) FROM #anciens;
GO

/* --- 2. La table des resultats --------------------------------------- */
/*     Creee dans son propre lot : SQL verifie les noms de colonnes avant
       d'executer, et comparerait sinon a une table restee d'un essai
       precedent.                                                          */
IF OBJECT_ID('tempdb..#resultat') IS NOT NULL DROP TABLE #resultat;

CREATE TABLE #resultat (
    Table_ nvarchar(300) COLLATE DATABASE_DEFAULT,
    Colonne nvarchar(128) COLLATE DATABASE_DEFAULT,
    NbLignes int
);
GO

/* --- 3. Le balayage --------------------------------------------------- */
/*     Le journal du renommage est exclu : il contient les anciens numeros
       par construction, c'est sa raison d'etre.                           */
SET NOCOUNT ON;

DECLARE @tbl nvarchar(300), @col nvarchar(128), @sql nvarchar(max);

DECLARE cCol CURSOR LOCAL FAST_FORWARD FOR
    SELECT o.name, c.name
    FROM sys.objects AS o
    JOIN sys.columns AS c ON c.object_id = o.object_id
    JOIN sys.types AS ty ON ty.user_type_id = c.user_type_id
    WHERE o.type = 'U'
      AND o.name COLLATE DATABASE_DEFAULT LIKE '3S AGENCE$%'
      AND ty.name IN ('nvarchar', 'varchar', 'nchar', 'char')
      AND (c.name COLLATE DATABASE_DEFAULT LIKE '%Item No#_%' ESCAPE '#'
           OR c.name COLLATE DATABASE_DEFAULT IN (N'Article', N'Item', N'No_ 2',
                                                  N'Parent Item No_', N'Substitute No_'))
      AND o.name COLLATE DATABASE_DEFAULT NOT LIKE '%Log Renommage Refs%'
    ORDER BY o.name, c.name;

OPEN cCol;
FETCH NEXT FROM cCol INTO @tbl, @col;
WHILE @@FETCH_STATUS = 0
BEGIN
    SET @sql = N'
        INSERT #resultat (Table_, Colonne, NbLignes)
        SELECT @tbl, @col, COUNT(*)
        FROM ' + QUOTENAME(@tbl) + N' AS t
        JOIN #anciens AS a
          ON a.AncienNo = t.' + QUOTENAME(@col) + N' COLLATE DATABASE_DEFAULT;';

    BEGIN TRY
        EXEC sys.sp_executesql @sql,
             N'@tbl nvarchar(300), @col nvarchar(128)',
             @tbl = @tbl, @col = @col;
    END TRY
    BEGIN CATCH
        INSERT #resultat VALUES (@tbl, @col, -1);   -- colonne illisible, a regarder
    END CATCH

    FETCH NEXT FROM cCol INTO @tbl, @col;
END

CLOSE cCol;
DEALLOCATE cCol;
GO

/* --- 4. Le verdict ---------------------------------------------------- */
SELECT Table_, Colonne, NbLignes
FROM #resultat
WHERE NbLignes <> 0
ORDER BY NbLignes DESC, Table_;

SELECT NbColonnesBalayees = COUNT(*),
       NbColonnesConcernees = SUM(CASE WHEN NbLignes > 0 THEN 1 ELSE 0 END),
       NbColonnesIllisibles = SUM(CASE WHEN NbLignes = -1 THEN 1 ELSE 0 END)
FROM #resultat;
GO
