# Vérification du rapport Antigravity — 10/09/2026

Ce document n'est pas un audit : c'est la **relecture d'un audit**. Chaque affirmation du
rapport d'Antigravity a été rouverte dans le code, ligne par ligne. Il sert de moitié à la
fusion avec le rapport de Codex, attendu.

Un rapport d'agent ne se prend pas au mot. Celui-ci a trouvé quatre défauts réels que nos
133 tests ne voyaient pas — c'est beaucoup —, en a inventé un, en a signalé un corrigé la
veille, et affirme en conclusion que ses tests sont dans le dépôt alors qu'aucun n'y est.

## Ce qui est confirmé

| # | Défaut | Où |
|---|---|---|
| 1.2 | **L'adresse comptée par le ralentisseur est celle que l'attaquant écrit** | `backend/…/service/AuthService.java` |
| 1.1 | Un jeton reste valable après la révocation du compte | `plateforme/…/security/JwtFiltre.java` |
| 1.3 | Le prix d'achat part dans le catalogue de chaque caissier | `backend/…/service/Mappers.java` |
| 1.4 | Le mot de passe d'une démo est lisible dans `ps` | `deploiement/preparer-demos.sh` |
| 2.1 | 1 + 2N requêtes pour lister les clients | `plateforme/…/web/ApiControleur.java` |
| 3.1 | Une remise négative seule échappe au contrôle | `backend/…/service/OrderService.java` |

### 1.2 — le plus grave, et le plus contre-intuitif

Notre vhost pose `proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for`, qui
**ajoute** l'adresse réelle **à la fin** de ce que le client a envoyé. `AuthService.adresse()`
garde la **première**, et son commentaire dit : « la PREMIÈRE adresse, la seule que le proxy
ait écrite lui-même ». C'est l'inverse : le proxy écrit la dernière.

Conséquence : un attaquant qui change d'adresse forgée à chaque essai n'est jamais
ralenti — les dix mille codes PIN redeviennent essayables — et, en forgeant l'adresse du
magasin, il ferme la porte à un commerce entier. `SECURITE.md § 1` affirme que ce point est
corrigé ; il ne l'est que derrière un proxy qui écrase l'en-tête, ce que le nôtre ne fait
pas.

Le vhost pose déjà `X-Real-IP $remote_addr`, que le client ne peut pas influencer : c'est
lui qu'il faut lire d'abord, puis la **dernière** entrée de `X-Forwarded-For`, puis
`getRemoteAddr()`.

### 1.4 — celui-là est de nous

`preparer-demos.sh` passe le mot de passe dans `psql -c "ALTER ROLE … PASSWORD '…'"`.
Tout ce qui est en argument se lit dans `ps` par n'importe quel compte de la machine.

La discipline était pourtant écrite noir sur blanc dans `poscaisse-ouvrir`, rédigé le même
jour : « le mot de passe n'est pas dans cette ligne, et c'est délibéré ». Elle n'a pas été
reportée sur le script d'à côté. Une règle appliquée à un seul endroit n'est pas une règle.

### 3.1 — bon résultat, mauvaise cause

Le rapport conclut qu'aucune validation n'existe. Elles existent toutes : signe, plafond de
100 %, permission, plafond par caissier, seuil au-delà duquel un manager doit autoriser. Le
défaut est ailleurs, dans le `return` anticipé :

```java
boolean any = Money.isPositive(percent) || Money.isPositive(amount);
if (!any) return;                        // ← une remise NÉGATIVE seule sort ici
if (… .signum() < 0) throw …             // ← jamais atteint dans ce cas
```

Effet : la note du client est **majorée**, pas réduite. Le contrôle de signe doit passer
avant le retour anticipé.

## Ce qui ne tient pas

- **4.1 « Remarques cuisine »** — corrigé la veille : renommage en « Remarques » et
  « Mots-clés », et migration `V18` qui retire les huit remarques de restauration rapide
  des bases qui ne s'en servent pas. L'audit a porté sur un état antérieur du dépôt.
- **2.2 multi-tenant** — exact, mais ce n'est pas une trouvaille : `ARCHITECTURE-SAAS.md`
  décrit ce chantier et réclame explicitement le test qui manque.
- **5.2 sauvegardes** — vrai pour le serveur, faux pour le poste autonome, qui a
  `SAUVEGARDER.bat` et sa consigne quotidienne. Le manque réel est côté VPS.

## Ce que la méthode a coûté

Les cinq tests cités — `RevocationEditeurIntegrationTest`, `AdresseAuthentificationTest`,
`AuditConfidentialiteIntegrationTest`, `RemisesAutoriseesTest`, `TenantContextTest` —
**ne sont pas dans le dépôt**. La conclusion affirme qu'ils y sont et qu'ils sont rouges.
Aucune trouvaille n'est donc rejouable : il a fallu tout rouvrir à la main, et c'est ce
travail-là qui a montré que 3.1 était mal diagnostiqué et 4.1 périmé.

Aucun chiffre de temps de réponse n'a été mesuré, alors que le prompt en demandait
(médiane et p95). L'analyse du N+1 est statique, et juste — mais ce n'est pas une mesure.

**Pour la prochaine campagne** : exiger que les tests soient commités avant les
corrections, et qu'ils tournent en l'état. Un défaut sans test qui le prouve est une
opinion.
