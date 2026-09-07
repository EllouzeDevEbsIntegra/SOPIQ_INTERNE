# -*- coding: utf-8 -*-
"""
Une seule page pour montrer les QUATRE propositions au client.

    python3 outils/propositions.py

Deux dispositions x deux palettes. Le client ne choisit pas entre quatre fichiers
ouverts dans quatre onglets : il bascule d'un menu en haut de page, et la difference
se voit au meme endroit de l'ecran. Cote a cote, tout se ressemble.

Les quatre versions sont rendues A LA MEME HAUTEUR DE LIGNE - la plus basse des
quatre, relue dans la sortie du generateur : sinon l'oeil jugerait la taille du texte
au lieu de juger la mise en page. Les fichiers qui partent sur les televiseurs, eux,
sont ensuite refaits a leur taille naturelle.

Le fichier tient dans un seul HTML, sans reseau : polices en ligne (c'est un apercu),
mais surtout UNE feuille de geometrie pour les douze tableaux et UNE copie de chaque
photo de fond, au lieu de quatre. Sans cela la page pesait quatre megaoctets.
"""
import os, re, subprocess, sys

ICI = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
GEN = os.path.join(ICI, 'outils', 'generer-tv.py')
ECRANS = [('1-gauche', 'Gauche', 'Classic et Fromage'),
          ('2-centre', 'Centre', 'Mozarilla et Mozarilla 3arbi'),
          ('3-droite', 'Droite', 'Spécial, Lablebi, Boissons, Extras')]
# disposition x palette -> dossier de sortie du generateur
VERSIONS = [('croise', 'nuit', ''), ('croise', 'clair', 'variante-clair'),
            ('listes', 'nuit', 'variante-listes'), ('listes', 'clair', 'variante-listes-clair')]


def engendrer(version, palette, ligne=None):
    args = [sys.executable, GEN, version, palette] + ([ligne] if ligne else [])
    r = subprocess.run(args, capture_output=True, text=True, cwd=ICI)
    if r.returncode:
        raise SystemExit(r.stderr or r.stdout)
    return r.stdout


def hauteur(sortie):
    m = re.search(r'ligne de\s+([\d.]+) px', sortie)
    if not m:
        raise SystemExit('Hauteur de ligne introuvable dans la sortie du generateur.')
    return m.group(1)


# La hauteur imposee est la plus basse des quatre : imposer la plus haute deborderait
# de l'ecran le plus charge. Elle est relue, jamais recopiee - un chiffre en dur ici se
# serait desaccorde a la premiere retouche de mise en page.
naturelles = {(v, p): hauteur(engendrer(v, p)) for v, p, _ in VERSIONS}
LIGNE = min(naturelles.values(), key=float)


def decouper(chemin):
    """Un apercu, ramene a ses trois morceaux : ses couleurs, sa geometrie, son tableau."""
    t = open(chemin, encoding='utf-8').read()
    feuille = re.findall(r'<style>(.*?)</style>', t, re.S)[-1]
    couleurs, geometrie = feuille.split('/* fin palette */', 1)
    # La page a son propre corps : les regles de plein ecran du tableau n'y ont pas leur
    # place, et le :root des palettes ne doit pas repeindre la page elle-meme.
    geometrie = re.sub(r'html, body \{[^}]*\}|body \{ display: flex[^}]*\}', '', geometrie)
    geometrie = geometrie.replace('body{background:%s;height:100vh}' % 'x', '')
    geometrie = re.sub(r'body\{background:[^}]*\}', '', geometrie)
    couleurs = couleurs.replace(':root, ', '')
    return couleurs.strip(), geometrie, t[t.rindex('</style>') + len('</style>'):]


pages, geometries, couleurs = {}, set(), {}
for version, palette, dossier in VERSIONS:
    engendrer(version, palette, LIGNE)
    ou = os.path.join(ICI, dossier) if dossier else ICI
    for code, place, quoi in ECRANS:
        c, g, corps = decouper(os.path.join(ou, 'apercu-ecran-%s.html' % code))
        geometries.add(g)
        couleurs[palette] = c
        pages[(version, palette, code)] = corps

# Une seule geometrie pour les douze tableaux : si elle divergeait d'une version a
# l'autre, la page mentirait aux trois quarts - autant s'arreter que montrer au client
# un tableau mis en page avec la mauvaise feuille.
if len(geometries) != 1:
    raise SystemExit('Les quatre versions ne partagent pas la meme geometrie : '
                     'la comparaison ne serait pas honnete. (%d feuilles distinctes)'
                     % len(geometries))
