# Logos Integra (POS, ERP, CRM, BI)

Tous les fichiers sont dérivés du **master officiel** `source/integra-complet.svg`
(icône, wordmark « Integra », ligne « Powered by EBS » : tracés repris mot pour mot).
Seul le groupe du suffixe change : « ERP » garde les tracés du master ; POS, CRM et BI
sont composés en Inter SemiBold aux mêmes métriques (hauteur de capitale 176, ligne de
base 670, départ x 2552, interlettrage calibré sur la largeur exacte de « ERP »).

Système de marque : **Integra** est la constante (bleu nuit) et l'icône reste toujours
teal ; le **suffixe produit** porte une couleur propre à chaque verticale. Tous les fichiers SVG sont vectoriels purs (texte converti en tracés),
aucune police à installer.

## Fichiers

| Fichier | Usage |
|---|---|
| `integra-<produit>-color.svg/.png` | Version principale, fond clair, avec « Powered by EBS » |
| `integra-<produit>-color-compact.svg/.png` | Sans la ligne « Powered by EBS » (en-têtes, barres d'appli) |
| `integra-<produit>-mono.svg/.png` | Monochrome noir (impression, fax, tampon) |
| `integra-<produit>-inverse.svg/.png` | Fond sombre (`#0F1622`), texte blanc, suffixe en variante claire |
| `source/integra-complet.svg` | Master officiel (Integra ERP), ne pas modifier |
| `integra-icon-<schéma>.svg/.png` | Icône seule (favicon, app mobile, avatar) |
| `preview-sheet.png` | Planche de contrôle de toutes les déclinaisons |

`<produit>` ∈ `pos`, `erp`, `crm`, `bi`. Les PNG sont exportés en 2x (transparents,
sauf la version inverse qui embarque son fond).

## Couleurs

| Rôle | Fond clair | Fond sombre |
|---|---|---|
| Wordmark « Integra » | `#17233A` | `#FFFFFF` |
| « Powered by EBS » | `#64748B` | `#A7B1C2` |
| Icône (dégradé haut → bas) | `#2E7D91` → `#164752` | `#3A93A8` → `#1E5D6B` |
| Fond sombre | – | `#0F1622` |

### Couleur par verticale (suffixe)

| Produit | Fond clair | Fond sombre | Signification |
|---|---|---|---|
| **POS** | `#D9701A` orange | `#F5A054` | commerce, caisse, énergie |
| **ERP** | `#1F4E8C` bleu | `#6FA3F0` | gestion, finance, fiabilité |
| **CRM** | `#6B3FA0` violet | `#B48CE6` | relation client |
| **BI** | `#1F8A5B` vert | `#5CC48F` | données, croissance |

Réservées pour de futures gammes (ne pas réutiliser les couleurs ci-dessus) :
rouge brique `#B8352E` (WMS / logistique), or `#B8860B` (RH / paie), rose `#C2417A` (e-commerce).

## Règles

- Une couleur = un produit ; le teal est réservé à l'icône et ne sert jamais de suffixe.
- La couleur d'un produit est reprise comme couleur d'accent dans son application
  (boutons principaux, onglet actif) pour renforcer l'identification.
- Suffixe : capitales, hauteur de capitale 176 (viewBox 1374), positionné exactement
  comme « ERP » dans le master ; la largeur du logo varie avec la longueur du suffixe et
  la marge droite reste celle du master.
- Ne pas appliquer le dégradé au texte ; ne pas modifier les proportions icône/texte.
- Zone de protection : la hauteur du « I » d'« Integra » sur les quatre côtés.
- Taille minimale : 140 px de large pour la version compacte, 220 px avec la ligne
  « Powered by EBS » ; en dessous, utiliser l'icône seule.

## Regénérer

```bash
pip install fonttools uharfbuzz svgelements
# Inter-600.ttf dans ./fonts (ou INTER_FONT_DIR)
python3 generate_logos.py .
```

Pour ajouter une gamme : une ligne dans le dictionnaire `PRODUCTS` de `generate_logos.py`
(couleur fond clair, couleur fond sombre). Les PNG (2x) et la planche sont rendus avec
Chromium/Playwright.
