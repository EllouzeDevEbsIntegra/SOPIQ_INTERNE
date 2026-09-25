-- Simulation 2, LECTURE SEULE : reparation des prix des lignes de BS non facturees
-- de STE COPIM, en ecartant les cas particuliers.
--
-- Regle appliquee (option "Garder prix initial") :
--   Prix Vente 1        = Unit Price       (prix d'origine de la ligne)
--   Prix Vente 2        = Unit Price * (1 - "% Discount" / 100)
--   Line Discount %     = "% Discount"     (remise d'origine, au lieu du parametrage)
--   Montant ligne HT BS = Prix Vente 2 * Quantity
--   Montant ligne TTC BS = Montant HT * (1 + VAT % / 100)
--
-- Cas particuliers EXCLUS de la reparation, a analyser separement :
--   Unit Price < Unit Cost, c'est-a-dire un prix d'origine qui ne couvre pas le cout.
--   Ce critere attrape les ventes a perte et les couts aberrants (unite de mesure
--   incoherente entre le cout et la quantite).
--
-- Suffixes : 437dbf0e = Base Application, ad36f199 = SOPICBC16A.

SET NOCOUNT ON;

IF OBJECT_ID('tempdb..#sim') IS NOT NULL DROP TABLE #sim;

SELECT l.[Document No_]                        AS DocNo,
       l.[Line No_]                            AS LigneNo,
       l.[No_]                                 AS Article,
       l.[Quantity]                            AS Qte,
       l.[Unit Cost]                           AS Cout,
       l.[Unit Price]                          AS PrixOrigine,
       ISNULL(e.[_ Discount], 0)               AS RemiseOrigine,
       e.[Prix Vente 1]                        AS PV1Actuel,
       e.[Prix Vente 2]                        AS PV2Actuel,
       e.[Montant ligne HT BS]                 AS MontantHTActuel,
       CAST(l.[Unit Price] * (1 - ISNULL(e.[_ Discount], 0) / 100.0) * l.[Quantity]
            AS decimal(38, 10))                AS MontantHTCible,
       CASE WHEN l.[Unit Price] < l.[Unit Cost] THEN 1 ELSE 0 END AS CasParticulier
INTO #sim
FROM [STE COPIM$Sales Shipment Line$437dbf0e-84ff-417a-965d-ed2bb9650972] l
JOIN [STE COPIM$Sales Shipment Line$ad36f199-c652-4e8e-9c9a-ca851e424760] e
  ON e.[Document No_] = l.[Document No_] AND e.[Line No_] = l.[Line No_]
JOIN [STE COPIM$Sales Shipment Header$ad36f199-c652-4e8e-9c9a-ca851e424760] he
  ON he.[No_] COLLATE DATABASE_DEFAULT = l.[Document No_] COLLATE DATABASE_DEFAULT
WHERE he.[BS] = 1
  AND l.[Type] = 2
  AND l.[Quantity] <> 0
  AND l.[Quantity Invoiced] = 0;

-- Resultat 1 : ce qui sera repare, et ce qui sera mis de cote
SELECT CASE CasParticulier WHEN 1 THEN 'Cas particulier, non touche' ELSE 'A reparer' END AS Population,
       COUNT(*)                                                      AS Lignes,
       SUM(CASE WHEN PV1Actuel = 0 THEN 1 ELSE 0 END)                AS DontPrixCalculeNul,
       CAST(SUM(MontantHTActuel) AS decimal(18, 3))                  AS TotalHTActuel,
       CAST(SUM(MontantHTCible) AS decimal(18, 3))                   AS TotalHTCible,
       CAST(SUM(MontantHTCible - MontantHTActuel) AS decimal(18, 3)) AS Ecart
FROM #sim
GROUP BY CasParticulier;

-- Resultat 2 : sens du changement, sur la seule population a reparer
SELECT CASE WHEN PV1Actuel = 0 THEN 'prix calcule nul'
            WHEN MontantHTCible > MontantHTActuel THEN 'prix en hausse'
            WHEN MontantHTCible < MontantHTActuel THEN 'prix en baisse'
            ELSE 'inchange' END                                      AS Cas,
       COUNT(*)                                                      AS Lignes,
       CAST(SUM(MontantHTCible - MontantHTActuel) AS decimal(18, 3)) AS Ecart
FROM #sim
WHERE CasParticulier = 0
GROUP BY CASE WHEN PV1Actuel = 0 THEN 'prix calcule nul'
              WHEN MontantHTCible > MontantHTActuel THEN 'prix en hausse'
              WHEN MontantHTCible < MontantHTActuel THEN 'prix en baisse'
              ELSE 'inchange' END
ORDER BY Lignes DESC;

-- Resultat 3 : les cas particuliers les plus lourds, pour la discussion a part
SELECT TOP 15 DocNo, LigneNo, Article, Qte,
       CAST(Cout AS decimal(18, 3))            AS Cout,
       CAST(PrixOrigine AS decimal(18, 3))     AS PrixOrigine,
       CAST(MontantHTActuel AS decimal(18, 3)) AS MontantHTActuel,
       CAST(MontantHTCible AS decimal(18, 3))  AS MontantHTCible
FROM #sim
WHERE CasParticulier = 1
ORDER BY ABS(MontantHTCible - MontantHTActuel) DESC;

DROP TABLE #sim;
