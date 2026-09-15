-- Controle COPIM, janvier 2026, lecture seule.
-- A executer dans SSMS sur la base DEV (base de la societe STE COPIM).
--
-- A utiliser si les totaux des queries API COPIM (25006662 a 25006665) ne tombent pas
-- juste : il recalcule le meme CA directement en SQL, source par source.
--
-- Resultat 1 : CA par source avec les filtres du Power BI. Les colonnes *Ile mesurent
--              ce qu'aurait donne une jointure "Item Ledger Entry" (Document No. +
--              Document Line No.), ecartee de la V1.
-- Resultat 2 : doublon possible entre BS archives et lignes de facture.
--
-- Suffixes des tables : 437dbf0e... = Base Application, ad36f199... = SOPICBC16A
-- (table "Ligne archive BS" et champs ajoutes "Old Document", Amount des retours).

SET NOCOUNT ON;

DECLARE @d1 date = '2026-01-01';
DECLARE @d2 date = '2026-01-31';

IF OBJECT_ID('tempdb..#src') IS NOT NULL DROP TABLE #src;
CREATE TABLE #src (
    Source   varchar(20),
    DocNo    nvarchar(20),
    LigneNo  int,
    ArticleNo nvarchar(20),
    Montant  decimal(38, 20),
    Entete   int,           -- 1 si l'entete existe (jointure des queries du Power BI)
    NbIle    int,           -- nombre d'ecritures article liees
    Lien     nvarchar(20)   -- BS : "No. BL" ; facture : "Old Document"
);

-- BS archives : Line Amount HT, Quantity <> 0, No. <> 'ACR', client <> 41000900
INSERT #src
SELECT 'BS archive', l.[Document No_], l.[Line No_], l.[No_], l.[Line Amount HT],
       CASE WHEN EXISTS (SELECT 1 FROM [STE COPIM$Entete archive BS$ad36f199-c652-4e8e-9c9a-ca851e424760] h
                         WHERE h.[No_] = l.[Document No_]) THEN 1 ELSE 0 END,
       (SELECT COUNT(*) FROM [STE COPIM$Item Ledger Entry$437dbf0e-84ff-417a-965d-ed2bb9650972] i
        WHERE i.[Document No_] = l.[Document No_] AND i.[Document Line No_] = l.[Line No_]),
       l.[No_ BL]
FROM [STE COPIM$Ligne archive BS$ad36f199-c652-4e8e-9c9a-ca851e424760] l
WHERE l.[Posting Date] BETWEEN @d1 AND @d2
  AND l.[Quantity] <> 0 AND l.[No_] <> 'ACR' AND l.[Sell-to Customer No_] <> '41000900';

-- Factures : Line Amount, No. <> '', No. <> 'ACR', client <> 41000901
INSERT #src
SELECT 'Facture', l.[Document No_], l.[Line No_], l.[No_], l.[Line Amount],
       CASE WHEN EXISTS (SELECT 1 FROM [STE COPIM$Sales Invoice Header$437dbf0e-84ff-417a-965d-ed2bb9650972] h
                         WHERE h.[No_] = l.[Document No_]) THEN 1 ELSE 0 END,
       (SELECT COUNT(*) FROM [STE COPIM$Item Ledger Entry$437dbf0e-84ff-417a-965d-ed2bb9650972] i
        WHERE i.[Document No_] = l.[Document No_] AND i.[Document Line No_] = l.[Line No_]),
       e.[Old Document]
FROM [STE COPIM$Sales Invoice Line$437dbf0e-84ff-417a-965d-ed2bb9650972] l
LEFT JOIN [STE COPIM$Sales Invoice Line$ad36f199-c652-4e8e-9c9a-ca851e424760] e
       ON e.[Document No_] = l.[Document No_] AND e.[Line No_] = l.[Line No_]
WHERE l.[Posting Date] BETWEEN @d1 AND @d2
  AND l.[No_] <> '' AND l.[No_] <> 'ACR' AND l.[Sell-to Customer No_] <> '41000901';

-- Avoirs : Line Amount, No. <> ''
INSERT #src
SELECT 'Avoir', l.[Document No_], l.[Line No_], l.[No_], l.[Line Amount],
       CASE WHEN EXISTS (SELECT 1 FROM [STE COPIM$Sales Cr_Memo Header$437dbf0e-84ff-417a-965d-ed2bb9650972] h
                         WHERE h.[No_] = l.[Document No_]) THEN 1 ELSE 0 END,
       (SELECT COUNT(*) FROM [STE COPIM$Item Ledger Entry$437dbf0e-84ff-417a-965d-ed2bb9650972] i
        WHERE i.[Document No_] = l.[Document No_] AND i.[Document Line No_] = l.[Line No_]),
       NULL
FROM [STE COPIM$Sales Cr_Memo Line$437dbf0e-84ff-417a-965d-ed2bb9650972] l
WHERE l.[Posting Date] BETWEEN @d1 AND @d2
  AND l.[No_] <> '';

