-- Simulation, LECTURE SEULE : effet de la reparation des prix des lignes de BS
-- non encore facturees de STE COPIM.
--
-- Regle simulee, celle de l'option "Garder prix initial" :
--   Prix Vente 1        = Unit Price de la ligne (prix d'origine)
--   Prix Vente 2        = Unit Price * (1 - "% Discount" / 100)   (remise d'origine)
--   Montant ligne HT BS = Prix Vente 2 * Quantity
--
-- Aucune ecriture. Le but est de mesurer combien de lignes changent et de combien,
-- avant de decider d'appliquer.
--
-- Suffixes : 437dbf0e = Base Application, ad36f199 = SOPICBC16A.

SET NOCOUNT ON;

IF OBJECT_ID('tempdb..#sim') IS NOT NULL DROP TABLE #sim;

SELECT l.[Document No_]                                   AS DocNo,
       l.[Line No_]                                       AS LigneNo,
       l.[Quantity]                                       AS Qte,
       l.[Quantity Invoiced]                              AS QteFacturee,
       l.[Unit Cost]                                      AS Cout,
       l.[Unit Price]                                     AS PrixOrigine,
       e.[_ Discount]                                     AS RemiseOrigine,
       l.[Line Discount _]                                AS RemiseActuelle,
       e.[Prix Vente 1]                                   AS PV1Actuel,
       e.[Prix Vente 2]                                   AS PV2Actuel,
       e.[Montant ligne HT BS]                            AS MontantHTActuel,
       CAST(l.[Unit Price] AS decimal(38, 10))            AS PV1Cible,
       CAST(l.[Unit Price] * (1 - ISNULL(e.[_ Discount], 0) / 100.0) AS decimal(38, 10)) AS PV2Cible,
       CAST(l.[Unit Price] * (1 - ISNULL(e.[_ Discount], 0) / 100.0) * l.[Quantity] AS decimal(38, 10)) AS MontantHTCible
INTO #sim
FROM [STE COPIM$Sales Shipment Line$437dbf0e-84ff-417a-965d-ed2bb9650972] l
JOIN [STE COPIM$Sales Shipment Line$ad36f199-c652-4e8e-9c9a-ca851e424760] e
  ON e.[Document No_] = l.[Document No_] AND e.[Line No_] = l.[Line No_]
JOIN [STE COPIM$Sales Shipment Header$ad36f199-c652-4e8e-9c9a-ca851e424760] he
  ON he.[No_] COLLATE DATABASE_DEFAULT = l.[Document No_] COLLATE DATABASE_DEFAULT
WHERE he.[BS] = 1
  AND l.[Type] = 2
  AND l.[Quantity] <> 0
  AND l.[Quantity Invoiced] = 0;   -- non encore facturees

-- Resultat 1 : volumetrie et effet global
SELECT COUNT(*)                                                             AS LignesNonFacturees,
       SUM(CASE WHEN PV1Actuel = 0 THEN 1 ELSE 0 END)                       AS DontPrixCalculeNul,
       SUM(CASE WHEN ABS(PV2Actuel - PV2Cible) > 0.001 THEN 1 ELSE 0 END)   AS LignesQuiChangent,
       CAST(SUM(MontantHTActuel) AS decimal(18, 3))                         AS TotalHTActuel,
       CAST(SUM(MontantHTCible) AS decimal(18, 3))                          AS TotalHTCible,
       CAST(SUM(MontantHTCible - MontantHTActuel) AS decimal(18, 3))        AS Ecart
FROM #sim;

-- Resultat 2 : repartition du changement, a la hausse ou a la baisse
SELECT CASE WHEN PV1Actuel = 0 THEN 'prix calcule nul'
            WHEN PV2Cible > PV2Actuel THEN 'prix en hausse'
            WHEN PV2Cible < PV2Actuel THEN 'prix en baisse'
            ELSE 'inchange' END                              AS Cas,
       COUNT(*)                                              AS Lignes,
       CAST(SUM(MontantHTCible - MontantHTActuel) AS decimal(18, 3)) AS Ecart
FROM #sim
GROUP BY CASE WHEN PV1Actuel = 0 THEN 'prix calcule nul'
              WHEN PV2Cible > PV2Actuel THEN 'prix en hausse'
              WHEN PV2Cible < PV2Actuel THEN 'prix en baisse'
              ELSE 'inchange' END
ORDER BY Lignes DESC;

-- Resultat 3 : dix exemples parmi les ecarts les plus importants
SELECT TOP 10 DocNo, LigneNo, Qte, Cout, PrixOrigine, RemiseOrigine, RemiseActuelle,
       CAST(PV2Actuel AS decimal(18, 3))       AS PV2Actuel,
       CAST(PV2Cible AS decimal(18, 3))        AS PV2Cible,
       CAST(MontantHTActuel AS decimal(18, 3)) AS MontantHTActuel,
       CAST(MontantHTCible AS decimal(18, 3))  AS MontantHTCible
FROM #sim
ORDER BY ABS(MontantHTCible - MontantHTActuel) DESC;

DROP TABLE #sim;
