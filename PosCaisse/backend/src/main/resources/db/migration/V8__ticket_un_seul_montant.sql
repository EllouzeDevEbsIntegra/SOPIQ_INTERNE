-- Un seul montant par ligne de ticket : on eteint « Prix unitaire » la ou il etait allume.
--
-- Le ticket imprimait, sous le total d'une ligne, le prix unitaire et le prix des
-- supplements. Aligne dans la meme colonne, cela se lit comme une addition : un client
-- a compte 7,000 + 3,000 = 10,000 alors que les 7,000 contenaient deja le supplement
-- a 3,000. Les montants des supplements disparaissent par le code (ce n'etait pas un
-- reglage) ; le prix unitaire, lui, reste un reglage - il sert quand un client conteste
-- « pourquoi 8,000 pour deux » - mais il ne doit plus etre allume sans avoir ete demande.
--
-- Les installations neuves partent deja a NON (ReceiptRenderer.defaultConfig). Cette
-- migration ne concerne donc que les caisses deja en service, ou le reglage a ete
-- ecrit en base a l'installation. Un gerant qui le veut le rallume en un clic dans
-- Back-office > Impression.
UPDATE receipt_template
   SET config_json = regexp_replace(config_json, '"showUnitPrice"\s*:\s*true', '"showUnitPrice":false')
 WHERE config_json ~ '"showUnitPrice"\s*:\s*true';
