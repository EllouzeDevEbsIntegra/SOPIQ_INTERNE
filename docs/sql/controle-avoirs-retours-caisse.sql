/* =====================================================================
   Avoirs et retours : effet de la correction, et recensement des avoirs
   portant un timbre fiscal.

   Contexte du 28/09/2026. Sur les documents de sens negatif, avoir client,
   retour BS et retour BL, la caisse rend de l'argent : le montant de
   reglement est enregistre en negatif, et "Montant reçu caisse" l'est donc
   aussi. Le rapport "Etat Solde Client" le soustrayait, ce qui revenait a
   l'ajouter : un retour de 100 deja rembourse de 40 affichait 140 au lieu
   de 60. La fiche, elle, reproposait la totalite du document au lieu du
   reste.

   Seconde regle, confirmee par le metier : un avoir ne porte pas de timbre
   fiscal. Le rapport en comptait un, ce qui rendait ces avoirs impossibles
   a solder.

   Ce script ne fait que LIRE. Il ne corrige aucune donnee.

   Changer la base a la premiere ligne :
       SOPIQ_DEV        pour l'exemple a montrer a la caisse
       SOPIQ_PROD_BC16  pour le recensement en production
   ===================================================================== */

USE SOPIQ_DEV;
GO

SET NOCOUNT ON;

DECLARE @base nvarchar(50) = N'437dbf0e-84ff-417a-965d-ed2bb9650972';
DECLARE @interne nvarchar(50) = N'fe610c13-6229-4f65-9f57-05b0ea985881';
DECLARE @st nvarchar(50) = N'840d69c1-a2ae-4b41-bfb1-4b23af2cf237';
DECLARE @sql nvarchar(max) = N'';

IF OBJECT_ID('tempdb..#societes') IS NOT NULL DROP TABLE #societes;
CREATE TABLE #societes (Nom nvarchar(50) COLLATE DATABASE_DEFAULT);
INSERT #societes
SELECT LEFT(name, CHARINDEX('$Sales Cr_Memo Header$', name) - 1) COLLATE DATABASE_DEFAULT
FROM sys.tables
WHERE name LIKE '%$Sales Cr_Memo Header$' + @base;

/* ---------------------------------------------------------------------
   1. L'EXEMPLE A MONTRER A LA CAISSE.

   Les documents deja rembourses en partie : ceux ou l'ancienne formule et
   la nouvelle ne disent pas la meme chose. La colonne AncienMontant est ce
   que le rapport affichait, NouveauMontant ce qu'il affichera.
   --------------------------------------------------------------------- */