geometrie = geometries.pop()

# Les trois photos de fond sont les memes dans les quatre versions : une seule copie de
# chacune, nommee par une classe. Repetees, elles pesaient plus de trois megaoctets.
fonds, classes = {}, {}
for cle, corps in pages.items():
    m = re.search(r'<div class="fond" style="background-image:url\(([^)]*)\)"></div>', corps)
    if not m:
        continue
    uri = m.group(1)
    nom = fonds.setdefault(uri, 'fond-%d' % (len(fonds) + 1))
    pages[cle] = corps.replace(m.group(0), '<div class="fond %s"></div>' % nom)
fonds_css = ''.join('.%s{background-image:url(%s)}\n' % (n, u) for u, n in fonds.items())

POLICES = ('<link rel="preconnect" href="https://fonts.googleapis.com">'
           '<link rel="stylesheet" href="https://fonts.googleapis.com/css2?'
           'family=Anton&family=Barlow+Semi+Condensed:wght@500;600&display=swap">')

DITS = {
    'croise': "Une ligne par garniture, et à droite deux blocs de trois prix — nature à gauche, "
              "avec le fromage à droite. <b>19 lignes au lieu de 38.</b> On compare deux versions "
              "d’un même sandwich d’un seul coup d’œil, mais il faut lire l’en-tête pour savoir "
              "quelle colonne est laquelle.",
    'listes': "Chaque famille forme un bloc entier, avec son titre et ses trois prix. On lit droit "
              "devant soi, sans compter les colonnes — mais le même nom de garniture se répète "
              "quatre fois sur le mur.",
    'nuit': "Fond noir, prix en or. Le tableau s’efface et les chiffres avancent ; c’est la salle "
            "qui éclaire le mur.",
    'clair': "Fond crème, prix à l’encre, rouge brique sur les titres, le téléphone et le prix de "
             "base. Plus proche d’une carte imprimée, plus lumineux de loin.",
}

