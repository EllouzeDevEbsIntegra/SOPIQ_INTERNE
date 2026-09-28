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

   Les trois morceaux d'un avoir vivent dans trois tables :
     - le document lui-meme, application de base ;
     - "solde", extension SOPIQ INTERNE, champ 80436 ;
     - "STStamp Amount", extension StandardTunisien, champ 70001.

   Ce script ne fait que LIRE. Il ne corrige aucune donnee.

   Changer la base a la premiere ligne :
       SOPIQ_DEV        pour l'exemple a montrer a la caisse
       SOPIQ_PROD_BC16  pour le recensement en production
   ===================================================================== */

USE SOPIQ_DEV;
GO

SET NOCOUNT ON;
GO

/* --- Les societes, et les trois tables de chacune --------------------- */
IF OBJECT_ID('tempdb..#avoirs') IS NOT NULL DROP TABLE #avoirs;
CREATE TABLE #avoirs (
    Societe nvarchar(50) COLLATE DATABASE_DEFAULT,
    Avoir nvarchar(20) COLLATE DATABASE_DEFAULT,
    Client nvarchar(20) COLLATE DATABASE_DEFAULT,
    DateDocument date,
    MontantTTC decimal(38, 3),
    Timbre decimal(38, 3),
    RecuCaisse decimal(38, 3),
    Solde bit
);

DECLARE @base nvarchar(50) = N'437dbf0e-84ff-417a-965d-ed2bb9650972';
DECLARE @interne nvarchar(50) = N'fe610c13-6229-4f65-9f57-05b0ea985881';
DECLARE @st nvarchar(50) = N'840d69c1-a2ae-4b41-bfb1-4b23af2cf237';
DECLARE @sql nvarchar(max) = N'';

SELECT @sql = @sql + N'
INSERT #avoirs (Societe, Avoir, Client, DateDocument, MontantTTC, Timbre, RecuCaisse, Solde)
SELECT ' + QUOTENAME(s.Nom, '''') + N' COLLATE DATABASE_DEFAULT,
       A.[No_] COLLATE DATABASE_DEFAULT,
       A.[Bill-to Customer No_] COLLATE DATABASE_DEFAULT,
       A.[Posting Date],
       ISNULL(L.MontantTTC, 0),
       ISNULL(T.[STStamp Amount], 0),
       ISNULL(R.RecuCaisse, 0),
       I.[solde]
FROM ' + QUOTENAME(s.Nom + '$Sales Cr_Memo Header$' + @base) + N' AS A
JOIN ' + QUOTENAME(s.Nom + '$Sales Cr_Memo Header$' + @interne) + N' AS I
    ON I.[No_] = A.[No_]
LEFT JOIN ' + QUOTENAME(s.Nom + '$Sales Cr_Memo Header$' + @st) + N' AS T
    ON T.[No_] = A.[No_]
LEFT JOIN (
    SELECT [Document No_] AS No_, SUM([Amount Including VAT]) AS MontantTTC
    FROM ' + QUOTENAME(s.Nom + '$Sales Cr_Memo Line$' + @base) + N'
    GROUP BY [Document No_]) AS L
    ON L.No_ = A.[No_]
LEFT JOIN (
    SELECT [Document No] COLLATE DATABASE_DEFAULT AS No_,
           SUM([Montant Reglement]) AS RecuCaisse
    FROM ' + QUOTENAME(s.Nom + '$Recu Caisse Document$' + @interne) + N'
    GROUP BY [Document No]) AS R
    ON R.No_ = A.[No_] COLLATE DATABASE_DEFAULT;'
FROM (SELECT LEFT(name, CHARINDEX('$Sales Cr_Memo Header$', name) - 1) AS Nom
      FROM sys.tables
      WHERE name LIKE '%$Sales Cr_Memo Header$' + @interne) AS s;

EXEC sys.sp_executesql @sql;
GO

/* ---------------------------------------------------------------------
   1. L'EXEMPLE A MONTRER A LA CAISSE.

   Les avoirs non soldes deja rembourses en partie : ceux ou l'ancienne
   formule et la nouvelle ne disent pas la meme chose.
     AncienMontant  ce que le rapport affichait
     NouveauMontant ce qu'il affichera
   --------------------------------------------------------------------- */
SELECT Societe, Avoir, Client, DateDocument,
       MontantTTC,
       -RecuCaisse AS RenduParLaCaisse,
       Timbre,
       MontantTTC + Timbre - RecuCaisse AS AncienMontant,
       MontantTTC + RecuCaisse          AS NouveauMontant
FROM #avoirs
WHERE Solde = 0
  AND (RecuCaisse <> 0 OR Timbre <> 0)
ORDER BY Societe, DateDocument;

/* ---------------------------------------------------------------------
   2. LE RECENSEMENT DEMANDE : les avoirs non soldes portant un timbre.
   --------------------------------------------------------------------- */
SELECT Societe,
       COUNT(*) AS NbAvoirsNonSoldesAvecTimbre,
       SUM(Timbre) AS TotalTimbres,
       MIN(DateDocument) AS PlusAncien,
       MAX(DateDocument) AS PlusRecent
FROM #avoirs
WHERE Solde = 0
  AND Timbre <> 0
GROUP BY Societe
ORDER BY Societe;

/* ---------------------------------------------------------------------
   3. Le detail de ces avoirs, cinquante premiers.
   --------------------------------------------------------------------- */
SELECT TOP 50 Societe, Avoir, Client, DateDocument, MontantTTC, Timbre
FROM #avoirs
WHERE Solde = 0
  AND Timbre <> 0
ORDER BY Societe, DateDocument;

/* ---------------------------------------------------------------------
   4. Pour situer : combien d'avoirs non soldes en tout.
   --------------------------------------------------------------------- */
SELECT Societe,
       COUNT(*) AS NbAvoirsNonSoldes,
       SUM(CASE WHEN Timbre <> 0 THEN 1 ELSE 0 END) AS DontAvecTimbre,
       SUM(CASE WHEN RecuCaisse <> 0 THEN 1 ELSE 0 END) AS DontDejaRembourses
FROM #avoirs
WHERE Solde = 0
GROUP BY Societe
ORDER BY Societe;
GO