SELECT @sql = @sql + N'
SELECT ' + QUOTENAME(s.Nom, '''') + N' AS Societe,
       ''Avoir client'' AS Type_,
       A.[No_] AS Document,
       A.[Bill-to Customer No_] AS Client,
       A.[Posting Date] AS DateDocument,
       R.MontantTTC,
       R.DejaRembourse AS RenduParLaCaisse,
       R.MontantTTC + R.Timbre - R.RecuCaisse AS AncienMontant,
       R.MontantTTC + R.RecuCaisse           AS NouveauMontant
FROM ' + QUOTENAME(s.Nom + '$Sales Cr_Memo Header$' + @base) + N' AS A
CROSS APPLY (
    SELECT MontantTTC = ISNULL((SELECT SUM(L.[Amount Including VAT])
                                FROM ' + QUOTENAME(s.Nom + '$Sales Cr_Memo Line$' + @base) + N' AS L
                                WHERE L.[Document No_] = A.[No_]), 0),
           Timbre     = ISNULL(E.[STStamp Amount], 0),
           RecuCaisse = ISNULL((SELECT SUM(D.[Montant Reglement])
                                FROM ' + QUOTENAME(s.Nom + '$Recu Caisse Document$' + @interne) + N' AS D
                                WHERE D.[Document No] COLLATE DATABASE_DEFAULT = A.[No_] COLLATE DATABASE_DEFAULT), 0),
           DejaRembourse = -ISNULL((SELECT SUM(D.[Montant Reglement])
                                FROM ' + QUOTENAME(s.Nom + '$Recu Caisse Document$' + @interne) + N' AS D
                                WHERE D.[Document No] COLLATE DATABASE_DEFAULT = A.[No_] COLLATE DATABASE_DEFAULT), 0)
) AS R
LEFT JOIN ' + QUOTENAME(s.Nom + '$Sales Cr_Memo Header$' + @st) + N' AS E
    ON E.[No_] = A.[No_]
WHERE A.[solde] = 0
  AND R.RecuCaisse <> 0
UNION ALL'
FROM #societes AS s
WHERE OBJECT_ID(QUOTENAME(s.Nom + '$Recu Caisse Document$' + @interne)) IS NOT NULL;

IF LEN(@sql) > 0
BEGIN
    SET @sql = LEFT(@sql, LEN(@sql) - LEN('UNION ALL')) + N' ORDER BY Societe, Document;';
    EXEC sys.sp_executesql @sql;
END
ELSE
    SELECT 'Aucune societe trouvee' AS Resultat;
GO

/* ---------------------------------------------------------------------
   2. LE RECENSEMENT DEMANDE : les avoirs non soldes portant un timbre.

   Ce sont des erreurs de saisie anciennes. Tant qu'un timbre y figure, le
   rapport ne pouvait pas les solder. Aucune correction n'est faite ici.
   --------------------------------------------------------------------- */
SET NOCOUNT ON;

DECLARE @base2 nvarchar(50) = N'437dbf0e-84ff-417a-965d-ed2bb9650972';
DECLARE @st2 nvarchar(50) = N'840d69c1-a2ae-4b41-bfb1-4b23af2cf237';
DECLARE @sql2 nvarchar(max) = N'';

SELECT @sql2 = @sql2 + N'
SELECT ' + QUOTENAME(s.Nom, '''') + N' AS Societe,
       COUNT(*) AS NbAvoirsNonSoldesAvecTimbre,
       SUM(E.[STStamp Amount]) AS TotalTimbres,
       MIN(A.[Posting Date]) AS PlusAncien,
       MAX(A.[Posting Date]) AS PlusRecent
FROM ' + QUOTENAME(s.Nom + '$Sales Cr_Memo Header$' + @base2) + N' AS A
JOIN ' + QUOTENAME(s.Nom + '$Sales Cr_Memo Header$' + @st2) + N' AS E
    ON E.[No_] = A.[No_]
WHERE A.[solde] = 0
  AND ISNULL(E.[STStamp Amount], 0) <> 0
UNION ALL'
FROM #societes AS s
WHERE OBJECT_ID(QUOTENAME(s.Nom + '$Sales Cr_Memo Header$' + @st2)) IS NOT NULL;

IF LEN(@sql2) > 0
BEGIN
    SET @sql2 = LEFT(@sql2, LEN(@sql2) - LEN('UNION ALL')) + N' ORDER BY Societe;';
    EXEC sys.sp_executesql @sql2;
END
GO

/* ---------------------------------------------------------------------
   3. Le detail de ces avoirs, cinquante premiers.
   --------------------------------------------------------------------- */
SET NOCOUNT ON;

DECLARE @base3 nvarchar(50) = N'437dbf0e-84ff-417a-965d-ed2bb9650972';
DECLARE @st3 nvarchar(50) = N'840d69c1-a2ae-4b41-bfb1-4b23af2cf237';
DECLARE @sql3 nvarchar(max) = N'';

SELECT @sql3 = @sql3 + N'
SELECT TOP 50 ' + QUOTENAME(s.Nom, '''') + N' AS Societe,
       A.[No_] AS Avoir,
       A.[Bill-to Customer No_] AS Client,
       A.[Posting Date] AS DateDocument,
       E.[STStamp Amount] AS Timbre
FROM ' + QUOTENAME(s.Nom + '$Sales Cr_Memo Header$' + @base3) + N' AS A
JOIN ' + QUOTENAME(s.Nom + '$Sales Cr_Memo Header$' + @st3) + N' AS E
    ON E.[No_] = A.[No_]
WHERE A.[solde] = 0
  AND ISNULL(E.[STStamp Amount], 0) <> 0
UNION ALL'
FROM #societes AS s
WHERE OBJECT_ID(QUOTENAME(s.Nom + '$Sales Cr_Memo Header$' + @st3)) IS NOT NULL;

IF LEN(@sql3) > 0
BEGIN
    SET @sql3 = LEFT(@sql3, LEN(@sql3) - LEN('UNION ALL')) + N' ORDER BY Societe, DateDocument;';
    EXEC sys.sp_executesql @sql3;
END
GO