PAGE = """<title>Menu mural — quatre propositions</title>
%(polices)s
<style>
%(geometrie)s
%(fonds)s
.tableau.nuit { %(nuit)s }
.tableau.clair { %(clair)s }
:root { color-scheme: dark; }
body { margin: 0; background: #0b0b0c; color: #cfc7ba; overflow: auto;
       font-family: 'Barlow Semi Condensed', system-ui, sans-serif; }
.page { padding: 22px clamp(14px, 3vw, 40px) 60px; max-width: 1500px; margin-inline: auto; }
h1 { font-family: Anton, sans-serif; font-size: clamp(23px, 3.2vw, 32px); letter-spacing: .14em;
     text-transform: uppercase; color: #FECC30; margin: 0 0 6px; }
.chapeau { font-size: 16px; line-height: 1.55; color: #9d9285; margin: 0 0 18px; max-width: 80ch; }
.menu { position: sticky; top: 0; background: #0b0b0c; padding: 12px 0 10px; z-index: 5;
        border-bottom: 1px solid #1d1c19; }
.rang { display: flex; gap: 8px; flex-wrap: wrap; align-items: center; margin-bottom: 8px; }
.rang:last-child { margin-bottom: 0; }
.rang > span { font-size: 12.5px; letter-spacing: .18em; text-transform: uppercase;
               color: #6f665b; width: 108px; flex: none; }
.menu button { font: 600 15.5px/1 'Barlow Semi Condensed', sans-serif; letter-spacing: .05em;
               text-transform: uppercase; color: #cfc7ba; background: #17161a; cursor: pointer;
               border: 1px solid #2b2924; border-radius: 4px; padding: 12px 20px; }
.menu button:hover { border-color: #5a544a; }
.menu button[aria-pressed="true"] { background: #FECC30; border-color: #FECC30; color: #17150f; }
.dit { font-size: 15.5px; line-height: 1.6; color: #9d9285; margin: 16px 0 18px; max-width: 88ch; }
.dit b { color: #F6EFE3; font-weight: 600; }
.dit i { font-style: normal; color: #7e756a; }
.ecrans { display: flex; flex-direction: column; gap: 24px; }
.poste .titre { display: flex; align-items: baseline; gap: 10px; margin-bottom: 7px; }
.poste .titre b { font-size: 14px; letter-spacing: .18em; text-transform: uppercase; color: #F6EFE3; }
.poste .titre span { font-size: 13.5px; color: #8B8072; }
.cadre { border: 3px solid #22201d; border-radius: 6px; background: #000; padding: 3px; }
/* La dalle garde son rapport 16/9 : c'est la largeur disponible qui commande, comme au mur. */
.cadre .tableau { --u: calc((100vw - clamp(56px, 6vw, 106px)) / 1920); }
@media (min-width: 1560px) { .cadre .tableau { --u: calc(1440px / 1920); } }
.tableau[hidden] { display: none !important; }
.pied { margin-top: 32px; border-top: 1px solid #22201d; padding-top: 16px; font-size: 14px;
        color: #6f665b; line-height: 1.6; }
</style>

<div class="page">
  <h1>Le menu mural — quatre propositions</h1>
  <p class="chapeau">Les mêmes %(articles)d articles et les mêmes prix, venus de la caisse.
     Deux façons de ranger les familles de mlewi, deux jeux de couleurs : choisissez une
     disposition et une palette, les trois écrans se repeignent.</p>

  <div class="menu">
    <div class="rang"><span>Disposition</span>
      <button type="button" data-axe="d" data-v="croise" aria-pressed="true">Tableaux croisés</button>
      <button type="button" data-axe="d" data-v="listes" aria-pressed="false">Listes séparées</button>
    </div>
    <div class="rang"><span>Couleurs</span>
      <button type="button" data-axe="p" data-v="nuit" aria-pressed="true">Nuit</button>
      <button type="button" data-axe="p" data-v="clair" aria-pressed="false">Crème</button>
    </div>
  </div>

  <p class="dit" id="dit"></p>
  <div class="ecrans">%(ecrans)s</div>

  <p class="pied">Les quatre versions sont montrées à la <b>même hauteur de ligne</b>
     (%(ligne)s px sur une base 1920 × 1080), pour comparer la mise en page et non la taille du
     texte : laissée libre, la version en listes monte un peu plus haut. Ce qui part sur les
     téléviseurs est refait à sa taille naturelle.<br>
     Chaque écran est un fichier autonome, sans réseau : <i>%(chemins)s</i>.</p>
</div>

<script>
var DITS = %(dits)s;
var choix = { d: 'croise', p: 'nuit' };
var dit = document.getElementById('dit');
function montrer() {
  var v = choix.d + '|' + choix.p;
  [].forEach.call(document.querySelectorAll('.menu button'), function (b) {
    b.setAttribute('aria-pressed', String(choix[b.dataset.axe] === b.dataset.v));
  });
  [].forEach.call(document.querySelectorAll('.tableau[data-v]'), function (t) {
    t.hidden = t.dataset.v !== v;
  });
  dit.innerHTML = DITS[choix.d] + ' <i>—</i> ' + DITS[choix.p];
}
[].forEach.call(document.querySelectorAll('.menu button'), function (b) {
  b.onclick = function () { choix[b.dataset.axe] = b.dataset.v; montrer(); };
});
montrer();
</script>"""

import json
blocs = []
for code, place, quoi in ECRANS:
    dedans = ''
    for version, palette, _ in VERSIONS:
        corps = pages[(version, palette, code)]
        dedans += corps.replace('<div class="tableau ',
                                '<div data-v="%s|%s" class="tableau ' % (version, palette), 1)
    blocs.append('<div class="poste"><div class="titre"><b>Écran %s</b><span>%s</span></div>'
                 '<div class="cadre">%s</div></div>' % (place.lower(), quoi, dedans))

chemins = ', '.join((d or 'tv/') for _, _, d in VERSIONS)
sortie = os.path.join(ICI, 'propositions.html')
open(sortie, 'w', encoding='utf-8').write(PAGE % {
    'polices': POLICES, 'geometrie': geometrie, 'fonds': fonds_css,
    'nuit': couleurs['nuit'].split('{', 1)[1].rsplit('}', 1)[0].strip(),
    'clair': couleurs['clair'].split('{', 1)[1].rsplit('}', 1)[0].strip(),
    'ecrans': ''.join(blocs), 'ligne': LIGNE.replace('.', ','), 'articles': 108,
    'chemins': chemins, 'dits': json.dumps(DITS, ensure_ascii=False)})

# Chaque version retrouve sa hauteur de ligne propre : c'est elle qui ira sur les dalles.
for version, palette, _ in VERSIONS:
    engendrer(version, palette)
print('propositions.html : %d Ko, 12 tableaux, une seule geometrie, %d photos de fond.'
      % (os.path.getsize(sortie) // 1024, len(fonds)))
for (v, p), h in sorted(naturelles.items()):
    print('  %-7s %-6s hauteur de ligne naturelle %s px' % (v, p, h))
