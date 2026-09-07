# -*- coding: utf-8 -*-
"""
Une page unique pour trancher devant le client : les deux mises en page, un bouton.

    python3 outils/comparer.py

Le restaurateur ne choisit pas entre deux fichiers ouverts dans deux onglets - il
bascule, et il voit la difference au meme endroit de l'ecran. C'est la seule maniere
de juger une mise en page : cote a cote, tout se ressemble.

LES DEUX VERSIONS SONT RENDUES A LA MEME HAUTEUR DE LIGNE. Laissee libre, la version
en listes monte a 41,1 px contre 39,5 en matrice - l'oeil jugerait alors la taille du
texte au lieu de juger la mise en page. On impose donc la plus basse des deux aux deux
cotes, et la page le dit.

C'est aussi ce qui permet UNE SEULE feuille de style pour les six tableaux : la
geometrie ne depend que de la hauteur de ligne, et les deux mises en page vivent deja
dans la meme feuille - l'ecran de droite est une liste alors que les deux autres sont
des matrices. Le script le verifie plutot que de l'esperer.
"""
import json, os, re, subprocess, sys

ICI = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
GEN = os.path.join(ICI, 'outils', 'generer-tv.py')
ECRANS = [('1-gauche', 'Gauche'), ('2-centre', 'Centre'), ('3-droite', 'Droite')]
LIGNE = '39.5'


def engendrer(version, dossier, ligne=None):
    # La version est toujours nommee : sans elle, la hauteur imposee se retrouverait
    # en premier argument et serait lue comme un nom de version.
    args = [sys.executable, GEN, version]
    if ligne: args.append(ligne)
    r = subprocess.run(args, capture_output=True, text=True, cwd=ICI)
    if r.returncode: raise SystemExit(r.stderr or r.stdout)
    return os.path.join(ICI, dossier) if dossier else ICI


def decouper(chemin):
    """Un apercu, ramene a ses deux morceaux : sa feuille de style et son tableau."""
    t = open(chemin, encoding='utf-8').read()
    styles = re.findall(r'<style>(.*?)</style>', t, re.S)
    corps = t[t.rindex('</style>') + len('</style>'):]
    return styles[-1], corps


# Les deux versions sont d'abord engendrees a la hauteur imposee, et lues en memoire.
# Les fichiers sont ensuite refaits a leur taille naturelle : ce qui part sur les
# televiseurs ne doit pas porter la trace d'une comparaison.
pages = {}
feuilles = set()
for version, dossier in (('croise', ''), ('listes', 'variante-listes')):
    ou = engendrer(version, dossier, LIGNE)
    for code, place in ECRANS:
        css, corps = decouper(os.path.join(ou, 'apercu-ecran-%s.html' % code))
        feuilles.add(css)
        pages[version + '|' + code] = corps

# Une seule feuille pour les six : si les deux versions divergeaient, la page mentirait
# a moitie - autant s'arreter que publier un tableau mis en page avec la mauvaise.
if len(feuilles) != 1:
    raise SystemExit('Les deux versions ne partagent pas la meme feuille de style : '
                     'la comparaison ne serait pas honnete. (%d feuilles distinctes)' % len(feuilles))
feuille = feuilles.pop()

POLICES = ('<link rel="preconnect" href="https://fonts.googleapis.com">'
           '<link rel="stylesheet" href="https://fonts.googleapis.com/css2?'
           'family=Anton&family=Barlow+Semi+Condensed:wght@500;600&display=swap">')

