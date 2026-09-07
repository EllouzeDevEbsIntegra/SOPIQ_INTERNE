-- La portee du compteur de tickets devient un reglage a part entiere.
--
-- Jusqu'ici elle n'existait nulle part : le compteur repartait a 1 des que le prefixe
-- IMPRIME changeait. Un format portant l'annee remettait donc a zero chaque 1er janvier,
-- qu'on le veuille ou non, et on ne pouvait pas remettre a zero chaque jour sans ecrire
-- la date sur le ticket. Trois reglages disent maintenant ce qui n'etait que devine.
--
-- Ils sont deduits du format DEJA en place sur cette base, et non des valeurs livrees :
-- une caisse qui numerote {SEQ:6} tout court ne doit pas se reveiller avec une remise a
-- zero annuelle qu'elle n'a jamais demandee. Le comportement d'hier est donc reconduit
-- tel quel, et c'est l'exploitant qui le changera s'il le souhaite.
--
-- Le compteur lui-meme n'est pas touche : sa cle change de forme, mais un compteur neuf
-- demarre au-dessus du plus grand numero deja imprime sous la meme forme (voir
-- TicketNumberService). La numerotation se poursuit donc sans trou ni doublon.

INSERT INTO app_setting (setting_key, setting_value, updated_at)
SELECT 'ticket.resetPeriod',
       CASE WHEN p LIKE '%{DD}%' AND p LIKE '%{MM}%' AND (p LIKE '%{YYYY}%' OR p LIKE '%{YY}%') THEN 'DAILY'
            WHEN p LIKE '%{MM}%' AND (p LIKE '%{YYYY}%' OR p LIKE '%{YY}%')                     THEN 'MONTHLY'
            WHEN p LIKE '%{YYYY}%' OR p LIKE '%{YY}%'                                           THEN 'YEARLY'
            ELSE 'NONE' END,
       now()
FROM (SELECT COALESCE((SELECT setting_value FROM app_setting WHERE setting_key = 'ticket.pattern'),
                      '{POS}-{YYYY}-{SEQ:6}') AS p) t
ON CONFLICT (setting_key) DO NOTHING;

INSERT INTO app_setting (setting_key, setting_value, updated_at)
SELECT 'ticket.perPos', CASE WHEN p LIKE '%{POS}%' THEN 'true' ELSE 'false' END, now()
FROM (SELECT COALESCE((SELECT setting_value FROM app_setting WHERE setting_key = 'ticket.pattern'),
                      '{POS}-{YYYY}-{SEQ:6}') AS p) t
ON CONFLICT (setting_key) DO NOTHING;

INSERT INTO app_setting (setting_key, setting_value, updated_at)
SELECT 'ticket.perRegister', CASE WHEN p LIKE '%{REG}%' THEN 'true' ELSE 'false' END, now()
FROM (SELECT COALESCE((SELECT setting_value FROM app_setting WHERE setting_key = 'ticket.pattern'),
                      '{POS}-{YYYY}-{SEQ:6}') AS p) t
ON CONFLICT (setting_key) DO NOTHING;

-- Le format lui-meme est desormais toujours ecrit, meme quand il vaut celui d'origine :
-- les trois reglages ci-dessus s'y accrochent, et un format reste implicite serait
-- silencieusement remplace le jour ou la valeur livree changerait.
INSERT INTO app_setting (setting_key, setting_value, updated_at)
VALUES ('ticket.pattern', '{POS}-{YYYY}-{SEQ:6}', now())
ON CONFLICT (setting_key) DO NOTHING;

-- Une cle de compteur porte maintenant les composantes de la portee separees par « | »
-- (PV01|2026), la ou elle recopiait le prefixe imprime (PV01-2026-#). VARCHAR(80) suffit
-- toujours, mais un code de point de vente et un code de caisse tiennent desormais dans
-- la meme cle : on met a l'aise.
ALTER TABLE document_sequence ALTER COLUMN scope_key TYPE VARCHAR(120);
