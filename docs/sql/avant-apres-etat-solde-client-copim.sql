/* =====================================================================
   Etat Solde Client, avant/apres, pour la caisse de STE COPIM.

   A montrer a la caisse avant toute mise en production du chantier recu
   de caisse. Condition posee par l'equipe de developpement Reapro.

   Trois calculs du rapport ont change. Sur les documents de sens negatif,
   avoir client, retour BL et retour BS, la caisse rend de l'argent : le
   montant de reglement est enregistre en negatif, et "Montant recu caisse"
   l'est donc aussi. Le rapport le soustrayait, ce qui revenait a l'ajouter.
   Un retour de 100 deja rembourse de 40 affichait 140 au lieu de 60.

   Sur les avoirs, une seconde correction : un avoir ne porte pas de timbre
   fiscal, le rapport en comptait un, ce qui rendait ces avoirs impossibles
   a solder.

   AncienMontant  ce que le rapport affiche aujourd'hui en production
   NouveauMontant ce qu'il affichera apres la mise en production

   Ce script ne fait que LIRE. Il ne corrige aucune donnee.
   ===================================================================== */

USE SOPIQ_PROD_BC16;
GO

SET NOCOUNT ON;
GO

DECLARE @societe nvarchar(50) = N'STE COPIM';
DECLARE @base    nvarchar(50) = N'437dbf0e-84ff-417a-965d-ed2bb9650972';
DECLARE @interne nvarchar(50) = N'fe610c13-6229-4f65-9f57-05b0ea985881';
DECLARE @st      nvarchar(50) = N'840d69c1-a2ae-4b41-bfb1-4b23af2cf237';
/* Les montants des lignes de retour vivent dans cette extension, pas dans la
   table de base : elle porte "Amount" et "Amount Including VAT". */
DECLARE @sopic   nvarchar(50) = N'ad36f199-c652-4e8e-9c9a-ca851e424760';

/* --- La societe gere-t-elle les BS ? De cette case depend le montant de
       base retenu sur les retours BL : le reste a facturer si elle est
       cochee, le total du document sinon. ------------------------------ */
DECLARE @sqlBS nvarchar(max) = N'
SELECT ''Gestion des BS'' AS Parametre, [BS] AS Valeur
FROM ' + QUOTENAME(@societe + '$Company Information$' + @interne) + N';';
EXEC sys.sp_executesql @sqlBS;

IF OBJECT_ID('tempdb..#docs') IS NOT NULL DROP TABLE #docs;
CREATE TABLE #docs (
    TypeDocument nvarchar(20) COLLATE DATABASE_DEFAULT,
    Document     nvarchar(20) COLLATE DATABASE_DEFAULT,
    Client       nvarchar(20) COLLATE DATABASE_DEFAULT,
    DateDocument date,
    MontantBase  decimal(38, 3),
    Timbre       decimal(38, 3),
    RecuCaisse   decimal(38, 3)
);

DECLARE @sql nvarchar(max) = N'';

/* --- 1. Les avoirs ---------------------------------------------------- */
SET @sql = N'
INSERT #docs (TypeDocument, Document, Client, DateDocument, MontantBase, Timbre, RecuCaisse)
SELECT N''Avoir'' COLLATE DATABASE_DEFAULT,
       A.[No_] COLLATE DATABASE_DEFAULT,
       A.[Bill-to Customer No_] COLLATE DATABASE_DEFAULT,
       A.[Posting Date],
       ISNULL(L.MontantTTC, 0),
       ISNULL(T.[STStamp Amount], 0),
       ISNULL(R.RecuCaisse, 0)
FROM ' + QUOTENAME(@societe + '$Sales Cr_Memo Header$' + @base) + N' AS A
JOIN ' + QUOTENAME(@societe + '$Sales Cr_Memo Header$' + @interne) + N' AS I
    ON I.[No_] = A.[No_]
LEFT JOIN ' + QUOTENAME(@societe + '$Sales Cr_Memo Header$' + @st) + N' AS T
    ON T.[No_] = A.[No_]
