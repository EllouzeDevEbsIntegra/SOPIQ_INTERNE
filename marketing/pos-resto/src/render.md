# Régénérer les visuels

Prérequis : Node 18+ et Playwright (`npm i -g playwright`) avec un Chromium installé.

```bash
# rendu d'un visuel : <source html> <png de sortie> <largeur> <hauteur> [échelle]
node render.mjs "$PWD/post-01-lancement-carre.html" "$PWD/../posts/post-01-lancement-1080x1080.png" 1080 1080
node render.mjs "$PWD/post-01-lancement-story.html" "$PWD/../posts/post-01-lancement-story-1080x1920.png" 1080 1920
```

Les polices sont chargées localement via `fonts.css` (dossier `fonts/`), donc le rendu fonctionne hors ligne.
Les SVG du dossier `brand/` référencent Google Fonts via `@import` pour l'affichage navigateur ; pour un usage
imprimeur, vectoriser le texte dans Illustrator/Inkscape (Outfit et Manrope sont sous licence OFL).
