# Logos Integra (POS, ERP, CRM, BI)

Système de marque : **Integra** est la constante (noir), le **suffixe produit** est la
variable (teal). Tous les fichiers SVG sont vectoriels purs (texte converti en tracés),
aucune police à installer.

## Fichiers

| Fichier | Usage |
|---|---|
| `integra-<produit>-color.svg/.png` | Version principale, fond clair, avec « Powered by EBS » |
| `integra-<produit>-color-compact.svg/.png` | Sans la ligne « Powered by EBS » (en-têtes, barres d'appli) |
| `integra-<produit>-mono.svg/.png` | Monochrome noir (impression, fax, tampon) |
| `integra-<produit>-inverse.svg/.png` | Fond sombre (`#0F1B1F`), texte blanc, suffixe teal clair |
| `integra-icon-<schéma>.svg/.png` | Icône seule (favicon, app mobile, avatar) |
| `preview-sheet.png` | Planche de contrôle de toutes les déclinaisons |

`<produit>` ∈ `pos`, `erp`, `crm`, `bi`. Les PNG sont exportés en 2x (transparents,
sauf la version inverse qui embarque son fond).

## Couleurs

| Rôle | Fond clair | Fond sombre |
|---|---|---|
| Wordmark « Integra » | `#0B0B0B` | `#FFFFFF` |
| Suffixe produit | `#1F5F6E` | `#6CC3D3` |
| Icône (dégradé haut → bas) | `#2E7A8B` → `#1E5B69` | `#3E97A9` → `#2A7585` |
| Fond sombre | – | `#0F1B1F` |

## Règles

- Le suffixe est toujours en teal, quelle que soit la gamme (une seule couleur pour
  toute la famille de produits).
- Suffixe : Inter SemiBold, capitales, 2/3 de la taille de « Integra », même ligne de
  base, espace fixe de 48 unités après le « a ».
- Ne pas appliquer le dégradé au texte ; ne pas modifier les proportions icône/texte.
- Zone de protection : la hauteur du « I » d'« Integra » sur les quatre côtés.
- Taille minimale : 140 px de large pour la version compacte, 220 px avec la ligne
  « Powered by EBS » ; en dessous, utiliser l'icône seule.

## Regénérer

Les fichiers sont produits par `generate_logos.py` (Python 3, `pip install fonttools uharfbuzz`) (fontTools + uharfbuzz) à partir des
polices Inter 500/600/700 ; adapter le suffixe dans la liste `["POS", "ERP", "CRM", "BI"]`
pour ajouter une gamme.

```bash
# Inter-500.ttf, Inter-600.ttf, Inter-700.ttf dans ./fonts (ou INTER_FONT_DIR)
python3 generate_logos.py .
```
