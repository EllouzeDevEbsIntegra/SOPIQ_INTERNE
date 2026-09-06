# -*- coding: utf-8 -*-
"""
Engendre les trois tableaux de menu des televiseurs de la salle.

    python3 outils/generer-tv.py

Trois ecrans de 40 pouces cote a cote, en hauteur, au-dessus du comptoir. Ce n'est pas
un site retreci : on lit ces tableaux debout, a trois ou quatre metres, en quelques
secondes, sans pouvoir cliquer ni faire defiler. Tout en decoule.

CE QUI EST DECIDE ICI, ET POURQUOI

  Un seul prix par ligne, celui de la pate normale. La carte porte trois prix par
  article - a l'ecran, trois colonnes divisent la taille du texte par deux et le
  tableau devient illisible du fond de la salle. L'ecart est le meme partout (verifie
  sur les 86 articles declines : cereale +1,000, chia +1,500), donc il se dit UNE fois,
  en grand, dans le bandeau rouge que porte chacun des trois ecrans.

  Rien ne tourne, rien ne defile, rien ne clignote. Un client qui arrive au milieu d'une
  rotation attend son tour pour lire un prix ; et un ecran fixe ne demande pas qu'on
  revienne. Les 111 articles tiennent sur les trois ecrans, tous visibles en meme temps.

  Pas de photo dans les listes. A cette densite, une vignette coute deux lignes de
  texte, et le client qui leve les yeux cherche un prix, pas une image - il a deja vu
  les photos sur la caisse et sur le site.

  Chaque ecran porte une part differente de la carte, et chacun se suffit : le bandeau
  des pates, l'enseigne et le telephone y figurent tous les trois, parce qu'on ne
  regarde pas les trois ecrans, on regarde celui qui est en face de soi.

  Les fichiers sont autonomes : polices et logo embarques, aucun appel au reseau. Un
  tableau de menu qui depend d'internet s'eteint le jour ou la connexion tombe.
"""
import base64, io, json, os, re, unicodedata

ICI = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CARTE = os.path.join(ICI, '..', 'site', 'carte.json')
LOGO = os.path.join(ICI, '..', 'site', 'img', 'logo-number-one.png')
POLICES = os.path.join(ICI, 'outils', 'polices')

# Repartition des rubriques sur les trois ecrans. L'ecran de gauche ouvre sur les
# compositions de la maison - c'est par la que le regard entre.
ECRANS = [
    ('1-gauche', 'Gauche',  ['Spécial', 'Classic', 'Lablebi']),
    ('2-centre', 'Centre',  ['Mozarilla', 'Mozarilla 3arbi']),
    ('3-droite', 'Droite',  ['Fromage', 'Boissons', 'Extras']),
]

# Geometrie, en pixels d'un ecran 1920 x 1080. Toute la page est ecrite dans cette
# unite puis mise a l'echelle par le navigateur : la composition est donc la meme sur
# un televiseur 4K que sur un vieux 1366 x 768.
LARGE, HAUT = 1920, 1080
MARGE, ENTETE, BANDEAU, ECART = 40, 80, 52, 14
# Un televiseur rogne les bords - jusqu'a 2,5 % de la dalle sur les reglages d'usine.
# On garde donc du noir sous la derniere ligne : 54 px, soit le double de ce que la
# surbalayage mange, pour qu'un prix ne disparaisse jamais par le bas.
RESERVE = 14
DISPO = HAUT - 2 * MARGE - ENTETE - BANDEAU - ECART - RESERVE
LIGNE_MAX, TITRE = 46, 1.42                           # hauteur de ligne, cout d'un titre


def prix(v):
    return ('%.3f' % float(v)).replace('.', ',')


def b64(chemin, mime):
    return 'data:%s;base64,%s' % (mime, base64.b64encode(open(chemin, 'rb').read()).decode())


def logo_data():
    """Le logo, ramene a la taille ou il s'affiche. Il est deja sur fond noir : pose sur
    le tableau, il n'a pas de bord - c'est le meme noir des deux cotes."""
    from PIL import Image
    im = Image.open(LOGO).convert('RGB')
    im.thumbnail((240, 240), Image.LANCZOS)
    tampon = io.BytesIO()
    im.save(tampon, 'PNG', optimize=True)
    return 'data:image/png;base64,' + base64.b64encode(tampon.getvalue()).decode()


