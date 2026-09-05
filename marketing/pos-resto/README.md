# POS Resto — Kit marketing (lancement)

Identité de marque, post exemple et cadre de la campagne de lancement de **POS Resto**
(caisse pour restaurants, cafés et fast-foods) sur Facebook, Instagram et TikTok.

> Statut : **V1 à valider**. Une fois le logo et le post 01 validés, le kit sera complété
> pour 2 mois (posts, stories, scripts vidéo, calendrier de publication).

## Arborescence

| Dossier / fichier | Contenu |
|---|---|
| `brand/` | Logo (SVG sources + PNG @4x), icône app 1024 px |
| `posts/` | Visuels prêts à publier (PNG 1080×1080 et 1080×1920) |
| `src/` | Sources HTML des visuels + polices locales (Outfit, Manrope) |
| `src/render.md` | Comment régénérer les PNG |

## 1. Identité de marque

### Logo
- **Symbole** : une cloche de service (le restaurant) coiffée d'une coche (commande validée),
  posée sur un ticket de caisse. Tuile arrondie orange façon icône d'application.
- **Wordmark** : `POS` en encre, `Resto` en braise, typographie Outfit ExtraBold.
- **Signature** : `ENCAISSEZ · SERVEZ · PILOTEZ` (les trois promesses du produit).

| Variante | Fichier | Usage |
|---|---|---|
| Horizontal couleur | `pos-resto-logo-horizontal.svg` | En-têtes, site, bannières claires |
| Horizontal fond sombre | `pos-resto-logo-horizontal-dark.svg` | Stories, vidéos, fonds encre |
| Empilé | `pos-resto-logo-stacked.svg` | Photo de profil, watermark carré |
| Monochrome | `pos-resto-logo-mono.svg` | Impression, tampon, documents |
| Icône seule | `pos-resto-icon.svg` / `pos-resto-icon-1024.png` | Avatar réseaux, favicon, app |

Zone de protection : au moins la hauteur de la coche autour du logo. Taille minimale : 24 px pour l'icône, 120 px de large pour l'horizontal.

### Palette

| Nom | Hex | Rôle |
|---|---|---|
| Braise | `#E8552B` | Accent principal, CTA, « Resto » |
| Encre | `#16233A` | Texte, fonds sombres, « POS » |
| Crème | `#FBF3E8` | Fond clair, texte sur encre |
| Menthe | `#1DB394` | État positif (table libre, encaissé) |
| Safran | `#F2B33D` | Attention (réservation, en attente) |

Braise et Encre portent la marque. Menthe et Safran sont réservés aux états dans les maquettes d'écran ; ils ne remplacent jamais l'accent.

### Typographie
- **Titres / wordmark** : Outfit (700–800), interlettrage serré (−2 %).
- **Texte courant / UI** : Manrope (500–800). Chiffres en tabulaire.
- Les deux polices sont libres (Google Fonts) et incluses dans `src/fonts/`.

### Ton
Direct, concret, du côté du restaurateur. On parle de salle, de service, de tickets, de fin de journée. Pas de jargon logiciel. Prix toujours en DT au format `73,500 DT`.

## 2. Post 01 — Lancement (à valider)

Visuels : `posts/post-01-lancement-1080x1080.png` (feed Facebook / Instagram) et
`posts/post-01-lancement-story-1080x1920.png` (story Instagram / Facebook, couverture TikTok).

**Accroche** : *Votre salle est pleine. Votre caisse suit ?*

**Légende Facebook / Instagram**

> 🍽️ Nouveau : **POS Resto**, la caisse pensée pour les restaurants, cafés et fast-foods tunisiens.
>
> Un service chargé, ça se gère avec une caisse qui suit le rythme :
> ✅ Plan de salle en temps réel
> ✅ Commandes envoyées en cuisine instantanément
> ✅ Espèces, TPE, tickets resto : tout est encaissé
> ✅ Vos chiffres du jour, connectés à votre gestion
>
> 👉 Demandez votre démo gratuite : écrivez-nous en message privé ou cliquez sur le lien en bio.
>
> #POSResto #CaisseRestaurant #RestaurantTunisie #Restauration #FastFood #CaféTunis #GestionRestaurant #SOPIQ

**Version TikTok (texte court)**
> Ta salle est pleine, ta caisse suit ? 🍽️ POS Resto : plan de salle, envoi cuisine, encaissement. Démo gratuite en DM 👉 #POSResto #RestaurantTunisie #Restauration #fyp

**Script story (15 s)**
1. (0–3 s) Plan de salle animé, tables qui passent de « Libre » à « Occupée ». Texte : *Service du soir, 20:42.*
2. (3–8 s) Une commande est saisie et part en cuisine. Texte : *Table 7 · envoyée en cuisine.*
3. (8–12 s) Écran d'encaissement, total 73,500 DT, paiement TPE. Texte : *Encaissé.*
4. (12–15 s) Logo + *Démo gratuite → répondez à cette story.*

## 3. Cadre de la campagne (2 mois, à détailler après validation)

| Semaine | Thème | Formats |
|---|---|---|
| S1–S2 | Lancement : le problème (caisse lente, erreurs, fin de journée) et la promesse | Post carré, story, vidéo teaser 15 s |
| S3–S4 | Fonctionnalités : plan de salle, envoi cuisine, encaissement multi-moyens | Carrousels « 1 fonction = 1 slide », vidéo démo 30 s |
| S5–S6 | Preuve : coulisses d'un service, chiffres du jour, témoignage client | Reels/TikTok terrain, post citation |
| S7–S8 | Conversion : offre de lancement, FAQ, appel à la démo | Post offre, story Q/R, vidéo « installation en 1 journée » |

Cadence cible : 3 posts feed / semaine (Facebook + Instagram), 3 stories / semaine, 2 TikTok / semaine.

## 4. À fournir pour finaliser le kit

Le dépôt `SOPIQ_INTERNE` ne contient pas l'application POS Resto : les écrans du post sont des **maquettes**.
Pour remplacer les maquettes par le vrai produit et verrouiller les messages, il manque :

1. Captures d'écran ou accès à l'application POS Resto (plan de salle, prise de commande, encaissement, rapport de fin de journée).
2. Liste exacte des fonctionnalités et des moyens de paiement supportés (les quatre promesses du post 01 sont des hypothèses à confirmer).
3. Coordonnées de contact et lien à mettre en bio (site, WhatsApp, téléphone) — `sopiq.tn` est un placeholder.
4. Offre de lancement et grille tarifaire, si elles doivent apparaître dans la campagne.
5. Vidéos brutes d'un service (téléphone, format vertical) pour les Reels / TikTok terrain.