LEFT JOIN (
    SELECT [Document No_] AS No_, SUM([Amount Including VAT]) AS MontantTTC
    FROM ' + QUOTENAME(@societe + '$Sales Cr_Memo Line$' + @base) + N'
    GROUP BY [Document No_]) AS L
    ON L.No_ = A.[No_]
LEFT JOIN (
    SELECT [Document No] COLLATE DATABASE_DEFAULT AS No_,
           SUM([Montant Reglement]) AS RecuCaisse
    FROM ' + QUOTENAME(@societe + '$Recu Caisse Document$' + @interne) + N'
    GROUP BY [Document No]) AS R
    ON R.No_ = A.[No_] COLLATE DATABASE_DEFAULT
WHERE I.[solde] = 0;';
EXEC sys.sp_executesql @sql;

/* --- 2. Les retours, BL et BS -----------------------------------------
       Deux montants de base sont remontes pour chaque retour, le reste a
       facturer et le total du document : le rapport retient l'un ou
       l'autre selon la case "Gestion des BS" affichee plus haut. ------- */
SET @sql = N'
INSERT #docs (TypeDocument, Document, Client, DateDocument, MontantBase, Timbre, RecuCaisse)
SELECT CASE WHEN I.[BS] = 1 THEN N''Retour BS'' ELSE N''Retour BL'' END COLLATE DATABASE_DEFAULT,
       H.[No_] COLLATE DATABASE_DEFAULT,
       H.[Bill-to Customer No_] COLLATE DATABASE_DEFAULT,
       H.[Posting Date],
       CASE WHEN I.[BS] = 1 THEN ISNULL(L.TotalDocument, 0)
            WHEN C.[BS] = 1 THEN ISNULL(L.ResteAFacturer, 0)
            ELSE ISNULL(L.TotalDocument, 0) END,
       0,
       ISNULL(R.RecuCaisse, 0)
FROM ' + QUOTENAME(@societe + '$Return Receipt Header$' + @base) + N' AS H
JOIN ' + QUOTENAME(@societe + '$Return Receipt Header$' + @interne) + N' AS I
    ON I.[No_] = H.[No_]
CROSS JOIN ' + QUOTENAME(@societe + '$Company Information$' + @interne) + N' AS C
LEFT JOIN (
    SELECT B.[Document No_] AS No_,
           SUM(E.[Amount Including VAT]) AS TotalDocument,
           SUM(CASE WHEN B.[Return Qty_ Rcd_ Not Invd_] > 0
                    THEN E.[Amount Including VAT] ELSE 0 END) AS ResteAFacturer
    FROM ' + QUOTENAME(@societe + '$Return Receipt Line$' + @base) + N' AS B
    JOIN ' + QUOTENAME(@societe + '$Return Receipt Line$' + @sopic) + N' AS E
        ON E.[Document No_] = B.[Document No_] AND E.[Line No_] = B.[Line No_]
    GROUP BY B.[Document No_]) AS L
    ON L.No_ = H.[No_]
LEFT JOIN (
    SELECT [Document No] COLLATE DATABASE_DEFAULT AS No_,
           SUM([Montant Reglement]) AS RecuCaisse
    FROM ' + QUOTENAME(@societe + '$Recu Caisse Document$' + @interne) + N'
    GROUP BY [Document No]) AS R
    ON R.No_ = H.[No_] COLLATE DATABASE_DEFAULT
WHERE I.[solde] = 0;';
EXEC sys.sp_executesql @sql;
GO

/* ---------------------------------------------------------------------
   1. CE QUE LA CAISSE DOIT VOIR : les documents dont le montant affiche
      change. Les autres, la tres grande majorite, sont inchanges.
   --------------------------------------------------------------------- */
SELECT TypeDocument, Document, Client, DateDocument,
       MontantBase,
       -RecuCaisse AS RenduParLaCaisse,
       Timbre,
       MontantBase + Timbre - RecuCaisse AS AncienMontant,
       MontantBase + RecuCaisse          AS NouveauMontant,
       (MontantBase + RecuCaisse) - (MontantBase + Timbre - RecuCaisse) AS Ecart
FROM #docs
WHERE RecuCaisse <> 0 OR Timbre <> 0
ORDER BY TypeDocument, DateDocument, Document;