def e(s):
    return (str(s).replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;')
            .replace('"', '&quot;'))


# ---------------------------------------------------------------- donnees
carte = json.load(open(CARTE, encoding='utf-8'))
par_nom = {c['nom']: c for c in carte['categories']}
R = carte['restaurant']


def flux(rubriques):
    """La suite des elements d'un ecran : un titre, ses lignes, le titre suivant."""
    out = []
    for nom in rubriques:
        c = par_nom[nom]
        out.append(('titre', nom))
        for a in c['articles']:
            out.append(('ligne', a['nom'], prix(a['prix'])))
    return out


def couper(items):
    """
    Deux colonnes aussi hautes l'une que l'autre.

    On essaie chaque point de coupure et on garde celui qui laisse la plus haute des
    deux colonnes la plus basse possible - c'est cette hauteur-la qui commandera la
    taille du texte. Une rubrique coupee en deux reprend son titre, suivi de
    << (suite) >> : sans cela, la deuxieme colonne commencerait par des lignes
    orphelines dont on ne saurait plus de quelle rubrique elles viennent.
    """
    def cout(bloc):
        return sum(TITRE if x[0] == 'titre' else 1 for x in bloc)

    meilleur, coupe = None, 0
    for i in range(1, len(items)):
        if items[i][0] == 'titre':
            g, d = items[:i], items[i:]
        else:
            # la colonne de droite reprend le titre de la rubrique en cours
            titre = next(x[1] for x in reversed(items[:i]) if x[0] == 'titre')
            g, d = items[:i], [('titre', titre + ' (suite)')] + items[i:]
        m = max(cout(g), cout(d))
        if meilleur is None or m < meilleur:
            meilleur, coupe, colonnes = m, i, (g, d)
    return colonnes, meilleur


CSS = """
:root { --or: #FECC30; --rouge: #F73123; --creme: #F6EFE3; --sourd: #8B8072; --nuit: #000000; }
* { box-sizing: border-box; }
html, body { margin: 0; height: 100%%; background: var(--nuit); }
body { display: flex; align-items: center; justify-content: center; overflow: hidden; }

/*
    Tout est ecrit en pixels d'un 1920 x 1080, puis multiplie par --u. Sur un
    televiseur, --u vaut ce qu'il faut pour remplir la dalle quelle que soit sa
    definition ; dans l'apercu du mur, il vaut le tiers.
*/
.tableau {
  --u: min(0.0520833vw, 0.0925926vh);
  width: calc(1920 * var(--u)); height: calc(1080 * var(--u));
  padding: calc(%(marge)d * var(--u));
  display: flex; flex-direction: column;
  font-family: 'Barlow Semi Condensed', 'Arial Narrow', sans-serif;
  color: var(--creme); background: var(--nuit);
  position: relative; overflow: hidden;
}

.entete { height: calc(%(entete)d * var(--u)); display: flex; align-items: center; gap: calc(20 * var(--u)); }
.entete .logo { height: calc(%(entete)d * var(--u)); width: auto; }
.entete .nom {
  font-family: Anton, 'Arial Narrow', sans-serif; line-height: .84;
  font-size: calc(52 * var(--u)); letter-spacing: .01em; color: var(--creme);
}
.entete .nom u { text-decoration: none; color: var(--rouge); }
.entete .lieu {
  font-size: calc(21 * var(--u)); letter-spacing: .22em; text-transform: uppercase;
  color: var(--sourd); margin-top: calc(6 * var(--u));
}
.entete .service {
  margin: 0 auto; font-size: calc(23 * var(--u)); letter-spacing: .3em;
  text-transform: uppercase; color: #5D554B;
}
.entete .tel { text-align: right; line-height: 1; }
.entete .tel b { font-family: Anton, sans-serif; font-size: calc(46 * var(--u)); color: var(--or); letter-spacing: .02em; }
.entete .tel i {
  display: block; font-style: normal; font-size: calc(19 * var(--u));
  letter-spacing: .2em; text-transform: uppercase; color: var(--sourd);
  margin-bottom: calc(5 * var(--u));
}

/* Le bandeau des pates : la seule chose que le client DOIT lire avant les prix. */
.bandeau {
  height: calc(%(bandeau)d * var(--u)); margin-top: calc(%(ecart)d * var(--u));
  background: var(--rouge); display: flex; align-items: center;
  padding: 0 calc(26 * var(--u)); gap: calc(30 * var(--u));
  font-size: calc(26 * var(--u)); color: #FFF0EC;
}
.bandeau .cle {
  font-family: Anton, sans-serif; font-size: calc(30 * var(--u));
  letter-spacing: .04em; color: #FFFFFF;
}
.bandeau .p { white-space: nowrap; }
.bandeau .p b { color: var(--or); font-weight: 600; }
.bandeau .sep { flex: 1; }
.bandeau .note { font-size: calc(23 * var(--u)); color: #FFD9D2; white-space: nowrap; }

.colonnes { flex: 1; display: flex; gap: calc(46 * var(--u)); margin-top: calc(%(ecart)d * var(--u)); }
.colonne { flex: 1; min-width: 0; }

.rubrique {
  font-family: Anton, 'Arial Narrow', sans-serif; color: var(--or);
  letter-spacing: .03em; text-transform: uppercase;
  height: calc(%(titre)s * var(--u)); display: flex; align-items: flex-end; gap: calc(14 * var(--u));
  font-size: calc(%(ftitre)s * var(--u));
  border-bottom: calc(2 * var(--u)) solid rgba(254, 204, 48, .32);
  margin-bottom: calc(%(apres)s * var(--u));
}
.rubrique span { flex: 1; }

.ligne {
  height: calc(%(ligne)s * var(--u)); display: flex; align-items: baseline; gap: calc(10 * var(--u));
}
.ligne .n { font-weight: 500; font-size: calc(%(fnom)s * var(--u)); white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
.ligne .pointille {
  flex: 1; height: calc(1 * var(--u)); margin-bottom: calc(%(fpoint)s * var(--u));
  background-image: radial-gradient(circle, rgba(246, 239, 227, .34) calc(1 * var(--u)), transparent calc(1 * var(--u)));
  background-size: calc(9 * var(--u)) calc(2 * var(--u)); background-repeat: repeat-x;
}
.ligne .p {
  font-weight: 600; font-size: calc(%(fprix)s * var(--u)); color: var(--or);
  font-variant-numeric: tabular-nums; white-space: nowrap;
}
"""

