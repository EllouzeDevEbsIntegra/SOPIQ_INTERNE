-- Controle de la prevention des prix de BS, LECTURE SEULE.
-- A executer sur SOPIQ_PROD_BC16 quelques jours apres le 25/09/2026.
--
-- Contexte : la codeunit 50033 "Prix BS Validation" (version 1.0.2.0, deployee en
-- production le 25/09/2026) reprend le prix d'origine sur les lignes de BS quand le
-- parametre "Garder prix initial" est actif ou quand le cout de la ligne est nul.
--
-- Attendu : EncoreAZero = 0. Toute valeur superieure signale un chemin non couvert
-- par le correctif, a signaler.

SELECT COUNT(*)                                              AS LignesBSDepuisLeCorrectif,
       SUM(CASE WHEN e.[Prix Vente 1] = 0 THEN 1 ELSE 0 END) AS EncoreAZero,
       SUM(CASE WHEN l.[Unit Cost] = 0 THEN 1 ELSE 0 END)    AS DontCoutNul,
       MIN(l.[Posting Date])                                 AS PremiereLigne,
       MAX(l.[Posting Date])                                 AS DerniereLigne
FROM [STE COPIM$Sales Shipment Line$437dbf0e-84ff-417a-965d-ed2bb9650972] l
JOIN [STE COPIM$Sales Shipment Line$ad36f199-c652-4e8e-9c9a-ca851e424760] e
  ON e.[Document No_] = l.[Document No_] AND e.[Line No_] = l.[Line No_]
JOIN [STE COPIM$Sales Shipment Header$ad36f199-c652-4e8e-9c9a-ca851e424760] he
  ON he.[No_] COLLATE DATABASE_DEFAULT = l.[Document No_] COLLATE DATABASE_DEFAULT
WHERE he.[BS] = 1
  AND l.[Type] = 2
  AND l.[Quantity] <> 0
  -- Date sans tirets : sur un serveur en francais, la forme avec tirets est lue
  -- en annee-jour-mois et provoque une erreur de conversion.
  AND l.[Posting Date] >= '20260925';
