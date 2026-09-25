-- Reparation des cas particuliers ecartes le 25/09/2026, STE COPIM.
-- ECRITURE. A executer hors heures de travail, puis redemarrer l'instance BC160.
--
-- Ces 10 lignes avaient ete laissees de cote parce que leur prix d'origine est
-- inferieur au cout de la ligne. Le controle des BS archives a montre que leur
-- colonne "Line Amount HT" porte exactement le montant calcule a partir du prix
-- d'origine : l'archive confirme donc ce prix, et le prix calcule depuis le cout
-- est une valeur posterieure, parfois absurde (fut d'huile a 4 086 DT le litre,
-- cout au fut contre quantite au litre).
--
-- Regle appliquee, la meme que la reparation principale :
--   Prix Vente 1         = Unit Price
--   Prix Vente 2         = Unit Price * (1 - "% Discount" / 100)
--   Montant ligne HT BS  = Prix Vente 2 * Quantity
--   Montant ligne TTC BS = Montant HT * (1 + VAT % / 100)
--   Line Discount %      = "% Discount"
--
-- Exclusion : la ligne dont le prix d'origine est nul (BS25-5276 ligne 30000).
-- Aucune source ne permet de la reconstituer, elle doit etre saisie dans BC.
--
-- Attendu : 10 lignes, montant total passant d'environ 1 719 489 a 13 869 DT.

SET NOCOUNT ON;
SET XACT_ABORT ON;

IF OBJECT_ID('dbo.BACKUP_PrixBS_COPIM_CasPart') IS NOT NULL
BEGIN
    PRINT 'La table de sauvegarde existe deja : script deja execute ? Verifier avant de continuer.';
    RETURN;
END

SELECT l.[Document No_]         AS DocNo,
       l.[Line No_]             AS LigneNo,
       l.[Quantity]             AS Qte,
       l.[Unit Cost]            AS Cout,
       l.[Unit Price]           AS PrixOrigine,
       l.[VAT _]                AS TauxTVA,
       l.[Line Discount _]      AS LineDiscountAvant,
       e.[_ Discount]           AS RemiseOrigine,
       e.[Prix Vente 1]         AS PV1Avant,
       e.[Prix Vente 2]         AS PV2Avant,
       e.[Montant ligne HT BS]  AS MontantHTAvant,
       e.[Montant ligne TTC BS] AS MontantTTCAvant,
       GETDATE()                AS DateSauvegarde
INTO dbo.BACKUP_PrixBS_COPIM_CasPart
FROM [STE COPIM$Sales Shipment Line$437dbf0e-84ff-417a-965d-ed2bb9650972] l
JOIN [STE COPIM$Sales Shipment Line$ad36f199-c652-4e8e-9c9a-ca851e424760] e
  ON e.[Document No_] = l.[Document No_] AND e.[Line No_] = l.[Line No_]
JOIN [STE COPIM$Sales Shipment Header$ad36f199-c652-4e8e-9c9a-ca851e424760] he
  ON he.[No_] COLLATE DATABASE_DEFAULT = l.[Document No_] COLLATE DATABASE_DEFAULT
WHERE he.[BS] = 1
  AND l.[Type] = 2
  AND l.[Quantity] <> 0
  AND l.[Quantity Invoiced] = 0
  AND l.[Unit Price] < l.[Unit Cost]
  AND l.[Unit Price] > 0;

PRINT 'Lignes sauvegardees : ' + CAST(@@ROWCOUNT AS varchar) + ' (attendu 10)';

BEGIN TRANSACTION;

UPDATE e
SET e.[Prix Vente 1]         = b.PrixOrigine,
    e.[Prix Vente 2]         = b.PrixOrigine * (1 - ISNULL(b.RemiseOrigine, 0) / 100.0),
    e.[Montant ligne HT BS]  = b.PrixOrigine * (1 - ISNULL(b.RemiseOrigine, 0) / 100.0) * b.Qte,
    e.[Montant ligne TTC BS] = b.PrixOrigine * (1 - ISNULL(b.RemiseOrigine, 0) / 100.0) * b.Qte
                               * (1 + ISNULL(b.TauxTVA, 0) / 100.0)
