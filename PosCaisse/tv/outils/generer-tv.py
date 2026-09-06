# -*- coding: utf-8 -*-
"""
Engendre les trois tableaux de menu des televiseurs de la salle.

    python3 outils/generer-tv.py

Trois ecrans de 40 pouces cote a cote, en hauteur, au-dessus du comptoir. Ce n'est pas
un site retreci : on lit ces tableaux debout, a trois ou quatre metres, en quelques
secondes, sans pouvoir cliquer ni faire defiler. Tout en decoule.

CE QUI EST DECIDE ICI, ET POURQUOI

  Les trois prix sur la ligne : normale, cereale, chia. Un client qui doit ajouter
  +1,000 de tete devant un tableau hesite, et un client qui hesite ne commande pas. Les
  colonnes ne coutent rien a la lisibilite : c'est la HAUTEUR de la ligne qui commande
  la taille du texte, et elle ne change pas - les trois prix tiennent dans la largeur
  qui restait libre a droite. Seule la double pate reste une regle, dans le bandeau
  rouge : elle vaut pour toute la carte (+1,000, et +1,500 en chia).

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
FONDS = os.path.join(ICI, 'fond')          # ecran-1-gauche.jpg, ecran-2-centre.jpg, ...
OPACITE = 0.15                              # ce qui reste de l'image sous le texte
POLICES = os.path.join(ICI, 'outils', 'polices')

# Repartition des rubriques sur les trois ecrans. L'ecran de gauche ouvre sur les
# compositions de la maison - c'est par la que le regard entre.
#
# Un ecran porte soit une suite de rubriques en deux colonnes, soit une MATRICE : les
# memes garnitures a gauche, et a droite un bloc de trois prix par famille de fromage.
# Deux ecrans sur trois sont des matrices, parce que la carte est batie ainsi : les
# memes 19 garnitures se declinent nature, au fromage, a la mozarilla et a la mozarilla
# 3arbi. Les ecrire quatre fois en listes faisait lire quatre fois la meme suite de
# noms, et obligeait a chercher d'une colonne a l'autre pour comparer deux versions.
#
ECRANS = [
    ('1-gauche', 'Gauche', {'matrice': ['Classic', 'Fromage']}),
    ('2-centre', 'Centre', {'matrice': ['Mozarilla', 'Mozarilla 3arbi']}),
    ('3-droite', 'Droite', ['Spécial', 'Lablebi', 'Boissons', 'Extras']),
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
# Matrice : largeur d'une colonne de prix, et ecart entre deux familles, en hauteurs de
# ligne. L'ecart vaut presque une colonne entiere - c'est lui, plus que le filet, qui
# dit ou finit une famille ; la place vient du nom, qui en avait de reste.
MCOL, MECART = 3.55, 2.8


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


def fond_data(code):
    """
    L'image de fond d'un ecran, si elle existe.

    Elle est ramenee a 1600 px et compressee : elle ne se voit qu'a 15 %, un fichier de
    trois megaoctets n'y ajouterait rien. Absente, l'ecran reste noir - le tableau ne
    depend jamais d'elle.
    """
    from PIL import Image
    for ext in ('jpg', 'jpeg', 'png', 'webp'):
        chemin = os.path.join(FONDS, 'ecran-%s.%s' % (code, ext))
        if os.path.exists(chemin):
            im = Image.open(chemin).convert('RGB')
            im.thumbnail((1600, 1600), Image.LANCZOS)
            t = io.BytesIO()
            im.save(t, 'JPEG', quality=74, optimize=True)
            return 'data:image/jpeg;base64,' + base64.b64encode(t.getvalue()).decode(), len(t.getvalue())
    return None, 0


def e(s):
    return (str(s).replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;')
            .replace('"', '&quot;'))


# ---------------------------------------------------------------- donnees
carte = json.load(open(CARTE, encoding='utf-8'))
par_nom = {c['nom']: c for c in carte['categories']}
R = carte['restaurant']


def flux(rubriques):
    """
    La suite des elements d'un ecran : un titre, ses lignes, le titre suivant.

    Une ligne porte soit ses trois prix de pate, soit un prix unique - lablebi,
    boissons et extras ne se declinent pas. Le titre sait lequel des deux vient, pour
    poser les intitules des colonnes seulement quand il y a des colonnes.
    """
    out = []
    for nom in rubriques:
        c = par_nom[nom]
        declinee = any(a.get('prixParPate') for a in c['articles'])
        out.append(('titre', nom, declinee))
        for a in c['articles']:
            pp = a.get('prixParPate')
            if pp:
                out.append(('ligne', a['nom'], [prix(pp[x]) for x in carte['pates']]))
            else:
                out.append(('ligne', a['nom'], [prix(a['prix'])]))
    return out


def garniture(nom, famille):
    """Le nom d'un article, prive de sa famille : << Omlette Mozarilla 3arbi Kwika >>
    redevient << Omlette Kwika >>. C'est la colonne de gauche de la matrice."""
    return nom.replace(famille + ' ', '').replace(' ' + famille, '').strip()