PAGE = """<title>Menu mural — deux mises en page</title>
%(polices)s
<style>
%(feuille)s
:root { color-scheme: dark; }
body { margin: 0; background: #0b0b0c; color: #cfc7ba;
       font-family: 'Barlow Semi Condensed', system-ui, sans-serif; }
.page { padding: 26px clamp(14px, 3vw, 40px) 60px; max-width: 1500px; margin-inline: auto; }
h1 { font-family: Anton, sans-serif; font-size: clamp(24px, 3.4vw, 34px); letter-spacing: .14em;
     text-transform: uppercase; color: #FECC30; margin: 0 0 6px; }
.chapeau { font-size: 16px; line-height: 1.55; color: #9d9285; margin: 0 0 22px; max-width: 78ch; }
.bascule { display: flex; gap: 8px; flex-wrap: wrap; margin-bottom: 8px; position: sticky; top: 0;
           background: #0b0b0c; padding: 12px 0; z-index: 5; }
.bascule button { font: 600 16px/1 'Barlow Semi Condensed', sans-serif; letter-spacing: .06em;
                  text-transform: uppercase; color: #cfc7ba; background: #17161a; cursor: pointer;
                  border: 1px solid #2b2924; border-radius: 4px; padding: 13px 22px; }
.bascule button:hover { border-color: #5a544a; }
.bascule button[aria-pressed="true"] { background: #FECC30; border-color: #FECC30; color: #17150f; }
.dit { font-size: 15.5px; line-height: 1.6; color: #9d9285; margin: 0 0 18px; max-width: 84ch; }
.dit b { color: #F6EFE3; font-weight: 600; }
.ecrans { display: flex; flex-direction: column; gap: 26px; }
.poste .titre { display: flex; align-items: baseline; gap: 10px; margin-bottom: 7px; }
.poste .titre b { font-size: 14px; letter-spacing: .18em; text-transform: uppercase; color: #F6EFE3; }
.poste .titre span { font-size: 13.5px; color: #8B8072; }
.cadre { border: 3px solid #22201d; border-radius: 6px; background: #000; padding: 3px; }
/* La dalle garde son rapport 16/9 : c'est la largeur disponible qui commande, comme au mur. */
.cadre .tableau { --u: calc((100vw - clamp(56px, 6vw, 106px)) / 1920); }
@media (min-width: 1560px) { .cadre .tableau { --u: calc(1440px / 1920); } }
.tableau[hidden] { display: none !important; }
.pied { margin-top: 34px; border-top: 1px solid #22201d; padding-top: 16px; font-size: 14px; color: #6f665b; }
</style>

<div class="page">
  <h1>Le menu mural, deux mises en page</h1>
  <p class="chapeau">Les mêmes 108 articles et les mêmes prix, venus de la caisse. Seule change la façon
     de ranger les quatre familles de mlewi sur les écrans de gauche et du centre.
     L'écran de droite est identique dans les deux versions.</p>

  <div class="bascule">
    <button type="button" data-v="croise" aria-pressed="true">Tableaux croisés</button>
    <button type="button" data-v="listes" aria-pressed="false">Listes séparées</button>
  </div>

  <p class="dit" id="dit"></p>
  <div class="ecrans">%(ecrans)s</div>

  <p class="pied">Les deux versions sont rendues à la <b>même hauteur de ligne</b> (39,5 px sur une base
     1920 × 1080), pour comparer la mise en page et non la taille du texte. Laissée libre, la version en
     listes monterait à 41,1 px — un peu plus grande, donc, que ce qui est montré ici.</p>
</div>

<script>
var DITS = {
  croise: "Une ligne par garniture, et à droite deux blocs de trois prix — nature à gauche, avec le fromage à droite. <b>19 lignes au lieu de 38.</b> On compare deux versions d’un même sandwich d’un seul coup d’œil, mais il faut lire l’en-tête pour savoir quelle colonne est laquelle.",
  listes: "Chaque famille forme un bloc entier, avec son titre et ses trois prix. On lit droit devant soi, sans compter les colonnes — mais le même nom de garniture se répète quatre fois sur le mur."
};
var boutons = [].slice.call(document.querySelectorAll('.bascule button'));
var dit = document.getElementById('dit');
function montrer(v) {
  boutons.forEach(function (b) { b.setAttribute('aria-pressed', String(b.dataset.v === v)); });
  [].forEach.call(document.querySelectorAll('.tableau[data-v]'), function (t) { t.hidden = t.dataset.v !== v; });
  dit.innerHTML = DITS[v];
}
boutons.forEach(function (b) { b.onclick = function () { montrer(b.dataset.v); }; });
montrer('croise');
</script>"""

blocs = []
for code, place in ECRANS:
    dedans = ''
    for version in ('croise', 'listes'):
        corps = pages[version + '|' + code]
        # Le tableau porte sa version : la bascule ne fait qu'allumer l'un et eteindre l'autre.
        dedans += corps.replace('<div class="tableau">', '<div class="tableau" data-v="%s">' % version, 1)
    blocs.append('<div class="poste"><div class="titre"><b>Écran %s</b><span>%s</span></div>'
                 '<div class="cadre">%s</div></div>'
                 % (place.lower(), {'Gauche': 'Classic et Fromage', 'Centre': 'Mozarilla et Mozarilla 3arbi',
                                    'Droite': 'Spécial, Lablebi, Boissons, Extras'}[place], dedans))

sortie = os.path.join(ICI, 'comparaison.html')
open(sortie, 'w', encoding='utf-8').write(
    PAGE % {'polices': POLICES, 'feuille': feuille, 'ecrans': ''.join(blocs)})

# Chaque version retrouve sa hauteur de ligne propre - c'est elle qui ira sur les dalles.
engendrer('croise', '')
engendrer('listes', 'variante-listes')
print('comparaison.html : %d Ko, 6 tableaux, une seule feuille de style.'
      % (os.path.getsize(sortie) // 1024))
print('La variante en listes reste dans variante-listes/, la version croisee a sa place habituelle.')
