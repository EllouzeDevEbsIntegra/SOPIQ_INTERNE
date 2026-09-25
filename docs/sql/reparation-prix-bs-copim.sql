-- Reparation des prix des lignes de BS non facturees de STE COPIM.
-- ECRITURE. A executer hors heures de travail, puis redemarrer l'instance BC160.
--
-- Regle appliquee, celle de l'option "Garder prix initial" :
--   Prix Vente 1         = Unit Price                              (prix d'origine)
--   Prix Vente 2         = Unit Price * (1 - "% Discount" / 100)   (remise d'origine)
--   Montant ligne HT BS  = Prix Vente 2 * Quantity
--   Montant ligne TTC BS = Montant HT * (1 + VAT % / 100)
--   Line Discount %      = "% Discount"   (remise d'origine au lieu du parametrage)
--
-- Perimetre, identique a la simulation validee (14 050 lignes, +394 049 DT) :
--   en-tete BS, ligne de type article, quantite non nulle, non encore facturee,
--   et prix d'origine superieur ou egal au cout.
--
-- Les 10 cas particuliers (prix inferieur au cout) ne sont PAS touches.
--
-- Les valeurs actuelles sont sauvegardees dans dbo.[BACKUP_PrixBS_COPIM] avant
-- toute ecriture. Le script de retour arriere est en bas du fichier.

SET NOCOUNT ON;
SET XACT_ABORT ON;

-- 1. Sauvegarde des valeurs actuelles
IF OBJECT_ID('dbo.BACKUP_PrixBS_COPIM') IS NOT NULL
BEGIN
    PRINT 'La table de sauvegarde existe deja : script deja execute ? Verifier avant de continuer.';
    RETURN;
END

SELECT l.[Document No_]        AS DocNo,
       l.[Line No_]            AS LigneNo,
       l.[Quantity]            AS Qte,
       l.[Unit Cost]           AS Cout,
       l.[Unit Price]          AS PrixOrigine,
       l.[VAT _]               AS TauxTVA,
       l.[Line Discount _]     AS LineDiscountAvant,
       e.[_ Discount]          AS RemiseOrigine,
       e.[Prix Vente 1]        AS PV1Avant,
       e.[Prix Vente 2]        AS PV2Avant,
       e.[Montant ligne HT BS] AS MontantHTAvant,
       e.[Montant ligne TTC BS] AS MontantTTCAvant,
       GETDATE()               AS DateSauvegarde
INTO dbo.BACKUP_PrixBS_COPIM
FROM [STE COPIM$Sales Shipment Line$437dbf0e-84ff-417a-965d-ed2bb9650972] l
JOIN [STE COPIM$Sales Shipment Line$ad36f199-c652-4e8e-9c9a-ca851e424760] e
  ON e.[Document No_] = l.[Document No_] AND e.[Line No_] = l.[Line No_]
JOIN [STE COPIM$Sales Shipment Header$ad36f199-c652-4e8e-9c9a-ca851e424760] he
  ON he.[No_] COLLATE DATABASE_DEFAULT = l.[Document No_] COLLATE DATABASE_DEFAULT
WHERE he.[BS] = 1
  AND l.[Type] = 2
  AND l.[Quantity] <> 0
  AND l.[Quantity Invoiced] = 0
  AND l.[Unit Price] >= l.[Unit Cost];

PRINT 'Lignes sauvegardees : ' + CAST(@@ROWCOUNT AS varchar) + ' (attendu 13441 en production)';

-- 2. Mise a jour, dans une transaction unique
BEGIN TRANSACTION;

UPDATE e
SET e.[Prix Vente 1]         = b.PrixOrigine,
    e.[Prix Vente 2]         = b.PrixOrigine * (1 - ISNULL(b.RemiseOrigine, 0) / 100.0),
    e.[Montant ligne HT BS]  = b.PrixOrigine * (1 - ISNULL(b.RemiseOrigine, 0) / 100.0) * b.Qte,
    e.[Montant ligne TTC BS] = b.PrixOrigine * (1 - ISNULL(b.RemiseOrigine, 0) / 100.0) * b.Qte
                               * (1 + ISNULL(b.TauxTVA, 0) / 100.0)
FROM [STE COPIM$Sales Shipment Line$ad36f199-c652-4e8e-9c9a-ca851e424760] e
JOIN dbo.BACKUP_PrixBS_COPIM b
  ON b.DocNo COLLATE DATABASE_DEFAULT = e.[Document No_] COLLATE DATABASE_DEFAULT
 AND b.LigneNo = e.[Line No_];

PRINT 'Lignes d extension mises a jour : ' + CAST(@@ROWCOUNT AS varchar);

UPDATE l
SET l.[Line Discount _] = ISNULL(b.RemiseOrigine, 0)
FROM [STE COPIM$Sales Shipment Line$437dbf0e-84ff-417a-965d-ed2bb9650972] l
JOIN dbo.BACKUP_PrixBS_COPIM b
  ON b.DocNo COLLATE DATABASE_DEFAULT = l.[Document No_] COLLATE DATABASE_DEFAULT
 AND b.LigneNo = l.[Line No_];

PRINT 'Remises de ligne mises a jour : ' + CAST(@@ROWCOUNT AS varchar);

COMMIT TRANSACTION;

-- 3. Controle apres ecriture
SELECT COUNT(*)                                                      AS LignesReparees,
       SUM(CASE WHEN e.[Prix Vente 1] = 0 THEN 1 ELSE 0 END)         AS ResteAZero,
       CAST(SUM(b.MontantHTAvant) AS decimal(18, 3))                 AS TotalHTAvant,
       CAST(SUM(e.[Montant ligne HT BS]) AS decimal(18, 3))          AS TotalHTApres,
       CAST(SUM(e.[Montant ligne HT BS] - b.MontantHTAvant) AS decimal(18, 3)) AS Ecart
FROM dbo.BACKUP_PrixBS_COPIM b
JOIN [STE COPIM$Sales Shipment Line$ad36f199-c652-4e8e-9c9a-ca851e424760] e
  ON e.[Document No_] COLLATE DATABASE_DEFAULT = b.DocNo COLLATE DATABASE_DEFAULT
 AND e.[Line No_] = b.LigneNo;

-- Attendu en production : 13 441 lignes, un seul reste a zero (ligne dont le prix
-- d'origine est lui-meme nul), ecart proche de +391 422 DT.
-- Pour memoire, sur la base DEV le 25/09/2026 : 14 050 lignes et +394 049 DT.

-- ---------------------------------------------------------------------------
-- RETOUR ARRIERE, a n'executer que si la reparation doit etre annulee :
--
-- BEGIN TRANSACTION;
-- UPDATE e
-- SET e.[Prix Vente 1] = b.PV1Avant, e.[Prix Vente 2] = b.PV2Avant,
--     e.[Montant ligne HT BS] = b.MontantHTAvant, e.[Montant ligne TTC BS] = b.MontantTTCAvant
-- FROM [STE COPIM$Sales Shipment Line$ad36f199-c652-4e8e-9c9a-ca851e424760] e
-- JOIN dbo.BACKUP_PrixBS_COPIM b
--   ON b.DocNo COLLATE DATABASE_DEFAULT = e.[Document No_] COLLATE DATABASE_DEFAULT
--  AND b.LigneNo = e.[Line No_];
-- UPDATE l
-- SET l.[Line Discount _] = b.LineDiscountAvant
-- FROM [STE COPIM$Sales Shipment Line$437dbf0e-84ff-417a-965d-ed2bb9650972] l
-- JOIN dbo.BACKUP_PrixBS_COPIM b
--   ON b.DocNo COLLATE DATABASE_DEFAULT = l.[Document No_] COLLATE DATABASE_DEFAULT
--  AND b.LigneNo = l.[Line No_];
-- COMMIT TRANSACTION;
-- ---------------------------------------------------------------------------
