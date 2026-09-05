# Integra POS — Kit marketing

Campagne de lancement d'**Integra POS** (application PosCaisse) sur Facebook, Instagram et TikTok.
Marque et logo fournis par SOPIQ. Tous les visuels utilisent des **captures d'écran réelles** de l'application.

| Dossier | Contenu |
|---|---|
| `FONCTIONNALITES.md` | Inventaire des fonctionnalités relevé dans le code et vérifié à l'écran. Référence pour tout message publié. |
| `screenshots/` | 38 captures réelles (1440×900 à 2×) : 20 écrans caisse, 18 écrans back-office, données de démonstration FAST FOOD DEMO |
| `brand/` | Logo Integra POS fourni par SOPIQ (à déposer : `logo-integra-pos-v1.png`, `logo-integra-pos-v2.png`) |
| `posts/` | Visuels prêts à publier (PNG) |
| `src/` | Sources HTML des visuels, polices locales, script de rendu |
| `tools/` | Scripts Playwright qui ont produit les captures (rejouables sur l'application locale) |

## Identité

- **Nom** : Integra POS. Signature : « Votre restaurant, plus simple ». Piliers : Rapide · Tactile · Performant.
- **Couleurs du logo** : orange `#F97316` → `#FF5A1F` (dégradé), noir `#1B1B1B`.
- **Couleurs de l'application** (à respecter dans les montages pour rester cohérent avec les captures) : vermillon `#C8441C`, encre `#14110E`, canevas `#F2F0EB`, vert encaissement `#15784A`.
- **Typographie des visuels** : Outfit (titres) et Manrope (texte), libres et incluses dans `src/fonts/`.

## Rejouer les captures

```bash
# application lancée sur http://localhost:8080 avec le jeu de démonstration
cd tools && node capture-pos.mjs          # 20 écrans caisse (crée des ventes de démo)
node capture-backoffice.mjs               # clôture propre + 18 écrans back-office
```

## Rendre un visuel

```bash
cd src && node render.mjs "$PWD/post-01-lancement-carre.html" "$PWD/../posts/post-01-lancement-1080x1080.png" 1080 1080
```