MODELE = """<div class="tableau">
  <div class="entete">
    <img class="logo" src="%(logo)s" alt="">
    <div>
      <div class="nom">NUMBER <u>ONE</u></div>
      <div class="lieu">%(lieu)s</div>
    </div>
    <div class="service">Sur place &middot; &Agrave; emporter &middot; Livraison</div>
    <div class="tel"><i>Commandes</i><b>%(tel)s</b></div>
  </div>
  <div class="bandeau">
    <span class="cle">P&Acirc;TES</span>
    <span class="p">Normale <b>prix affich&eacute;</b></span>
    <span class="p">C&eacute;r&eacute;ale <b>+1,000</b></span>
    <span class="p">Chia <b>+1,500</b></span>
    <span class="sep"></span>
    <span class="note">Double p&acirc;te : +1,000 &middot; en chia +1,500</span>
  </div>
  <div class="colonnes">
    <div class="colonne">%(g)s</div>
    <div class="colonne">%(d)s</div>
  </div>
</div>"""


def rendu_colonne(items, l):
    out = ''
    for x in items:
        if x[0] == 'titre':
            out += '<div class="rubrique"><span>%s</span></div>' % e(x[1].upper())
        else:
            out += ('<div class="ligne"><span class="n">%s</span>'
                    '<span class="pointille"></span><span class="p">%s</span></div>'
                    % (e(x[1]), e(x[2])))
    return out


def tableau(rubriques, logo):
    items = flux(rubriques)
    (g, d), haut = couper(items)
    # La hauteur de ligne descend juste ce qu'il faut pour que la plus haute des deux
    # colonnes tienne dans la dalle - jamais plus bas que necessaire.
    l = min(LIGNE_MAX, DISPO / haut)
    css = CSS % {
        'marge': MARGE, 'entete': ENTETE, 'bandeau': BANDEAU, 'ecart': ECART,
        'ligne': round(l, 2), 'titre': round(l * TITRE - l * .30, 2),
        'apres': round(l * .30, 2), 'ftitre': round(l * .74, 2),
        'fnom': round(l * .62, 2), 'fprix': round(l * .68, 2),
        'fpoint': round(l * .17, 2),
    }
    corps = MODELE % {'logo': logo, 'lieu': R['ville'], 'tel': R['telephone'],
                      'g': rendu_colonne(g, l), 'd': rendu_colonne(d, l)}
    return css, corps, l, len([x for x in items if x[0] == 'ligne'])