def matrice(familles):
    """
    Les garnitures a gauche, un bloc de trois prix par famille a droite.

    Les familles doivent porter les MEMES garnitures ; l'ordre dans lequel elles sont
    rangees en caisse, lui, n'a pas d'importance - les lignes s'apparient par le nom de
    la garniture, pas par leur rang. Deplacer un article dans le back-office ne peut
    donc pas decaler une colonne d'une ligne, ce qui ferait comparer deux plats
    differents sans que rien ne le signale.

    L'ordre affiche est celui de la premiere famille. Ce qui manque d'un cote arrete le
    script au lieu de publier un tableau troue.
    """
    tables = [{garniture(a['nom'], f): a for a in par_nom[f]['articles']} for f in familles]
    base = [garniture(a['nom'], familles[0]) for a in par_nom[familles[0]]['articles']]
    for f, t in zip(familles[1:], tables[1:]):
        manque = set(base) ^ set(t)
        if manque:
            raise SystemExit(
                'ARRET : << %s >> et << %s >> ne portent pas les memes garnitures.\n'
                '        Seulement d\'un cote : %s'
                % (familles[0], f, ', '.join(sorted(manque))))
    lignes = []
    for nom in base:
        blocs = []
        for t in tables:
            pp = t[nom].get('prixParPate') or {}
            blocs.append([prix(pp[x]) if pp.get(x) is not None else '&mdash;'
                          for x in carte['pates']])
        lignes.append((nom, blocs))
    return lignes


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
            t = next(x for x in reversed(items[:i]) if x[0] == 'titre')
            g, d = items[:i], [('titre', t[1] + ' (suite)', t[2])] + items[i:]
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