FROM [STE COPIM$Sales Shipment Line$ad36f199-c652-4e8e-9c9a-ca851e424760] e
JOIN dbo.BACKUP_PrixBS_COPIM_CasPart b
  ON b.DocNo COLLATE DATABASE_DEFAULT = e.[Document No_] COLLATE DATABASE_DEFAULT
 AND b.LigneNo = e.[Line No_];

PRINT 'Lignes d extension mises a jour : ' + CAST(@@ROWCOUNT AS varchar);

UPDATE l
SET l.[Line Discount _] = ISNULL(b.RemiseOrigine, 0)
FROM [STE COPIM$Sales Shipment Line$437dbf0e-84ff-417a-965d-ed2bb9650972] l
JOIN dbo.BACKUP_PrixBS_COPIM_CasPart b
  ON b.DocNo COLLATE DATABASE_DEFAULT = l.[Document No_] COLLATE DATABASE_DEFAULT
 AND b.LigneNo = l.[Line No_];

PRINT 'Remises de ligne mises a jour : ' + CAST(@@ROWCOUNT AS varchar);

COMMIT TRANSACTION;

-- Controle : comparaison avec le montant porte par le BS archive
SELECT b.DocNo, b.LigneNo,
       CAST(b.MontantHTAvant AS decimal(18, 3))          AS MontantAvant,
       CAST(e.[Montant ligne HT BS] AS decimal(18, 3))   AS MontantApres,
       CAST(a.[Line Amount HT] AS decimal(18, 3))        AS MontantArchive
FROM dbo.BACKUP_PrixBS_COPIM_CasPart b
JOIN [STE COPIM$Sales Shipment Line$ad36f199-c652-4e8e-9c9a-ca851e424760] e
  ON e.[Document No_] COLLATE DATABASE_DEFAULT = b.DocNo COLLATE DATABASE_DEFAULT
 AND e.[Line No_] = b.LigneNo
LEFT JOIN [STE COPIM$Ligne archive BS$ad36f199-c652-4e8e-9c9a-ca851e424760] a
  ON a.[Document No_] COLLATE DATABASE_DEFAULT = b.DocNo COLLATE DATABASE_DEFAULT
 AND a.[Line No_] = b.LigneNo
ORDER BY ABS(b.MontantHTAvant) DESC;

-- MontantApres doit etre egal a MontantArchive sur les dix lignes.

-- ---------------------------------------------------------------------------
-- RETOUR ARRIERE :
--
-- BEGIN TRANSACTION;
-- UPDATE e
-- SET e.[Prix Vente 1] = b.PV1Avant, e.[Prix Vente 2] = b.PV2Avant,
--     e.[Montant ligne HT BS] = b.MontantHTAvant, e.[Montant ligne TTC BS] = b.MontantTTCAvant
-- FROM [STE COPIM$Sales Shipment Line$ad36f199-c652-4e8e-9c9a-ca851e424760] e
-- JOIN dbo.BACKUP_PrixBS_COPIM_CasPart b
--   ON b.DocNo COLLATE DATABASE_DEFAULT = e.[Document No_] COLLATE DATABASE_DEFAULT
--  AND b.LigneNo = e.[Line No_];
-- UPDATE l
-- SET l.[Line Discount _] = b.LineDiscountAvant
-- FROM [STE COPIM$Sales Shipment Line$437dbf0e-84ff-417a-965d-ed2bb9650972] l
-- JOIN dbo.BACKUP_PrixBS_COPIM_CasPart b
--   ON b.DocNo COLLATE DATABASE_DEFAULT = l.[Document No_] COLLATE DATABASE_DEFAULT
--  AND b.LigneNo = l.[Line No_];
-- COMMIT TRANSACTION;
-- ---------------------------------------------------------------------------