def polices(incruster):
    """
    Les polices : embarquees dans les fichiers des televiseurs, appelees en ligne dans
    l'apercu. Un tableau de menu doit s'afficher sans reseau ; un apercu, non.
    """
    if not incruster:
        return ('<link rel="stylesheet" href="https://fonts.googleapis.com/css2?'
                'family=Anton&family=Barlow+Semi+Condensed:wght@500;600&display=swap">')
    faces = [('Anton', 400, 'normal', 'anton.woff2'),
             ('Barlow Semi Condensed', 500, 'normal', 'barlow-r.woff2'),
             ('Barlow Semi Condensed', 600, 'normal', 'barlow-sb.woff2')]
    css = ''
    for nom, poids, style, f in faces:
        css += ("@font-face{font-family:'%s';font-weight:%d;font-style:%s;font-display:swap;"
                "src:url(%s) format('woff2')}\n"
                % (nom, poids, style, b64(os.path.join(POLICES, f), 'font/woff2')))
    return '<style>\n' + css + '</style>'


logo = logo_data()
sorties = []
for code, place, rubriques in ECRANS:
    css, corps, l, n = tableau(rubriques, logo)
    page = ('<!doctype html><html lang="fr"><head><meta charset="utf-8">'
            '<meta name="viewport" content="width=device-width,initial-scale=1">'
            '<title>NUMBER ONE - ecran %s</title>' % place
            + polices(True) + '<style>' + css + '</style></head><body>' + corps + '</body></html>')
    f = os.path.join(ICI, 'ecran-%s.html' % code)
    open(f, 'w', encoding='utf-8').write(page)
    sorties.append((place, rubriques, l, n, os.path.getsize(f), css, corps))

# ---------------------------------------------------------------- apercu du mur
mur = ('<title>Menu mural Number One</title>' + polices(False) + '<style>'
       + sorties[0][5] + """
body { margin: 0; background: #0b0b0c; color: #cfc7ba;
       font-family: 'Barlow Semi Condensed', system-ui, sans-serif; }
.mur { padding: 22px; }
.mur h1 { font-family: Anton, sans-serif; font-size: 22px; letter-spacing: .16em;
          text-transform: uppercase; color: #FECC30; margin: 0 0 4px; }
.mur .dit { font-size: 15px; color: #8B8072; margin: 0 0 18px; max-width: 88ch; }
.rangee { display: flex; gap: 14px; align-items: flex-start; overflow-x: auto; padding-bottom: 10px; }
.poste { flex: none; }
.poste .cadre { border: 3px solid #22201d; border-radius: 6px; background: #000; padding: 3px; width: fit-content; }
.poste .tableau { --u: 0.3333px; }
.poste .etiquette { font-size: 13px; letter-spacing: .18em; text-transform: uppercase;
                    color: #8B8072; margin: 8px 0 0; }
.poste .etiquette b { color: #F6EFE3; font-weight: 600; }
</style><div class="mur"><h1>Le mur, vu de la salle</h1>
<p class="dit">Les trois dalles a l'echelle, dans l'ordre ou elles sont accrochees.
Chaque tableau est un fichier a part, affiche en plein ecran sur son televiseur.</p>
<div class="rangee">""")
for i, (place, rubriques, l, n, taille, css, corps) in enumerate(sorties):
    mur += ('<div class="poste"><div class="cadre">%s</div>'
            '<p class="etiquette"><b>%s</b> &middot; %s &middot; %d articles</p></div>'
            % (corps, place, ' + '.join(rubriques), n))
mur += '</div></div>'
open(os.path.join(ICI, 'mur-apercu.html'), 'w', encoding='utf-8').write(mur)

print('Trois tableaux engendres depuis site/carte.json :')
for place, rubriques, l, n, taille, _, _ in sorties:
    print('  %-8s %-38s %3d articles, ligne de %4.1f px, %d Ko'
          % (place, ' + '.join(rubriques), n, l, taille // 1024))
print('  Total : %d articles.' % sum(s[3] for s in sorties))
print('  Apercu du mur : mur-apercu.html')