-- Retours BS : Amount, No. <> '', exclusion de 6 clients
INSERT #src
SELECT 'Retour BS', l.[Document No_], l.[Line No_], l.[No_], e.[Amount],
       CASE WHEN EXISTS (SELECT 1 FROM [STE COPIM$Return Receipt Header$437dbf0e-84ff-417a-965d-ed2bb9650972] h
                         WHERE h.[No_] = l.[Document No_]) THEN 1 ELSE 0 END,
       (SELECT COUNT(*) FROM [STE COPIM$Item Ledger Entry$437dbf0e-84ff-417a-965d-ed2bb9650972] i
        WHERE i.[Document No_] = l.[Document No_] AND i.[Document Line No_] = l.[Line No_]),
       NULL
FROM [STE COPIM$Return Receipt Line$437dbf0e-84ff-417a-965d-ed2bb9650972] l
LEFT JOIN [STE COPIM$Return Receipt Line$ad36f199-c652-4e8e-9c9a-ca851e424760] e
       ON e.[Document No_] = l.[Document No_] AND e.[Line No_] = l.[Line No_]
WHERE l.[Posting Date] BETWEEN @d1 AND @d2
  AND l.[No_] <> ''
  AND l.[Sell-to Customer No_] NOT IN ('41000980', '41000900', '41000901', '41000981', '41000982', '41000242');

-- Resultat 1
SELECT Source,
       COUNT(*)                                                  AS Lignes,
       CAST(SUM(Montant) AS decimal(18, 3))                      AS Montant,
       SUM(CASE WHEN Entete = 0 THEN 1 ELSE 0 END)               AS LignesSansEntete,
       SUM(CASE WHEN NbIle = 0 THEN 1 ELSE 0 END)                AS LignesSansIle,
       CAST(SUM(CASE WHEN NbIle = 0 THEN Montant ELSE 0 END) AS decimal(18, 3)) AS MontantSansIle,
       SUM(CASE WHEN NbIle > 1 THEN 1 ELSE 0 END)                AS LignesPlusieursIle,
       CAST(SUM(Montant * NbIle) AS decimal(18, 3))              AS MontantAvecJointure
FROM #src
GROUP BY Source
UNION ALL
SELECT 'CA COPIM',
       COUNT(*),
       CAST(SUM(CASE WHEN Source IN ('BS archive', 'Facture') THEN Montant ELSE -Montant END) AS decimal(18, 3)),
       NULL, NULL, NULL, NULL, NULL
FROM #src;

-- Resultat 2 : doublon BS archive / facture
SELECT 'Factures jan. avec Old Document renseigne' AS Controle,
       COUNT(*) AS Lignes, CAST(SUM(Montant) AS decimal(18, 3)) AS Montant
FROM #src WHERE Source = 'Facture' AND ISNULL(Lien, '') <> ''
UNION ALL
SELECT 'Factures jan. dont Old Document est un BS archive',
       COUNT(*), CAST(SUM(s.Montant) AS decimal(18, 3))
FROM #src s
WHERE s.Source = 'Facture'
  AND EXISTS (SELECT 1 FROM [STE COPIM$Ligne archive BS$ad36f199-c652-4e8e-9c9a-ca851e424760] b
              WHERE b.[Document No_] = s.Lien)
UNION ALL
SELECT 'BS jan. avec facture liee (Old Document + No., toute date)',
       COUNT(*), CAST(SUM(s.Montant) AS decimal(18, 3))
FROM #src s
WHERE s.Source = 'BS archive'
  AND EXISTS (SELECT 1
              FROM [STE COPIM$Sales Invoice Line$ad36f199-c652-4e8e-9c9a-ca851e424760] e
              JOIN [STE COPIM$Sales Invoice Line$437dbf0e-84ff-417a-965d-ed2bb9650972] i
                ON i.[Document No_] = e.[Document No_] AND i.[Line No_] = e.[Line No_]
              WHERE e.[Old Document] = s.DocNo AND i.[No_] = s.ArticleNo)
UNION ALL
SELECT 'BS jan. avec No. BL renseigne',
       COUNT(*), CAST(SUM(Montant) AS decimal(18, 3))
FROM #src WHERE Source = 'BS archive' AND ISNULL(Lien, '') <> ''
UNION ALL
SELECT 'BS jan. dont le No. BL est facture (Shipment No. + No.)',
       COUNT(*), CAST(SUM(s.Montant) AS decimal(18, 3))
FROM #src s
WHERE s.Source = 'BS archive' AND ISNULL(s.Lien, '') <> ''
  AND EXISTS (SELECT 1 FROM [STE COPIM$Sales Invoice Line$437dbf0e-84ff-417a-965d-ed2bb9650972] i
              WHERE i.[Shipment No_] = s.Lien AND i.[No_] = s.ArticleNo);

DROP TABLE #src;
