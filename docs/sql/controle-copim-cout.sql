-- Controle COPIM avant les queries de cout, janvier 2026, lecture seule.
-- A executer dans SSMS sur la base DEV (base de la societe STE COPIM).
--
-- Perimetre : exactement les lignes retenues pour le CA (memes filtres et exclusions
-- que le Power BI et que le controle controle-copim.sql).
--
-- Resultat 1 : taux de remplissage des champs de liaison et taux de lignes pour
--              lesquelles une ecriture valeur est trouvee, selon chaque cle possible.
--              PctLignes et PctMontant sont rapportes au total de la source.
-- Resultat 2 : sur les BS archives, vers quoi pointe "Old Document".
-- Resultat 3 : exemples de lignes de BS archives (transformees et avec Old Document).
--
-- Collation : COLLATE DATABASE_DEFAULT des deux cotes de chaque comparaison de texte.

SET NOCOUNT ON;

DECLARE @d1 date = '20260101';
DECLARE @d2 date = '20260131';

IF OBJECT_ID('tempdb..#bs') IS NOT NULL DROP TABLE #bs;
IF OBJECT_ID('tempdb..#fv') IS NOT NULL DROP TABLE #fv;
IF OBJECT_ID('tempdb..#av') IS NOT NULL DROP TABLE #av;
IF OBJECT_ID('tempdb..#rbs') IS NOT NULL DROP TABLE #rbs;
IF OBJECT_ID('tempdb..#c') IS NOT NULL DROP TABLE #c;

CREATE TABLE #c (Source varchar(30), Ordre int, Controle varchar(80), Ok int, Montant decimal(38, 20));

------------------------------------------------------------------------------------------
-- BS archives
------------------------------------------------------------------------------------------
SELECT l.[Document No_] AS DocNo, l.[Line No_] AS LigneNo, l.[Type] AS TypeLigne,
       l.[Line Amount HT] AS Montant, l.[No_ BL] AS NoBL, l.[Old Document] AS OldDoc,
       l.[Item Shpt_ Entry No_] AS IleNo,
       (SELECT MAX(CAST(h.[BS] AS int)) FROM [STE COPIM$Entete archive BS$ad36f199-c652-4e8e-9c9a-ca851e424760] h
        WHERE h.[No_] COLLATE DATABASE_DEFAULT = l.[Document No_] COLLATE DATABASE_DEFAULT) AS EnteteBS
INTO #bs
FROM [STE COPIM$Ligne archive BS$ad36f199-c652-4e8e-9c9a-ca851e424760] l
WHERE l.[Posting Date] BETWEEN @d1 AND @d2
  AND l.[Quantity] <> 0
  AND l.[No_] COLLATE DATABASE_DEFAULT <> 'ACR' COLLATE DATABASE_DEFAULT
  AND l.[Sell-to Customer No_] COLLATE DATABASE_DEFAULT <> '41000900' COLLATE DATABASE_DEFAULT;