/*
    L'image de fond. Elle habite le bas de la dalle - la ou les colonnes s'arretent et
    ou le noir restait vide - et s'efface en montant : au niveau des prix il n'en reste
    presque rien, et au niveau du bandeau rouge, rien du tout. A 15 %%, elle rechauffe
    le tableau sans jamais disputer un chiffre.
*/
.fond {
  position: absolute; inset: 0; z-index: 0; pointer-events: none;
  background-size: cover; background-position: center bottom;
  opacity: %(opacite)s;
  -webkit-mask-image: linear-gradient(to top, #000 0%%, #000 34%%, rgba(0,0,0,.30) 66%%, transparent 88%%);
  mask-image: linear-gradient(to top, #000 0%%, #000 34%%, rgba(0,0,0,.30) 66%%, transparent 88%%);
}
.entete, .bandeau, .colonnes { position: relative; z-index: 1; }

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

.rubrique, .ligne {
  display: grid;
  grid-template-columns: minmax(0, 1fr) repeat(3, calc(%(colonne)s * var(--u)));
  gap: calc(10 * var(--u)); align-items: baseline;
}

.rubrique {
  font-family: Anton, 'Arial Narrow', sans-serif; color: var(--or);
  letter-spacing: .03em; text-transform: uppercase;
  height: calc(%(titre)s * var(--u)); align-items: flex-end;
  font-size: calc(%(ftitre)s * var(--u));
  border-bottom: calc(3 * var(--u)) solid rgba(254, 204, 48, .55);
  margin-bottom: calc(%(apres)s * var(--u));
}
/* Les intitules de colonnes se posent au-dessus des prix qu'ils nomment, pas ailleurs :
   c'est la meme grille que les lignes qui les place. */
.rubrique .col {
  font-family: 'Barlow Semi Condensed', sans-serif; font-weight: 600;
  font-size: calc(%(fcol)s * var(--u)); letter-spacing: .12em;
  color: var(--sourd); text-align: right;
}

.ligne { height: calc(%(ligne)s * var(--u)); }
.ligne .n {
  font-weight: 500; font-size: calc(%(fnom)s * var(--u));
  display: flex; align-items: baseline; gap: calc(10 * var(--u)); min-width: 0;
}
.ligne .n .pointille {
  flex: 1; height: calc(1 * var(--u)); align-self: center; margin-top: calc(%(fpoint)s * var(--u));
  background-image: radial-gradient(circle, rgba(246, 239, 227, .30) calc(1 * var(--u)), transparent calc(1 * var(--u)));
  background-size: calc(9 * var(--u)) calc(2 * var(--u)); background-repeat: repeat-x;
}
.ligne .p {
  font-weight: 600; font-size: calc(%(fprix)s * var(--u)); color: var(--or);
  font-variant-numeric: tabular-nums; white-space: nowrap; text-align: right;
}
/* Un article qui ne se decline pas garde un seul prix, aligne sur la derniere colonne :
   trois cases vides feraient croire a des prix manquants. */
.ligne .p.seul { grid-column: 2 / -1; }

/*
    La matrice : les garnitures a gauche, un bloc de trois prix par famille a droite.
    Une seule grille tient les trois rangees - le nom de la famille, les intitules de
    pate, les prix - donc rien ne peut glisser d'une colonne. L'ecart entre les deux
    blocs est plus large que celui qui separe les pates : c'est lui qui dit ou finit
    une famille et ou commence l'autre, sans avoir a tracer un trait.
*/
.colonnes.seule { display: block; }
.matrice { position: relative; }

/*
    Un filet entre les deux familles. L'ecart seul suffisait a l'oeil de pres, pas a
    quatre metres : a cette distance les six chiffres d'une ligne se lisent comme une
    seule suite, et on cherche ou finit la mozarilla. Le filet s'eteint vers le bas -
    il sert a ouvrir la lecture, pas a couper le tableau en deux.
*/
.matrice .separateur {
  position: absolute; top: calc((%(titre)s - 3) * var(--u)); bottom: calc(4 * var(--u));
  right: calc(%(msep)s * var(--u)); width: calc(3 * var(--u));
  background: linear-gradient(to bottom, rgba(254, 204, 48, .55), rgba(254, 204, 48, .07));
}
.matrice .rubrique, .matrice .soustitre, .matrice .ligne {
  display: grid;
  grid-template-columns: minmax(0, 1fr) repeat(3, calc(%(mcol)s * var(--u)))
                         calc(%(mecart)s * var(--u)) repeat(3, calc(%(mcol)s * var(--u)));
  gap: calc(10 * var(--u)); align-items: baseline;
}
/* La colonne d'ecart n'est qu'un vide : les cases sautent par-dessus. */
.matrice .ligne .p:nth-child(5), .matrice .soustitre .col:nth-child(5) { grid-column: 6; }
.matrice .ligne .p:nth-child(6), .matrice .soustitre .col:nth-child(6) { grid-column: 7; }
.matrice .ligne .p:nth-child(7), .matrice .soustitre .col:nth-child(7) { grid-column: 8; }

.matrice .rubrique .groupe {
  font-family: Anton, 'Arial Narrow', sans-serif; font-size: calc(%(fgroupe)s * var(--u));
  color: var(--or); letter-spacing: .03em; text-align: center;
}
.matrice .rubrique .groupe:nth-child(2) { grid-column: 2 / 5; }
.matrice .rubrique .groupe:nth-child(3) { grid-column: 6 / 9; }
.matrice .soustitre { height: calc(%(msous)s * var(--u)); margin-bottom: calc(%(apres)s * var(--u)); }
.matrice .soustitre .col {
  font-family: 'Barlow Semi Condensed', sans-serif; font-weight: 600;
  font-size: calc(%(fcol)s * var(--u)); letter-spacing: .12em;
  color: var(--sourd); text-align: right;
}

"""

MODELE = """<div class="tableau">%(fond)s
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
    <span class="cle">DOUBLE P&Acirc;TE</span>
    <span class="p">Normale <b>+1,000</b></span>
    <span class="p">C&eacute;r&eacute;ale <b>+1,000</b></span>
    <span class="p">Chia <b>+1,500</b></span>
    <span class="sep"></span>
    <span class="note">Prix en dinars tunisiens</span>
  </div>
  %(interieur)s
</div>"""


def rendu_colonne(items, l):
    out = ''
    for x in items:
        if x[0] == 'titre':
            cols = ''.join('<span class="col">%s</span>' % e(p) for p in carte['pates']) if x[2] else ''
            out += '<div class="rubrique"><span class="t">%s</span>%s</div>' % (e(x[1].upper()), cols)
        else:
            p = x[2]
            if len(p) == 1:
                cases = '<span class="p seul">%s</span>' % e(p[0])
            else:
                cases = ''.join('<span class="p">%s</span>' % e(v) for v in p)
            out += ('<div class="ligne"><span class="n">%s<i class="pointille"></i></span>%s</div>'
                    % (e(x[1]), cases))
    return out


def rendu_matrice(familles, lignes):
    groupes = ''.join('<span class="groupe">%s</span>' % e(f.upper()) for f in familles)
    pates = ''.join(''.join('<span class="col">%s</span>' % e(p) for p in carte['pates'])
                    for _ in familles)
    corps = ''
    for nom, blocs in lignes:
        cases = ''.join(''.join('<span class="p">%s</span>' % v for v in b) for b in blocs)
        corps += ('<div class="ligne"><span class="n">%s<i class="pointille"></i></span>%s</div>'
                  % (e(nom), cases))
    return ('<div class="matrice"><i class="separateur"></i>'
            '<div class="rubrique"><span class="t">GARNITURE</span>%s</div>'
            '<div class="soustitre"><span></span>%s</div>%s</div>'
            % (groupes, pates, corps))


def contenu(rubriques):
    """Ce qu'un ecran doit poser, et ce que cela coute en hauteurs de ligne."""
    if isinstance(rubriques, dict):
        lignes = matrice(rubriques['matrice'])
        # Deux rangees d'en-tete au lieu d'une : la famille, puis les trois pates.
        return ('matrice', (rubriques['matrice'], lignes), len(lignes) + TITRE + 0.85)
    items = flux(rubriques)
    colonnes, haut = couper(items)
    return ('liste', (items, colonnes), haut)


def tableau(rubriques, logo, fond, l):
    """
    Un tableau, a la hauteur de ligne COMMUNE aux trois ecrans.

    Elle est commune, et non calculee ecran par ecran, parce que les trois dalles sont
    cote a cote sur le meme mur : un titre de 30 px a gauche et de 28 a droite ne se
    remarque pas ecran par ecran, mais se voit des qu'on prend du recul. L'ecran le plus
    charge decide donc pour les trois, et les autres finissent simplement plus haut -
    du noir en bas, la ou l'image de fond vit deja.
    """
    genre, charge, _ = contenu(rubriques)
    matricielle = genre == 'matrice'
    if matricielle:
        familles, lignes = charge
    else:
        items, (g, d) = charge
    css = CSS % {
        'marge': MARGE, 'entete': ENTETE, 'bandeau': BANDEAU, 'ecart': ECART,
        'ligne': round(l, 2), 'titre': round(l * TITRE - l * .30, 2),
        'apres': round(l * .30, 2), 'ftitre': round(l * .74, 2),
        'fnom': round(l * .62, 2), 'fprix': round(l * .66, 2),
        # Les intitules de pate se lisent de la salle, eux aussi : ils disent quelle
        # colonne on regarde, et une ligne de six chiffres sans eux ne veut rien dire.
        'fpoint': round(l * .06, 2), 'fcol': round(l * .46, 2),
        'colonne': round(l * 2.55, 2), 'opacite': OPACITE,
        # La matrice n'a que 19 lignes la ou une liste en aurait 38. La place gagnee
        # passe dans la LARGEUR des colonnes et dans l'ecart entre les deux familles,
        # pas dans la taille du texte : celle-la est la meme sur les trois ecrans.
        'mcol': round(l * MCOL, 2), 'mecart': round(l * MECART, 2),
        # Le filet qui separe les deux familles, pose au milieu de la colonne d'ecart :
        # trois colonnes de prix, leurs deux intervalles, puis la moitie de l'ecart.
        'msep': round(l * MCOL * 3 + 30 + l * MECART / 2, 2),
        'fgroupe': round(l * .78, 2), 'msous': round(l * 1.0, 2),
    }
    couche = ('<div class="fond" style="background-image:url(%s)"></div>' % fond) if fond else ''
    if matricielle:
        interieur = '<div class="colonnes seule">%s</div>' % rendu_matrice(familles, lignes)
        articles = len(lignes) * len(familles)
    else:
        interieur = ('<div class="colonnes"><div class="colonne">%s</div>'
                     '<div class="colonne">%s</div></div>'
                     % (rendu_colonne(g, l), rendu_colonne(d, l)))
        articles = len([x for x in items if x[0] == 'ligne'])
    corps = MODELE % {'logo': logo, 'lieu': R['ville'], 'tel': R['telephone'],
                      'fond': couche, 'interieur': interieur}
    return css, corps, l, articles


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

# Une seule hauteur de ligne pour les trois ecrans : celle que le plus charge supporte.
LIGNE = min(LIGNE_MAX, DISPO / max(contenu(r)[2] for _, _, r in ECRANS))

sorties = []
for code, place, rubriques in ECRANS:
    fond, poids_fond = fond_data(code)
    css, corps, l, n = tableau(rubriques, logo, fond, LIGNE)
    page = ('<!doctype html><html lang="fr"><head><meta charset="utf-8">'
            '<meta name="viewport" content="width=device-width,initial-scale=1">'
            '<title>NUMBER ONE - ecran %s</title>' % place
            + polices(True) + '<style>' + css + '</style></head><body>' + corps + '</body></html>')
    f = os.path.join(ICI, 'ecran-%s.html' % code)
    open(f, 'w', encoding='utf-8').write(page)
    # Le meme tableau, seul, pour se regarder en grand : polices en ligne, pas de
    # doctype - c'est un apercu, pas le fichier qui tourne sur la dalle.
    open(os.path.join(ICI, 'apercu-ecran-%s.html' % code), 'w', encoding='utf-8').write(
        '<title>Tableau %s Number One</title>' % place.lower()
        + polices(False) + '<style>' + css
        + 'body{background:#000;height:100vh}</style>' + corps)
    sorties.append((place, rubriques, l, n, os.path.getsize(f), css, corps, poids_fond))

# ---------------------------------------------------------------- apercu du mur
mur = ('<title>Menu mural Number One</title>' + polices(False) + '<style>'
       + sorties[0][5] + """
body { margin: 0; background: #0b0b0c; color: #cfc7ba;
       font-family: 'Barlow Semi Condensed', system-ui, sans-serif; }
.mur { padding: 22px; }
.mur h1 { font-family: Anton, sans-serif; font-size: 22px; letter-spacing: .16em;
          text-transform: uppercase; color: #FECC30; margin: 0 0 4px; }
.mur .dit { font-size: 15px; color: #8B8072; margin: 0 0 18px; max-width: 88ch; }
.rangee { display: flex; gap: 14px; align-items: flex-start; }
.poste { flex: none; }
.poste .cadre { border: 3px solid #22201d; border-radius: 6px; background: #000; padding: 3px; width: fit-content; }
.poste .tableau { --u: calc((100vw - 108px) / 5760); }
.poste .etiquette { font-size: 13px; letter-spacing: .18em; text-transform: uppercase;
                    color: #8B8072; margin: 8px 0 0; }
.poste .etiquette b { color: #F6EFE3; font-weight: 600; }
</style><div class="mur"><h1>Le mur, vu de la salle</h1>
<p class="dit">Les trois dalles a l'echelle, dans l'ordre ou elles sont accrochees.
Chaque tableau est un fichier a part, affiche en plein ecran sur son televiseur.</p>
<div class="rangee">""")
for i, (place, rubriques, l, n, taille, css, corps, pf) in enumerate(sorties):
    mur += ('<div class="poste"><div class="cadre">%s</div>'
            '<p class="etiquette"><b>%s</b> &middot; %s &middot; %d articles</p></div>'
            % (corps, place, ' + '.join(rubriques), n))
mur += '</div></div>'
open(os.path.join(ICI, 'mur-apercu.html'), 'w', encoding='utf-8').write(mur)

print('Trois tableaux engendres depuis site/carte.json :')
for place, rubriques, l, n, taille, _, _, pf in sorties:
    print('  %-8s %-38s %3d articles, ligne de %4.1f px, %d Ko%s'
          % (place, ' + '.join(rubriques), n, l, taille // 1024,
             (', fond %d Ko' % (pf // 1024)) if pf else ', SANS FOND'))
print('  Total : %d articles.' % sum(s[3] for s in sorties))
print('  Apercu du mur : mur-apercu.html')
