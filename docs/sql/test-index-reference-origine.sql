/* =====================================================================
   Test de l'index sur [Reference Origine Lié], sur SOPIQ_DEV.

   Ce que reproduit ce script : la requete que les applications externes
   envoient des milliers de fois par jour a la vue ELVA_Item,

       SELECT count(*) FROM ELVA_ITEM WHERE [Reference Origine Lié] = @P0

   mesuree le 26/09/2026 a 20 514 executions, 14 527 pages lues chacune,
   924 secondes cumulees. La vue de production lit SOPIQ_PROD_BC16 ; ici
   on la rejoue a l'identique sur SOPIQ_DEV, qui porte les memes tables
   pour la societe SOPIQ PROD.

   Deroulement : on mesure, on cree l'index, on remesure, et on decide de
   la production avec les deux chiffres sous les yeux. L'index se retire
   en une commande, donnee a la fin.

   ATTENTION : SOPIQ_DEV et SOPIQ_PROD_BC16 sont sur la meme instance
   SQL. Le BLOC 4, qui rejoue un chargement complet du catalogue, prend
   plusieurs dizaines de secondes et pese sur le serveur : a reserver a
   une periode creuse, il est facultatif.
   ===================================================================== */

USE SOPIQ_DEV;
GO

SET NOCOUNT ON;
GO

/* ---------------------------------------------------------------------
   BLOC 1 : choisir une reference de test, representative.
   --------------------------------------------------------------------- */
DECLARE @Ref nvarchar(100);

SELECT TOP 1 @Ref = IX.[Reference Origine Lié]
FROM dbo.[SOPIQ PROD$Item$ad36f199-c652-4e8e-9c9a-ca851e424760] AS IX
WHERE IX.[Reference Origine Lié] <> ''
GROUP BY IX.[Reference Origine Lié]
HAVING COUNT(*) BETWEEN 2 AND 20
ORDER BY COUNT(*) DESC;

SELECT
    @Ref AS ReferenceDeTest,
    (SELECT COUNT(*)
     FROM dbo.[SOPIQ PROD$Item$ad36f199-c652-4e8e-9c9a-ca851e424760] AS IX
     WHERE IX.[Reference Origine Lié] = @Ref) AS NbArticlesPortantCetteReference,
    (SELECT COUNT(*)
     FROM dbo.[SOPIQ PROD$Item$ad36f199-c652-4e8e-9c9a-ca851e424760]) AS NbArticlesDansLaTable;

/*  Noter la reference affichee : elle sert aux blocs suivants.
    La recopier ci-dessous, a la place de la valeur d'exemple.           */
GO

/* ---------------------------------------------------------------------
   BLOC 2 : la mesure AVANT index.

   Remplacer la valeur de @Ref par celle du bloc 1, puis executer.
   Lire l'onglet Messages : c'est la que SQL annonce le nombre de
   lectures logiques, seul chiffre qui compte ici. Le temps en
   millisecondes depend de ce que fait le serveur au meme moment.
   --------------------------------------------------------------------- */
DECLARE @Ref nvarchar(100) = N'A REMPLACER';

SET STATISTICS IO ON;
SET STATISTICS TIME ON;

SELECT COUNT(*) AS NbLignes
FROM dbo.[SOPIQ PROD$Item$437dbf0e-84ff-417a-965d-ed2bb9650972] AS I
INNER JOIN dbo.[SOPIQ PROD$Item$ad36f199-c652-4e8e-9c9a-ca851e424760] AS IX
    ON IX.No_ = I.No_
INNER JOIN dbo.[SOPIQ PROD$Manufacturer$437dbf0e-84ff-417a-965d-ed2bb9650972] AS M
    ON M.Code = I.[Manufacturer Code]
INNER JOIN dbo.[SOPIQ PROD$Manufacturer$ad36f199-c652-4e8e-9c9a-ca851e424760] AS MX
    ON MX.Code = M.Code
WHERE I.Type IN (0, 1)
  AND M.Code NOT IN ('FAB0278', 'FAB0281')
  AND IX.[Reference Origine Lié] = @Ref;

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
GO

/* ---------------------------------------------------------------------
   BLOC 3 : creation de l'index, sur SOPIQ_DEV uniquement.

   Cet index ne fait pas partie du modele Business Central. Une
   synchronisation d'extension peut le supprimer ; il suffit de relancer
   ce bloc. Prefixe IDX_PERF_, comme les index de la liste articles.
   --------------------------------------------------------------------- */
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = 'IDX_PERF_ItemExt_RefOrigine'
      AND object_id = OBJECT_ID('dbo.[SOPIQ PROD$Item$ad36f199-c652-4e8e-9c9a-ca851e424760]'))
