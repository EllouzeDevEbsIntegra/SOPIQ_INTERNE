/* =====================================================================
   Le point est-il libre comme separateur des numeros de version de
   modele ?

   Regle retenue le 28/09/2026, apres discussion :

       societe 3S AGENCE
       ET type = Modele Version
       ET marque = Mercedes
       ET numero de six chiffres
       ALORS 204002 devient 204.002

   Tout le reste est laisse tel quel : autres marques, autres societes,
   numeros qui ne font pas six chiffres comme DS7, GOLF 6 ou T-CROSS.

   Objectif : qu'un numero de vehicule ne puisse plus jamais tomber sur un
   numero de piece, ce qui s'est produit avec la reference 204002, vanne
   EGR dans SOPIQ PROD et C 220 CDI dans 3S AGENCE.

   Ce script ne fait que LIRE. Il ne renomme rien.
   ===================================================================== */

USE SOPIQ_PROD_BC16;
GO

SET NOCOUNT ON;

DECLARE @base nvarchar(50) = N'437dbf0e-84ff-417a-965d-ed2bb9650972';
DECLARE @sql nvarchar(max) = N'';

IF OBJECT_ID('tempdb..#societes') IS NOT NULL DROP TABLE #societes;
CREATE TABLE #societes (Nom nvarchar(50) COLLATE DATABASE_DEFAULT);
INSERT #societes VALUES ('SOPIQ PROD'), ('STE COPIM'), ('3S AGENCE'), ('STE MPAA PROD');

IF OBJECT_ID('tempdb..#articles') IS NOT NULL DROP TABLE #articles;
/*  Classement force sur les colonnes texte : les tables d'extension et la
    base temporaire n'ont pas le meme, et SQL refuse de les comparer.      */
CREATE TABLE #articles (
    Societe nvarchar(50) COLLATE DATABASE_DEFAULT,
    No_ nvarchar(20) COLLATE DATABASE_DEFAULT,
    Description nvarchar(100) COLLATE DATABASE_DEFAULT,
    Marque nvarchar(20) COLLATE DATABASE_DEFAULT,
    TypeArticle int
);

