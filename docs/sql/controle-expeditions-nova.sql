-- Controle des expeditions de STE COPIM, LECTURE SEULE.
-- Prepare les reponses aux points 1 et 2 de la demande Reapro.
--
-- Resultat 1 : le booleen BS de l'en-tete correspond-il au prefixe du numero ?
-- Resultat 2 : les totaux stockes (FlowFields "Line Amount HT" et "Line Amount" de
--              l'en-tete) sont-ils egaux a ce que recalcule le rapport BL COPIM
--              (report 50235), qui ne lit pas ces champs mais refait le calcul
--              ligne par ligne ?
-- Resultat 3 : dix exemples d'ecart, s'il y en a.
--
-- Regle du rapport 50235, reprise a l'identique :
--   remise    = "% Discount" si BS, sinon "Line Discount %"
--   net HT    = (Unit Price * Quantity) * (1 - remise / 100)
--   net TTC   = net HT * (1 + VAT % / 100)
--
-- Les en-tetes sont materialises avant le calcul des sommes : SQL Server refuse un
-- agregat qui melange une colonne externe et les colonnes de la sous-requete.
--
-- Suffixes : 437dbf0e = Base Application, ad36f199 = SOPICBC16A.

SET NOCOUNT ON;

IF OBJECT_ID('tempdb..#hdr') IS NOT NULL DROP TABLE #hdr;
IF OBJECT_ID('tempdb..#exp') IS NOT NULL DROP TABLE #exp;

-- 1. Les en-tetes, avec leur prefixe et leur booleen BS
SELECT h.[No_] AS DocNo,
       CASE WHEN h.[No_] LIKE 'BS%' THEN 'BS'
            WHEN h.[No_] LIKE 'BL%' THEN 'BL'
            ELSE 'autre' END          AS Prefixe,
       CAST(ISNULL(he.[BS], 0) AS int) AS FlagBS
INTO #hdr
FROM [STE COPIM$Sales Shipment Header$437dbf0e-84ff-417a-965d-ed2bb9650972] h
LEFT JOIN [STE COPIM$Sales Shipment Header$ad36f199-c652-4e8e-9c9a-ca851e424760] he
       ON he.[No_] COLLATE DATABASE_DEFAULT = h.[No_] COLLATE DATABASE_DEFAULT;

-- 2. Les deux calculs, en une seule passe sur les lignes
SELECT hd.DocNo, hd.Prefixe, hd.FlagBS,
       CAST(ISNULL(SUM(le.[Line Amount HT]), 0) AS decimal(38, 5)) AS StockHT,
       CAST(ISNULL(SUM(le.[Line Amount]), 0) AS decimal(38, 5))    AS StockTTC,
       CAST(ISNULL(SUM(
            (l.[Unit Price] * l.[Quantity])
            * (1 - (CASE WHEN hd.FlagBS = 1 THEN ISNULL(le.[_ Discount], 0)
                         ELSE l.[Line Discount _] END) / 100.0)
       ), 0) AS decimal(38, 5))                                    AS RapportHT,
       CAST(ISNULL(SUM(
            (l.[Unit Price] * l.[Quantity])
            * (1 - (CASE WHEN hd.FlagBS = 1 THEN ISNULL(le.[_ Discount], 0)
                         ELSE l.[Line Discount _] END) / 100.0)
            * (1 + l.[VAT _] / 100.0)
       ), 0) AS decimal(38, 5))                                    AS RapportTTC
INTO #exp
FROM #hdr hd
LEFT JOIN [STE COPIM$Sales Shipment Line$437dbf0e-84ff-417a-965d-ed2bb9650972] l
       ON l.[Document No_] COLLATE DATABASE_DEFAULT = hd.DocNo COLLATE DATABASE_DEFAULT
LEFT JOIN [STE COPIM$Sales Shipment Line$ad36f199-c652-4e8e-9c9a-ca851e424760] le
       ON le.[Document No_] COLLATE DATABASE_DEFAULT = l.[Document No_] COLLATE DATABASE_DEFAULT
      AND le.[Line No_] = l.[Line No_]
GROUP BY hd.DocNo, hd.Prefixe, hd.FlagBS;

-- Resultat 1 : le booleen BS colle-t-il au prefixe ?
SELECT Prefixe, FlagBS, COUNT(*) AS Expeditions
FROM #exp
GROUP BY Prefixe, FlagBS
ORDER BY Prefixe, FlagBS;

-- Resultat 2 : ecart entre les totaux stockes et le calcul du rapport
SELECT COUNT(*)                                                         AS Expeditions,
       SUM(CASE WHEN ABS(StockHT - RapportHT) > 0.01 THEN 1 ELSE 0 END)   AS EcartHT,
       SUM(CASE WHEN ABS(StockTTC - RapportTTC) > 0.01 THEN 1 ELSE 0 END) AS EcartTTC,
       CAST(SUM(StockHT) AS decimal(18, 3))                              AS TotalStockHT,
       CAST(SUM(RapportHT) AS decimal(18, 3))                            AS TotalRapportHT,
       CAST(SUM(StockTTC) AS decimal(18, 3))                             AS TotalStockTTC,
       CAST(SUM(RapportTTC) AS decimal(18, 3))                           AS TotalRapportTTC
FROM #exp;

-- Resultat 3 : dix exemples d'ecart
SELECT TOP 10 DocNo, Prefixe, FlagBS,
       CAST(StockHT AS decimal(18, 3))    AS StockHT,
       CAST(RapportHT AS decimal(18, 3))  AS RapportHT,
       CAST(StockTTC AS decimal(18, 3))   AS StockTTC,
       CAST(RapportTTC AS decimal(18, 3)) AS RapportTTC
FROM #exp
WHERE ABS(StockHT - RapportHT) > 0.01 OR ABS(StockTTC - RapportTTC) > 0.01
ORDER BY ABS(StockHT - RapportHT) DESC;

DROP TABLE #hdr;
DROP TABLE #exp;
