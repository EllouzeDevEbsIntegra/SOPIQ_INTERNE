/* =====================================================================
   Essai : accélérer les colonnes « Facture et Avoir Ouverts » et
   « Nombre de facture non payée » de l'administration des clients.

   Le probleme. Ces deux colonnes somment et comptent les ecritures client
   detaillees avec le filtre `STOuvert = filter('Oui')`. Or STOuvert n'est
   pas une colonne : c'est un champ calcule de l'extension StandardTunisien
   qui va chercher `Open` sur l'ecriture client. Pour chaque client
   affiche, le serveur parcourt donc ses ecritures detaillees et interroge
   l'ecriture client de chacune.

   L'idee. Un index sur les ecritures detaillees par client et type de
   document, embarquant le montant et le lien vers l'ecriture client. Rien
   ne change dans le code ni dans les chiffres affiches.

   Sur DEV, societe SOPIQ PROD. Bloc par bloc, en lisant l'onglet Messages.
   ===================================================================== */

USE SOPIQ_DEV;
GO

SET STATISTICS IO ON;
SET STATISTICS TIME ON;
GO

/* ---------------------------------------------------------------------
   BLOC 1 : la situation actuelle, pour les cinquante premiers clients.
   Relever les lectures logiques sur les deux tables d'ecritures.
   --------------------------------------------------------------------- */
SELECT C.[No_] AS Client,
       ISNULL(SUM(D.[Amount (LCY)]), 0) AS FactureEtAvoirOuverts,
       COUNT(D.[Entry No_]) AS NbEcritures
FROM (SELECT TOP 50 [No_]
      FROM [SOPIQ PROD$Customer$437dbf0e-84ff-417a-965d-ed2bb9650972]
      ORDER BY [No_]) AS C
LEFT JOIN [SOPIQ PROD$Detailed Cust_ Ledg_ Entry$437dbf0e-84ff-417a-965d-ed2bb9650972] AS D
    ON  D.[Customer No_] = C.[No_]
    AND D.[Document Type] IN (2, 3)
LEFT JOIN [SOPIQ PROD$Cust_ Ledger Entry$437dbf0e-84ff-417a-965d-ed2bb9650972] AS E
    ON  E.[Entry No_] = D.[Cust_ Ledger Entry No_]
    AND E.[Open] = 1
WHERE E.[Entry No_] IS NOT NULL
GROUP BY C.[No_];
GO

/* ---------------------------------------------------------------------
   BLOC 2 : l'index. Seule ecriture de ce script.

   Hors ligne, donc la table des ecritures detaillees est brievement
   verrouillee. C'est une grosse table : lancer en heure creuse.
   --------------------------------------------------------------------- */
CREATE NONCLUSTERED INDEX IDX_PERF_DetCustLedg_CustDocType
    ON [SOPIQ PROD$Detailed Cust_ Ledg_ Entry$437dbf0e-84ff-417a-965d-ed2bb9650972]
       ([Customer No_], [Document Type])
    INCLUDE ([Amount (LCY)], [Cust_ Ledger Entry No_])
    WITH (DATA_COMPRESSION = PAGE);
GO

/* ---------------------------------------------------------------------
   BLOC 3 : la meme mesure, avec l'index. Les valeurs doivent etre
   identiques client par client.
   --------------------------------------------------------------------- */
SELECT C.[No_] AS Client,
       ISNULL(SUM(D.[Amount (LCY)]), 0) AS FactureEtAvoirOuverts,
       COUNT(D.[Entry No_]) AS NbEcritures
FROM (SELECT TOP 50 [No_]
      FROM [SOPIQ PROD$Customer$437dbf0e-84ff-417a-965d-ed2bb9650972]
      ORDER BY [No_]) AS C
LEFT JOIN [SOPIQ PROD$Detailed Cust_ Ledg_ Entry$437dbf0e-84ff-417a-965d-ed2bb9650972] AS D
    ON  D.[Customer No_] = C.[No_]
    AND D.[Document Type] IN (2, 3)
LEFT JOIN [SOPIQ PROD$Cust_ Ledger Entry$437dbf0e-84ff-417a-965d-ed2bb9650972] AS E
    ON  E.[Entry No_] = D.[Cust_ Ledger Entry No_]
    AND E.[Open] = 1
WHERE E.[Entry No_] IS NOT NULL
GROUP BY C.[No_];
GO

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
GO

/* ---------------------------------------------------------------------
   BLOC 4 : RETOUR ARRIERE.
   --------------------------------------------------------------------- */
-- DROP INDEX IDX_PERF_DetCustLedg_CustDocType
--     ON [SOPIQ PROD$Detailed Cust_ Ledg_ Entry$437dbf0e-84ff-417a-965d-ed2bb9650972];
-- GO