SELECT @sql = @sql + N'
INSERT #articles (Societe, No_, Description, Marque, TypeArticle)
SELECT ' + QUOTENAME(s.Nom, '''') + N' COLLATE DATABASE_DEFAULT,
       I.[No_] COLLATE DATABASE_DEFAULT,
       I.[Description] COLLATE DATABASE_DEFAULT,
       I.[Make Code] COLLATE DATABASE_DEFAULT,
       I.[Item Type]
FROM ' + QUOTENAME(s.Nom + '$Item$' + @base) + N' AS I;'
FROM #societes AS s
WHERE OBJECT_ID(QUOTENAME(s.Nom + '$Item$' + @base)) IS NOT NULL;

EXEC sys.sp_executesql @sql;
GO
/*  Le GO ci-dessus est necessaire : SQL verifie les noms de colonnes de
    tout un lot avant de l'executer. Si une table temporaire du meme nom
    reste dans la session, il compare les colonnes a l'ancienne structure
    et refuse. En coupant le lot, les requetes qui suivent sont compilees
    apres la creation de la table. La table temporaire, elle, survit au GO.  */

/* --- 1. Quelles marques portent les versions de modele de 3S ? ------- */
/*     Pour connaitre le code exact de Mercedes et le poids des autres.   */
SELECT ISNULL(NULLIF(Marque, ''), '(sans marque)') AS Marque,
       COUNT(*) AS NbVersionsDeModele,
       SUM(CASE WHEN LEN(No_) = 6 AND No_ NOT LIKE '%[^0-9]%' THEN 1 ELSE 0 END) AS DontSixChiffres
FROM #articles
WHERE Societe = '3S AGENCE'
  AND TypeArticle = 2
GROUP BY ISNULL(NULLIF(Marque, ''), '(sans marque)')
ORDER BY NbVersionsDeModele DESC;

/* --- 2. Le point est-il deja utilise dans les numeros d'article ? ---- */
SELECT Societe,
       COUNT(*) AS NbNumerosContenantUnPoint
FROM #articles
WHERE No_ LIKE '%.%'
GROUP BY Societe
ORDER BY Societe;

SELECT TOP 30 Societe, No_, Description,
       CASE TypeArticle WHEN 2 THEN 'Version de modele' ELSE 'Article' END AS Type_
FROM #articles
WHERE No_ LIKE '%.%'
ORDER BY Societe, No_;

/* --- 3. Le perimetre exact de la regle ------------------------------- */
/*     SQL refuse un EXISTS a l'interieur d'un agregat, message 130 : les
       numeros deja pris sont rattaches par une jointure externe.         */
WITH Vehicules AS (
    SELECT No_, Description, Marque,
           LEFT(No_, 3) + '.' + SUBSTRING(No_, 4, 3) AS NouveauNo
    FROM #articles
    WHERE Societe = '3S AGENCE'
      AND TypeArticle = 2
      AND Marque LIKE '%MERCEDES%'
      AND LEN(No_) = 6
      AND No_ NOT LIKE '%[^0-9]%'
),
DejaPris AS (
    SELECT DISTINCT No_ FROM #articles
)
SELECT COUNT(*) AS NbVehiculesARenommer,
       SUM(CASE WHEN D.No_ IS NULL THEN 0 ELSE 1 END) AS NbFormesPointeesDejaPrises
FROM Vehicules AS V
LEFT JOIN DejaPris AS D ON D.No_ = V.NouveauNo;

/* --- 4. Le detail des formes pointees deja prises, s'il y en a ------- */
WITH Vehicules AS (
    SELECT No_, Description, Marque,
           LEFT(No_, 3) + '.' + SUBSTRING(No_, 4, 3) AS NouveauNo
    FROM #articles
    WHERE Societe = '3S AGENCE'
      AND TypeArticle = 2
      AND Marque LIKE '%MERCEDES%'
      AND LEN(No_) = 6
      AND No_ NOT LIKE '%[^0-9]%'
)
SELECT V.No_ AS AncienNo, V.Description AS Vehicule, V.NouveauNo,
       A.Societe AS DejaPortePar, A.Description AS LibelleExistant
FROM Vehicules AS V
JOIN #articles AS A ON A.No_ = V.NouveauNo
ORDER BY V.No_;

/* --- 5. Un apercu de ce que donnerait le renommage ------------------- */
SELECT TOP 20
       No_ AS AncienNo,
       LEFT(No_, 3) + '.' + SUBSTRING(No_, 4, 3) AS NouveauNo,
       Description, Marque
FROM #articles
WHERE Societe = '3S AGENCE'
  AND TypeArticle = 2
  AND Marque LIKE '%MERCEDES%'
  AND LEN(No_) = 6
  AND No_ NOT LIKE '%[^0-9]%'
ORDER BY No_;

/* --- 6. Les sept collisions connues sont-elles toutes couvertes ? ---- */
/*     Si l'une d'elles n'entre pas dans la regle, elle restera en
       collision apres le renommage et devra etre traitee a la main.      */
WITH Collisions AS (
    SELECT No_
    FROM #articles
    GROUP BY No_
    HAVING SUM(CASE WHEN TypeArticle = 2 THEN 1 ELSE 0 END) > 0
       AND SUM(CASE WHEN TypeArticle <> 2 THEN 1 ELSE 0 END) > 0
)
SELECT A.No_ AS Numero,
       A.Societe,
       A.Description,
       A.Marque,
       CASE WHEN A.Societe = '3S AGENCE' AND A.TypeArticle = 2
                 AND A.Marque LIKE '%MERCEDES%'
                 AND LEN(A.No_) = 6 AND A.No_ NOT LIKE '%[^0-9]%'
            THEN 'Couvert par la regle'
            WHEN A.TypeArticle = 2 THEN 'NON couvert, a traiter a la main'
            ELSE 'Piece, ne bouge pas' END AS Traitement
FROM #articles AS A
JOIN Collisions AS C ON C.No_ = A.No_
ORDER BY A.No_, A.Societe;
GO