/* ---------------------------------------------------------------------
   2. LE RESUME, par type de document.
   --------------------------------------------------------------------- */
SELECT TypeDocument,
       COUNT(*) AS NbDocumentsNonSoldes,
       SUM(CASE WHEN RecuCaisse <> 0 OR Timbre <> 0 THEN 1 ELSE 0 END) AS DontMontantChange,
       SUM(MontantBase + Timbre - RecuCaisse) AS TotalAncien,
       SUM(MontantBase + RecuCaisse)          AS TotalNouveau
FROM #docs
GROUP BY TypeDocument
ORDER BY TypeDocument;

/* ---------------------------------------------------------------------
   3. LES DIX PLUS GROS ECARTS, pour l'exemple a l'ecran.
   --------------------------------------------------------------------- */
SELECT TOP 10 TypeDocument, Document, Client, DateDocument,
       MontantBase + Timbre - RecuCaisse AS AncienMontant,
       MontantBase + RecuCaisse          AS NouveauMontant
FROM #docs
WHERE RecuCaisse <> 0 OR Timbre <> 0
ORDER BY ABS((MontantBase + RecuCaisse) - (MontantBase + Timbre - RecuCaisse)) DESC;
GO

/* ---------------------------------------------------------------------
   4. CONTRE-EPREUVE.

   Les trois requetes precedentes ne rendent rien parce que le filtre du
   rapport, "non solde", ecarte les documents que la caisse a regles : un
   document regle est marque solde. Ce bloc le montre, en comptant les
   memes documents SANS ce filtre. S'il rend des lignes, la donnee est
   bien la, et c'est bien le filtre qui explique le resultat vide.
   --------------------------------------------------------------------- */
DECLARE @societe2 nvarchar(50) = N'STE COPIM';
DECLARE @base2    nvarchar(50) = N'437dbf0e-84ff-417a-965d-ed2bb9650972';
DECLARE @interne2 nvarchar(50) = N'fe610c13-6229-4f65-9f57-05b0ea985881';

DECLARE @sql2 nvarchar(max) = N'
SELECT N''Avoir'' AS TypeDocument,
       SUM(CASE WHEN I.[solde] = 1 THEN 1 ELSE 0 END) AS RegleEtSolde,
       SUM(CASE WHEN I.[solde] = 0 THEN 1 ELSE 0 END) AS RegleMaisNonSolde,
       SUM(R.RecuCaisse) AS TotalRenduParLaCaisse
FROM ' + QUOTENAME(@societe2 + '$Sales Cr_Memo Header$' + @base2) + N' AS A
JOIN ' + QUOTENAME(@societe2 + '$Sales Cr_Memo Header$' + @interne2) + N' AS I
    ON I.[No_] = A.[No_]
JOIN (
    SELECT [Document No] COLLATE DATABASE_DEFAULT AS No_,
           SUM([Montant Reglement]) AS RecuCaisse
    FROM ' + QUOTENAME(@societe2 + '$Recu Caisse Document$' + @interne2) + N'
    GROUP BY [Document No]) AS R
    ON R.No_ = A.[No_] COLLATE DATABASE_DEFAULT
WHERE R.RecuCaisse <> 0

UNION ALL

SELECT N''Retour'',
       SUM(CASE WHEN I.[solde] = 1 THEN 1 ELSE 0 END),
       SUM(CASE WHEN I.[solde] = 0 THEN 1 ELSE 0 END),
       SUM(R.RecuCaisse)
FROM ' + QUOTENAME(@societe2 + '$Return Receipt Header$' + @base2) + N' AS H
JOIN ' + QUOTENAME(@societe2 + '$Return Receipt Header$' + @interne2) + N' AS I
    ON I.[No_] = H.[No_]
JOIN (
    SELECT [Document No] COLLATE DATABASE_DEFAULT AS No_,
           SUM([Montant Reglement]) AS RecuCaisse
    FROM ' + QUOTENAME(@societe2 + '$Recu Caisse Document$' + @interne2) + N'
    GROUP BY [Document No]) AS R
    ON R.No_ = H.[No_] COLLATE DATABASE_DEFAULT
WHERE R.RecuCaisse <> 0;';
EXEC sys.sp_executesql @sql2;
GO