INSERT #c
SELECT 'BS archive (tout)', v.Ordre, v.Controle, v.Ok, b.Montant
FROM #bs b
CROSS APPLY (VALUES
    (1, 'Type = Article', CASE WHEN b.TypeLigne = 2 THEN 1 ELSE 0 END),
    (2, 'No. BL renseigne (ligne transformee)', CASE WHEN ISNULL(b.NoBL, '') COLLATE DATABASE_DEFAULT <> '' COLLATE DATABASE_DEFAULT THEN 1 ELSE 0 END),
    (3, 'Old Document renseigne', CASE WHEN ISNULL(b.OldDoc, '') COLLATE DATABASE_DEFAULT <> '' COLLATE DATABASE_DEFAULT THEN 1 ELSE 0 END),
    (4, 'Entete archive BS avec BS = oui', CASE WHEN b.EnteteBS = 1 THEN 1 ELSE 0 END),
    (5, 'Entete archive BS avec BS = non', CASE WHEN b.EnteteBS = 0 THEN 1 ELSE 0 END),
    (6, 'Entete archive BS absent', CASE WHEN b.EnteteBS IS NULL THEN 1 ELSE 0 END),
    (7, 'Item Shpt. Entry No. renseigne', CASE WHEN b.IleNo <> 0 THEN 1 ELSE 0 END),
    (8, 'Item Shpt. Entry No. partage avec une autre ligne',
        CASE WHEN b.IleNo <> 0 AND (SELECT COUNT(*) FROM #bs x WHERE x.IleNo = b.IleNo) > 1 THEN 1 ELSE 0 END)
) v(Ordre, Controle, Ok);

INSERT #c
SELECT CASE WHEN ISNULL(b.NoBL, '') COLLATE DATABASE_DEFAULT = '' COLLATE DATABASE_DEFAULT
            THEN 'BS non transforme' ELSE 'BS transforme' END,
       v.Ordre, v.Controle, v.Ok, b.Montant
FROM #bs b
CROSS APPLY (VALUES
    (10, 'Ecriture article trouvee par Item Shpt. Entry No.',
        CASE WHEN EXISTS (SELECT 1 FROM [STE COPIM$Item Ledger Entry$437dbf0e-84ff-417a-965d-ed2bb9650972] i
                          WHERE i.[Entry No_] = b.IleNo) THEN 1 ELSE 0 END),
    (11, '... et cette ecriture article porte le n du BS',
        CASE WHEN EXISTS (SELECT 1 FROM [STE COPIM$Item Ledger Entry$437dbf0e-84ff-417a-965d-ed2bb9650972] i
                          WHERE i.[Entry No_] = b.IleNo
                            AND i.[Document No_] COLLATE DATABASE_DEFAULT = b.DocNo COLLATE DATABASE_DEFAULT) THEN 1 ELSE 0 END),
    (12, '... et cette ecriture article porte le n du BL',
        CASE WHEN EXISTS (SELECT 1 FROM [STE COPIM$Item Ledger Entry$437dbf0e-84ff-417a-965d-ed2bb9650972] i
                          WHERE i.[Entry No_] = b.IleNo
                            AND i.[Document No_] COLLATE DATABASE_DEFAULT = b.NoBL COLLATE DATABASE_DEFAULT) THEN 1 ELSE 0 END),
    (13, '... et son Document Line No. = n ligne du BS',
        CASE WHEN EXISTS (SELECT 1 FROM [STE COPIM$Item Ledger Entry$437dbf0e-84ff-417a-965d-ed2bb9650972] i
                          WHERE i.[Entry No_] = b.IleNo AND i.[Document Line No_] = b.LigneNo) THEN 1 ELSE 0 END),
    (20, 'VE trouvee par Item Ledger Entry No. = Item Shpt. Entry No.',
        CASE WHEN EXISTS (SELECT 1 FROM [STE COPIM$Value Entry$437dbf0e-84ff-417a-965d-ed2bb9650972] ve
                          WHERE ve.[Item Ledger Entry No_] = b.IleNo AND b.IleNo <> 0) THEN 1 ELSE 0 END),
    (21, 'VE trouvee par n BS + n ligne BS',
        CASE WHEN EXISTS (SELECT 1 FROM [STE COPIM$Value Entry$437dbf0e-84ff-417a-965d-ed2bb9650972] ve
                          WHERE ve.[Document No_] COLLATE DATABASE_DEFAULT = b.DocNo COLLATE DATABASE_DEFAULT
                            AND ve.[Document Line No_] = b.LigneNo) THEN 1 ELSE 0 END),
    (22, 'VE trouvee par n BL + n ligne BS',
        CASE WHEN EXISTS (SELECT 1 FROM [STE COPIM$Value Entry$437dbf0e-84ff-417a-965d-ed2bb9650972] ve
                          WHERE ve.[Document No_] COLLATE DATABASE_DEFAULT = b.NoBL COLLATE DATABASE_DEFAULT
                            AND ve.[Document Line No_] = b.LigneNo) THEN 1 ELSE 0 END),
    (23, 'Ligne BL trouvee (n BL + Item Shpt. Entry No.)',
        CASE WHEN EXISTS (SELECT 1 FROM [STE COPIM$Sales Shipment Line$437dbf0e-84ff-417a-965d-ed2bb9650972] s
                          WHERE s.[Document No_] COLLATE DATABASE_DEFAULT = b.NoBL COLLATE DATABASE_DEFAULT
                            AND s.[Item Shpt_ Entry No_] = b.IleNo AND b.IleNo <> 0) THEN 1 ELSE 0 END),
    (24, 'VE trouvee par n BL + n ligne BL retrouvee',
        CASE WHEN EXISTS (SELECT 1
                          FROM [STE COPIM$Sales Shipment Line$437dbf0e-84ff-417a-965d-ed2bb9650972] s
                          JOIN [STE COPIM$Value Entry$437dbf0e-84ff-417a-965d-ed2bb9650972] ve
                            ON ve.[Document No_] COLLATE DATABASE_DEFAULT = s.[Document No_] COLLATE DATABASE_DEFAULT
                           AND ve.[Document Line No_] = s.[Line No_]
                          WHERE s.[Document No_] COLLATE DATABASE_DEFAULT = b.NoBL COLLATE DATABASE_DEFAULT
                            AND s.[Item Shpt_ Entry No_] = b.IleNo AND b.IleNo <> 0) THEN 1 ELSE 0 END)
) v(Ordre, Controle, Ok);

------------------------------------------------------------------------------------------
-- Factures
------------------------------------------------------------------------------------------
SELECT l.[Document No_] AS DocNo, l.[Line No_] AS LigneNo, l.[Type] AS TypeLigne, l.[Line Amount] AS Montant,
       l.[Shipment No_] AS ShipNo, l.[Shipment Line No_] AS ShipLigne, e.[Old Document] AS OldDoc
INTO #fv
FROM [STE COPIM$Sales Invoice Line$437dbf0e-84ff-417a-965d-ed2bb9650972] l
LEFT JOIN [STE COPIM$Sales Invoice Line$ad36f199-c652-4e8e-9c9a-ca851e424760] e
       ON e.[Document No_] COLLATE DATABASE_DEFAULT = l.[Document No_] COLLATE DATABASE_DEFAULT
      AND e.[Line No_] = l.[Line No_]
WHERE l.[Posting Date] BETWEEN @d1 AND @d2
  AND l.[No_] COLLATE DATABASE_DEFAULT <> '' COLLATE DATABASE_DEFAULT
  AND l.[No_] COLLATE DATABASE_DEFAULT <> 'ACR' COLLATE DATABASE_DEFAULT
  AND l.[Sell-to Customer No_] COLLATE DATABASE_DEFAULT <> '41000901' COLLATE DATABASE_DEFAULT;

INSERT #c
SELECT 'Facture', v.Ordre, v.Controle, v.Ok, f.Montant
FROM #fv f
CROSS APPLY (VALUES
    (1, 'Type = Article', CASE WHEN f.TypeLigne = 2 THEN 1 ELSE 0 END),
    (2, 'Shipment No. renseigne', CASE WHEN ISNULL(f.ShipNo, '') COLLATE DATABASE_DEFAULT <> '' COLLATE DATABASE_DEFAULT THEN 1 ELSE 0 END),
    (3, 'Shipment Line No. renseigne', CASE WHEN f.ShipLigne <> 0 THEN 1 ELSE 0 END),
    (4, 'Old Document renseigne', CASE WHEN ISNULL(f.OldDoc, '') COLLATE DATABASE_DEFAULT <> '' COLLATE DATABASE_DEFAULT THEN 1 ELSE 0 END),
    (10, 'Ligne BL trouvee (Shipment No. + Shipment Line No.)',
        CASE WHEN EXISTS (SELECT 1 FROM [STE COPIM$Sales Shipment Line$437dbf0e-84ff-417a-965d-ed2bb9650972] s
                          WHERE s.[Document No_] COLLATE DATABASE_DEFAULT = f.ShipNo COLLATE DATABASE_DEFAULT
                            AND s.[Line No_] = f.ShipLigne) THEN 1 ELSE 0 END),
    (11, '... avec Item Shpt. Entry No. renseigne',
        CASE WHEN EXISTS (SELECT 1 FROM [STE COPIM$Sales Shipment Line$437dbf0e-84ff-417a-965d-ed2bb9650972] s
                          WHERE s.[Document No_] COLLATE DATABASE_DEFAULT = f.ShipNo COLLATE DATABASE_DEFAULT
                            AND s.[Line No_] = f.ShipLigne AND s.[Item Shpt_ Entry No_] <> 0) THEN 1 ELSE 0 END),
    (20, 'VE trouvee par Item Shpt. Entry No. de la ligne BL',
        CASE WHEN EXISTS (SELECT 1
                          FROM [STE COPIM$Sales Shipment Line$437dbf0e-84ff-417a-965d-ed2bb9650972] s
                          JOIN [STE COPIM$Value Entry$437dbf0e-84ff-417a-965d-ed2bb9650972] ve
                            ON ve.[Item Ledger Entry No_] = s.[Item Shpt_ Entry No_]
                          WHERE s.[Document No_] COLLATE DATABASE_DEFAULT = f.ShipNo COLLATE DATABASE_DEFAULT
                            AND s.[Line No_] = f.ShipLigne AND s.[Item Shpt_ Entry No_] <> 0) THEN 1 ELSE 0 END),
    (21, 'VE trouvee par Shipment No. + Shipment Line No.',
        CASE WHEN EXISTS (SELECT 1 FROM [STE COPIM$Value Entry$437dbf0e-84ff-417a-965d-ed2bb9650972] ve
                          WHERE ve.[Document No_] COLLATE DATABASE_DEFAULT = f.ShipNo COLLATE DATABASE_DEFAULT
                            AND ve.[Document Line No_] = f.ShipLigne) THEN 1 ELSE 0 END),
    (22, 'VE trouvee par n facture + n ligne facture',
        CASE WHEN EXISTS (SELECT 1 FROM [STE COPIM$Value Entry$437dbf0e-84ff-417a-965d-ed2bb9650972] ve
                          WHERE ve.[Document No_] COLLATE DATABASE_DEFAULT = f.DocNo COLLATE DATABASE_DEFAULT
                            AND ve.[Document Line No_] = f.LigneNo) THEN 1 ELSE 0 END)
) v(Ordre, Controle, Ok);

------------------------------------------------------------------------------------------
-- Avoirs
------------------------------------------------------------------------------------------
SELECT l.[Document No_] AS DocNo, l.[Line No_] AS LigneNo, l.[Type] AS TypeLigne, l.[Line Amount] AS Montant,
       l.[Return Receipt No_] AS RcptNo, l.[Return Receipt Line No_] AS RcptLigne
INTO #av
FROM [STE COPIM$Sales Cr_Memo Line$437dbf0e-84ff-417a-965d-ed2bb9650972] l
WHERE l.[Posting Date] BETWEEN @d1 AND @d2
  AND l.[No_] COLLATE DATABASE_DEFAULT <> '' COLLATE DATABASE_DEFAULT;

INSERT #c
SELECT 'Avoir', v.Ordre, v.Controle, v.Ok, a.Montant
FROM #av a
CROSS APPLY (VALUES
    (1, 'Type = Article', CASE WHEN a.TypeLigne = 2 THEN 1 ELSE 0 END),
    (2, 'Return Receipt No. renseigne', CASE WHEN ISNULL(a.RcptNo, '') COLLATE DATABASE_DEFAULT <> '' COLLATE DATABASE_DEFAULT THEN 1 ELSE 0 END),
    (3, 'Return Receipt Line No. renseigne', CASE WHEN a.RcptLigne <> 0 THEN 1 ELSE 0 END),
    (10, 'Ligne reception retour trouvee',
        CASE WHEN EXISTS (SELECT 1 FROM [STE COPIM$Return Receipt Line$437dbf0e-84ff-417a-965d-ed2bb9650972] r
                          WHERE r.[Document No_] COLLATE DATABASE_DEFAULT = a.RcptNo COLLATE DATABASE_DEFAULT
                            AND r.[Line No_] = a.RcptLigne) THEN 1 ELSE 0 END),
    (20, 'VE trouvee par Item Rcpt. Entry No. de la ligne reception',
        CASE WHEN EXISTS (SELECT 1
                          FROM [STE COPIM$Return Receipt Line$437dbf0e-84ff-417a-965d-ed2bb9650972] r
                          JOIN [STE COPIM$Value Entry$437dbf0e-84ff-417a-965d-ed2bb9650972] ve
                            ON ve.[Item Ledger Entry No_] = r.[Item Rcpt_ Entry No_]
                          WHERE r.[Document No_] COLLATE DATABASE_DEFAULT = a.RcptNo COLLATE DATABASE_DEFAULT
                            AND r.[Line No_] = a.RcptLigne AND r.[Item Rcpt_ Entry No_] <> 0) THEN 1 ELSE 0 END),
    (21, 'VE trouvee par Return Receipt No. + Line No.',
        CASE WHEN EXISTS (SELECT 1 FROM [STE COPIM$Value Entry$437dbf0e-84ff-417a-965d-ed2bb9650972] ve
                          WHERE ve.[Document No_] COLLATE DATABASE_DEFAULT = a.RcptNo COLLATE DATABASE_DEFAULT
                            AND ve.[Document Line No_] = a.RcptLigne) THEN 1 ELSE 0 END),
    (22, 'VE trouvee par n avoir + n ligne avoir',
        CASE WHEN EXISTS (SELECT 1 FROM [STE COPIM$Value Entry$437dbf0e-84ff-417a-965d-ed2bb9650972] ve
                          WHERE ve.[Document No_] COLLATE DATABASE_DEFAULT = a.DocNo COLLATE DATABASE_DEFAULT
                            AND ve.[Document Line No_] = a.LigneNo) THEN 1 ELSE 0 END)
) v(Ordre, Controle, Ok);

------------------------------------------------------------------------------------------
-- Retours BS
------------------------------------------------------------------------------------------
SELECT l.[Document No_] AS DocNo, l.[Line No_] AS LigneNo, l.[Type] AS TypeLigne, ISNULL(e.[Amount], 0) AS Montant,
       l.[Item Rcpt_ Entry No_] AS IleNo
INTO #rbs
FROM [STE COPIM$Return Receipt Line$437dbf0e-84ff-417a-965d-ed2bb9650972] l
LEFT JOIN [STE COPIM$Return Receipt Line$ad36f199-c652-4e8e-9c9a-ca851e424760] e
       ON e.[Document No_] COLLATE DATABASE_DEFAULT = l.[Document No_] COLLATE DATABASE_DEFAULT
      AND e.[Line No_] = l.[Line No_]
WHERE l.[Posting Date] BETWEEN @d1 AND @d2
  AND l.[No_] COLLATE DATABASE_DEFAULT <> '' COLLATE DATABASE_DEFAULT
  AND l.[Sell-to Customer No_] COLLATE DATABASE_DEFAULT NOT IN (
        '41000980' COLLATE DATABASE_DEFAULT, '41000900' COLLATE DATABASE_DEFAULT,
        '41000901' COLLATE DATABASE_DEFAULT, '41000981' COLLATE DATABASE_DEFAULT,
        '41000982' COLLATE DATABASE_DEFAULT, '41000242' COLLATE DATABASE_DEFAULT);

INSERT #c
SELECT 'Retour BS', v.Ordre, v.Controle, v.Ok, r.Montant
FROM #rbs r
CROSS APPLY (VALUES
    (1, 'Type = Article', CASE WHEN r.TypeLigne = 2 THEN 1 ELSE 0 END),
    (2, 'Item Rcpt. Entry No. renseigne', CASE WHEN r.IleNo <> 0 THEN 1 ELSE 0 END),
    (20, 'VE trouvee par Item Ledger Entry No. = Item Rcpt. Entry No.',
        CASE WHEN EXISTS (SELECT 1 FROM [STE COPIM$Value Entry$437dbf0e-84ff-417a-965d-ed2bb9650972] ve
                          WHERE ve.[Item Ledger Entry No_] = r.IleNo AND r.IleNo <> 0) THEN 1 ELSE 0 END),
    (21, 'VE trouvee par n retour + n ligne retour',
        CASE WHEN EXISTS (SELECT 1 FROM [STE COPIM$Value Entry$437dbf0e-84ff-417a-965d-ed2bb9650972] ve
                          WHERE ve.[Document No_] COLLATE DATABASE_DEFAULT = r.DocNo COLLATE DATABASE_DEFAULT
                            AND ve.[Document Line No_] = r.LigneNo) THEN 1 ELSE 0 END)
) v(Ordre, Controle, Ok);

------------------------------------------------------------------------------------------
-- Resultat 1 : taux par source
------------------------------------------------------------------------------------------
SELECT c.Source, c.Ordre, c.Controle,
       SUM(c.Ok)                                                         AS LignesOk,
       COUNT(*)                                                          AS LignesSource,
       CAST(100.0 * SUM(c.Ok) / NULLIF(COUNT(*), 0) AS decimal(5, 1))    AS PctLignes,
       CAST(SUM(c.Montant * c.Ok) AS decimal(18, 3))                     AS MontantOk,
       CAST(SUM(c.Montant) AS decimal(18, 3))                            AS MontantSource,
       CAST(100.0 * SUM(c.Montant * c.Ok) / NULLIF(SUM(c.Montant), 0) AS decimal(5, 1)) AS PctMontant
FROM #c c
GROUP BY c.Source, c.Ordre, c.Controle
ORDER BY c.Source, c.Ordre;

------------------------------------------------------------------------------------------
-- Resultat 2 : BS archives, cible de "Old Document"
------------------------------------------------------------------------------------------
SELECT Cible, COUNT(*) AS Lignes, CAST(SUM(Montant) AS decimal(18, 3)) AS Montant
FROM (
    SELECT b.Montant,
           CASE
             WHEN EXISTS (SELECT 1 FROM [STE COPIM$Entete archive BS$ad36f199-c652-4e8e-9c9a-ca851e424760] h
                          WHERE h.[No_] COLLATE DATABASE_DEFAULT = b.OldDoc COLLATE DATABASE_DEFAULT) THEN 'un autre BS archive'
             WHEN EXISTS (SELECT 1 FROM [STE COPIM$Sales Shipment Header$437dbf0e-84ff-417a-965d-ed2bb9650972] h
                          WHERE h.[No_] COLLATE DATABASE_DEFAULT = b.OldDoc COLLATE DATABASE_DEFAULT) THEN 'une expedition (BL)'
             WHEN EXISTS (SELECT 1 FROM [STE COPIM$Sales Invoice Header$437dbf0e-84ff-417a-965d-ed2bb9650972] h
                          WHERE h.[No_] COLLATE DATABASE_DEFAULT = b.OldDoc COLLATE DATABASE_DEFAULT) THEN 'une facture'
             WHEN EXISTS (SELECT 1 FROM [STE COPIM$Sales Header$437dbf0e-84ff-417a-965d-ed2bb9650972] h
                          WHERE h.[No_] COLLATE DATABASE_DEFAULT = b.OldDoc COLLATE DATABASE_DEFAULT) THEN 'un document vente en cours'
             ELSE 'introuvable'
           END AS Cible
    FROM #bs b
    WHERE ISNULL(b.OldDoc, '') COLLATE DATABASE_DEFAULT <> '' COLLATE DATABASE_DEFAULT
) t
GROUP BY Cible;

------------------------------------------------------------------------------------------
-- Resultat 3 : exemples
------------------------------------------------------------------------------------------
SELECT TOP 10 'transformee' AS Cas, b.DocNo, b.LigneNo, b.NoBL, b.OldDoc, b.IleNo, b.EnteteBS, b.Montant
FROM #bs b
WHERE ISNULL(b.NoBL, '') COLLATE DATABASE_DEFAULT <> '' COLLATE DATABASE_DEFAULT
UNION ALL
SELECT TOP 10 'old document', b.DocNo, b.LigneNo, b.NoBL, b.OldDoc, b.IleNo, b.EnteteBS, b.Montant
FROM #bs b
WHERE ISNULL(b.OldDoc, '') COLLATE DATABASE_DEFAULT <> '' COLLATE DATABASE_DEFAULT;

DROP TABLE #bs;
DROP TABLE #fv;
DROP TABLE #av;
DROP TABLE #rbs;
DROP TABLE #c;