BEGIN
    DECLARE @debut datetime = GETDATE();

    /*  Une seule colonne de cle, aucune colonne incluse : on ne devine pas
        les besoins des autres requetes, on repond a celle qu'on a mesuree.
        Un index etroit coute moins cher a maintenir a chaque ecriture.    */
    CREATE NONCLUSTERED INDEX IDX_PERF_ItemExt_RefOrigine
        ON dbo.[SOPIQ PROD$Item$ad36f199-c652-4e8e-9c9a-ca851e424760] ([Reference Origine Lié]);

    PRINT 'Index cree en ' + CAST(DATEDIFF(SECOND, @debut, GETDATE()) AS varchar) + ' secondes.';
END
ELSE
    PRINT 'Index deja present, rien a faire.';
GO

/* ---------------------------------------------------------------------
   BLOC 4 : la mesure APRES index. Meme requete, meme reference.
   --------------------------------------------------------------------- */
DECLARE @Ref nvarchar(100) = N'A REMPLACER';

SET STATISTICS IO ON;
SET STATISTICS TIME ON;

SELECT COUNT(*) AS NbLignes
FROM dbo.[SOPIQ PROD$Item$437dbf0e-84ff-417a-965d-ed2bb9650972] AS I
INNER JOIN dbo.[SOPIQ PROD$Item$ad36f199-c652-4e8e-9c9a-ca851e424760] AS IX
    ON IX.No_ = I.No_
INNER JOIN dbo.[SOPIQ PROD$Manufacturer$437dbf0e-84ff-417a-965d-ed2bb9650972] AS M
    ON M.Code = I.[Manufacturer Code]
INNER JOIN dbo.[SOPIQ PROD$Manufacturer$ad36f199-c652-4e8e-9c9a-ca851e424760] AS MX
    ON MX.Code = M.Code
WHERE I.Type IN (0, 1)
  AND M.Code NOT IN ('FAB0278', 'FAB0281')
  AND IX.[Reference Origine Lié] = @Ref;

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
GO

/* ---------------------------------------------------------------------
   BLOC 5, FACULTATIF : le chargement complet du catalogue.

   C'est la requete a 2 345 522 pages et 34 a 81 secondes, celle que
   l'application rejoue 257 fois. Elle reproduit la vue entiere, avec ses
   trois agregats par article. A ne lancer qu'en periode creuse : la
   production partage le meme serveur.

   L'index du bloc 3 n'y changera rien, c'est attendu : ici le cout vient
   des trois OUTER APPLY, pas du filtre. Ce bloc sert a chiffrer le
   deuxieme chantier, pas a valider le premier.
   --------------------------------------------------------------------- */
/*
SET STATISTICS IO ON;
SET STATISTICS TIME ON;

SELECT COUNT(*) AS NbLignes, SUM(CAST(X.Quantité AS bigint)) AS SommeControle
FROM (
    SELECT ILE.Qty - ISNULL(REC.Qty, 0) - ISNULL(RES.QtyHors37, 0) AS Quantité
    FROM dbo.[SOPIQ PROD$Item$437dbf0e-84ff-417a-965d-ed2bb9650972] AS I
    INNER JOIN dbo.[SOPIQ PROD$Item$ad36f199-c652-4e8e-9c9a-ca851e424760] AS IX
        ON IX.No_ = I.No_
    INNER JOIN dbo.[SOPIQ PROD$Manufacturer$437dbf0e-84ff-417a-965d-ed2bb9650972] AS M
        ON M.Code = I.[Manufacturer Code]
    INNER JOIN dbo.[SOPIQ PROD$Manufacturer$ad36f199-c652-4e8e-9c9a-ca851e424760] AS MX
        ON MX.Code = M.Code
    OUTER APPLY (
        SELECT SUM(E.Quantity) AS Qty
        FROM dbo.[SOPIQ PROD$Item Ledger Entry$437dbf0e-84ff-417a-965d-ed2bb9650972] AS E
        WHERE E.[Item No_] = I.No_
          AND E.[Location Code] NOT IN ('IMPORT', 'LITIGE', 'RESERVER')) AS ILE
    OUTER APPLY (
        SELECT SUM(W.Quantity) AS Qty
        FROM dbo.[SOPIQ PROD$Warehouse Entry$437dbf0e-84ff-417a-965d-ed2bb9650972] AS W
        WHERE W.[Item No_] = I.No_
          AND W.[Location Code] = 'CENTRAL'
          AND W.[Bin Code] = 'RECEPTION') AS REC
    OUTER APPLY (
        SELECT SUM(CASE WHEN R.[Source Type] <> 37 THEN R.Quantity END) AS QtyHors37
        FROM dbo.[SOPIQ PROD$Reservation Entry$437dbf0e-84ff-417a-965d-ed2bb9650972] AS R
        WHERE R.[Item No_] = I.No_) AS RES
    WHERE I.Type IN (0, 1)
      AND M.Code NOT IN ('FAB0278', 'FAB0281')
) AS X;

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
*/
GO

/* ---------------------------------------------------------------------
   Retrait de l'index, si l'on veut revenir en arriere.
   --------------------------------------------------------------------- */
/*
DROP INDEX IDX_PERF_ItemExt_RefOrigine
    ON dbo.[SOPIQ PROD$Item$ad36f199-c652-4e8e-9c9a-ca851e424760];
*/
