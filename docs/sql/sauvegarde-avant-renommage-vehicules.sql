/* =====================================================================
   Photo avant le renommage des versions de modele Mercedes de 3S AGENCE.

   Regle du renommage : 3S AGENCE, type Modele Version, marque Mercedes,
   numero de six chiffres. 204002 devient 204.002. Perimetre mesure le
   28/09/2026 : 850 fiches, aucune forme pointee deja prise.

   Pourquoi cette photo. Business Central propage un renommage partout ou
   une relation de table existe. Deux tables posent probleme :

     - "items Master" n'est pas par societe. En renommant un vehicule de
       3S AGENCE, le renommage emporte aussi les lignes qui appartiennent
       a SOPIQ PROD, STE COPIM ou STE MPAA. C'est ce qui s'est produit
       hier avec 204002, devenu C204002 jusque dans la ligne de SOPIQ PROD.
     - "Specific Item Ledger Entry" n'a aucune relation vers l'article.
       Le renommage ne l'atteint pas, elle reste sur les anciens numeros,
       en silence. C'est la table des vehicules, elle est donc en plein
       dans le sujet.

   Ce script fait deux choses :
     1. il CREE deux tables de sauvegarde, copies conformes des donnees
        avant renommage. C'est la seule ecriture, elle n'altere rien ;
     2. il affiche ce qui sera touche, pour le savoir avant.

   Les tables de sauvegarde peuvent etre supprimees une fois le chantier
   termine et controle. Les commandes de suppression sont a la fin.
   ===================================================================== */

USE SOPIQ_PROD_BC16;
GO

SET NOCOUNT ON;
GO

/* ---------------------------------------------------------------------
   BLOC 1 : les deux sauvegardes.
   --------------------------------------------------------------------- */
IF OBJECT_ID('dbo.SauvegardeItemsMaster_20260928') IS NOT NULL
    PRINT 'Sauvegarde items Master deja presente, rien de fait.';
ELSE
BEGIN
    SELECT * INTO dbo.SauvegardeItemsMaster_20260928
    FROM [items Master$fe610c13-6229-4f65-9f57-05b0ea985881];

    PRINT 'Sauvegarde items Master creee : '
        + CAST(@@ROWCOUNT AS varchar) + ' lignes.';
END
GO

IF OBJECT_ID('dbo.SauvegardeSpecificILE3S_20260928') IS NOT NULL
    PRINT 'Sauvegarde Specific Item Ledger Entry deja presente, rien de fait.';
ELSE
BEGIN
    SELECT * INTO dbo.SauvegardeSpecificILE3S_20260928
    FROM [3S AGENCE$Specific Item Ledger Entry$fe610c13-6229-4f65-9f57-05b0ea985881];

    PRINT 'Sauvegarde Specific Item Ledger Entry creee : '
        + CAST(@@ROWCOUNT AS varchar) + ' lignes.';
END
GO

/* ---------------------------------------------------------------------
   BLOC 2 : ce que le renommage va toucher.
   --------------------------------------------------------------------- */

/*  Les 850 fiches concernees, et leur futur numero.                      */
IF OBJECT_ID('tempdb..#cibles') IS NOT NULL DROP TABLE #cibles;

SELECT [No_] COLLATE DATABASE_DEFAULT AS AncienNo,
       LEFT([No_], 3) + '.' + SUBSTRING([No_], 4, 3) COLLATE DATABASE_DEFAULT AS NouveauNo,
       [Description] COLLATE DATABASE_DEFAULT AS Description
INTO #cibles
FROM [3S AGENCE$Item$437dbf0e-84ff-417a-965d-ed2bb9650972]
WHERE [Item Type] = 2
  AND [Make Code] LIKE '%MERCEDES%'
  AND LEN([No_]) = 6
  AND [No_] NOT LIKE '%[^0-9]%';

SELECT COUNT(*) AS NbFichesARenommer FROM #cibles;
GO

/*  Les lignes de items Master qui portent un de ces numeros. Celles dont
    la societe n'est pas 3S AGENCE seront emportees a tort : ce sont elles
    qu'il faudra remettre apres le renommage.                             */
SELECT M.[Company] AS Societe,
       COUNT(*) AS NbLignes
FROM [items Master$fe610c13-6229-4f65-9f57-05b0ea985881] AS M
JOIN #cibles AS C ON C.AncienNo = M.[No] COLLATE DATABASE_DEFAULT
GROUP BY M.[Company]
ORDER BY M.[Company];

SELECT TOP 50
       M.[No] AS Numero, M.[Company] AS Societe, M.[Master], M.[Verified] AS Valide,
       C.NouveauNo AS DeviendraitAtort
FROM [items Master$fe610c13-6229-4f65-9f57-05b0ea985881] AS M
JOIN #cibles AS C ON C.AncienNo = M.[No] COLLATE DATABASE_DEFAULT
WHERE M.[Company] <> '3S AGENCE'
ORDER BY M.[No];

/*  Les ecritures specifiques restees sur les anciens numeros : elles ne
    suivront pas, il faudra les mettre a jour a la main.                  */
SELECT COUNT(*) AS NbEcrituresSpecifiquesAMettreAJour
FROM [3S AGENCE$Specific Item Ledger Entry$fe610c13-6229-4f65-9f57-05b0ea985881] AS S
JOIN #cibles AS C ON C.AncienNo = S.[Item No_] COLLATE DATABASE_DEFAULT;
GO

/* =====================================================================
   Suppression des sauvegardes, une fois le chantier termine et controle.
   =====================================================================

DROP TABLE dbo.SauvegardeItemsMaster_20260928;
DROP TABLE dbo.SauvegardeSpecificILE3S_20260928;

===================================================================== */
