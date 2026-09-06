# -*- coding: utf-8 -*-
"""
Engendre site/index.html depuis la carte de la caisse.

Pourquoi engendrer plutot qu'ecrire la page : les prix vivent en caisse. Recopier
110 articles a la main, c'est se condamner a un site qui ment des la premiere hausse.
On relance ce script, la page suit.

    python3 outils/generer-site.py

Regles tenues ici, et nulle part ailleurs :
  - un article sans prix (0) n'est PAS publie. Un menu public faux coute plus cher
    qu'un menu incomplet ;
  - trois colonnes de prix pour un article decline : Normale, Cereale, Chia. Le
    client lit son prix, il ne fait pas l'addition ;
  - la photo est cherchee par le nom de l'article, accents et casse ignores. Absente,
    la vignette laisse une initiale, jamais un cadre casse.
"""
import json, os, re, unicodedata, html

import base64

ICI = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
# La carte exportee du poste passe AVANT le fichier d'import : depuis ce chargement, des
# articles ont ete ajoutes a la main, des noms corriges, des prix rectifies et les
# categories reordonnees. Le fichier d'import ne sait rien de tout cela, la caisse si.
LIVE = os.path.join(ICI, 'carte-live.json')
IMPORT = os.path.join(ICI, '..', 'catalogs', 'number-one-2026.json')
IMG = os.path.join(ICI, 'img')

TEL_AFFICHE = '26 473 741'
TEL_LIEN = '+21626473741'
ADRESSE = 'Route Tenyour Km 5, Chihia, Sfax'
# Le lien donne par le client, pas une recherche : il mene a SA fiche, avec ses avis et
# son itineraire, la ou une recherche par adresse peut tomber sur le voisin.
MAPS = 'https://maps.app.goo.gl/KzE3dShY9iCtMxAB9'

def sans_accent(s):
    return ''.join(c for c in unicodedata.normalize('NFD', s)
                   if unicodedata.category(c) != 'Mn')

def slug(s):
    return re.sub(r'-+', '-', re.sub(r'[^a-z0-9]+', '-', sans_accent(s).lower())).strip('-')

def prix(v):
    return ('%.3f' % float(v)).replace('.', ',')

def e(s):
    return html.escape(str(s), quote=True)

PATES = ['Normale', 'Céréale', 'Chia']

def pate(nom):
    """
    Le nom d'une version, ramene a la pate qu'il designe : la caisse les appelle
    << Pate Normale >>, << Normale >> ou << Cereale >> selon la saisie, et les doubles
    portent le meme mot precede de << Double >>. Le site n'affiche que les trois
    simples, sur une ligne : un tableau a six colonnes ne se lit pas sur un telephone.
    """
    t = sans_accent(nom).lower().replace('pate', ' ').strip()
    if 'double' in t: return None
    if t.startswith('normal'): return 'Normale'
    if t.startswith('cereal'): return 'Céréale'
    if 'chia' in t: return 'Chia'
    return None

def depuis_le_poste(c):
    """La carte telle que la caisse l'a rendue, ramenee a la forme attendue ici."""
    noms = {v['id']: v['name'] for a in c.get('variants', []) for v in a.get('values', [])}
    cats = {x['id']: x['name'] for x in c['categories']}
    out = []
    for p in c['products']:
        pv = [{'value': pate(noms.get(v['variantValueId'], '')), 'price': v['price']}
              for v in (p.get('variantPrices') or [])]
        out.append({'name': p['name'], 'price': p['price'], 'category': cats.get(p['categoryId'], '?'),
                    'imageUrl': p.get('imageUrl'), 'variant': bool(p.get('variantId')),
                    'variantPrices': [v for v in pv if v['value'] and v['price'] is not None]})
    return [{'name': x['name']} for x in c['categories']], out

# ---------------------------------------------------------------- donnees
if os.path.exists(LIVE):
    categories, tous = depuis_le_poste(json.load(open(LIVE, encoding='utf-8')))
    source = 'carte-live.json (poste)'
else:
    carte = json.load(open(IMPORT, encoding='utf-8'))
    categories, tous = carte['categories'], carte['products']
    source = 'catalogs/number-one-2026.json (fichier d\'import)'

produits = [p for p in tous if float(p['price']) > 0]
ecartes = [p['name'] for p in tous if float(p['price']) <= 0]

photos = set()
if os.path.isdir(IMG):
    for f in os.listdir(IMG):
        base, ext = os.path.splitext(f)
        if ext.lower() in ('.png', '.jpg', '.jpeg', '.webp'):
            photos.add(base)

def poser_photos():
    """
    Les vignettes du poste, ecrites dans img/ pour les articles qui n'ont pas deja leur
    fichier. Un fichier deja present N'EST PAS ecrase : il vient du dossier d'origine,
    en pleine definition, alors que la caisse ne garde qu'une vignette de 240 px.
    """
    poses = 0
    for p in produits:
        u = p.get('imageUrl') or ''
        if not u.startswith('data:image/') or slug(p['name']) in photos: continue
        tete, _, data = u.partition(',')
        ext = tete.split('/')[1].split(';')[0].replace('jpeg', 'jpg')
        try: octets = base64.b64decode(data)
        except Exception: continue
        open(os.path.join(IMG, slug(p['name']) + '.' + ext), 'wb').write(octets)
        photos.add(slug(p['name']))
        poses += 1
    return poses

os.makedirs(IMG, exist_ok=True)
posees = poser_photos()

def prix_pates(p):
    m = {v['value']: v['price'] for v in p.get('variantPrices', [])}
    return [m.get(x) for x in PATES] if p.get('variant') else None

par_cat = {}
for p in produits:
    par_cat.setdefault(p['category'], []).append(p)
cats = [c for c in categories if par_cat.get(c['name'])]

# ---------------------------------------------------------------- rendu
def carte_article(p):
    """
    Une carte par article : photo, nom, et ses prix.

    La photo et l'initiale sont toujours toutes les deux posees, l'une par-dessus
    l'autre. Deposer un fichier dans site/img/ suffit donc a le voir, sans rien
    regenerer ; et un fichier absent laisse l'initiale, jamais un cadre casse.
    """
    pv = prix_pates(p)
    if pv and any(x is not None for x in pv):
        prix_html = '<div class="tarifs">' + ''.join(
            '<div class="tarif"><span>%s</span><b>%s</b></div>' % (e(n), prix(v) if v is not None else '&mdash;')
            for n, v in zip(PATES, pv)) + '</div>'
    else:
        prix_html = '<div class="tarifs un"><div class="tarif"><b>%s</b><i>DT</i></div></div>' % prix(p['price'])
    return (
      '<article class="fiche" data-nom="%s">'
        '<span class="photo"><i aria-hidden="true">%s</i>'
          '<img src="img/%s.png" alt="" loading="lazy" decoding="async" onerror="this.remove()"></span>'
        '<div class="corps"><h3>%s</h3>%s</div>'
      '</article>'
    ) % (e(sans_accent(p['name']).lower()), e(p['name'][0]), e(slug(p['name'])), e(p['name']), prix_html)


def panneau(c, premier):
    liste = par_cat[c['name']]
    return (
      '<section class="panneau" id="cat-%s" role="tabpanel" aria-labelledby="ong-%s"%s>'
        '<div class="panneau-tete"><h2>%s</h2><span>%d articles</span></div>'
        '<div class="grille">%s</div>'
      '</section>'
    ) % (slug(c['name']), slug(c['name']), '' if premier else ' hidden',
         e(c['name']), len(liste), ''.join(carte_article(p) for p in liste))


onglets = ''.join(
    '<button class="onglet%s" role="tab" id="ong-%s" aria-controls="cat-%s" aria-selected="%s" type="button">%s</button>'
    % (' on' if i == 0 else '', slug(c['name']), slug(c['name']), 'true' if i == 0 else 'false', e(c['name']))
    for i, c in enumerate(cats))

panneaux = ''.join(panneau(c, i == 0) for i, c in enumerate(cats))

PAGE = open(os.path.join(ICI, 'outils', 'modele.html'), encoding='utf-8').read()
for cle, valeur in (('{{TEL}}', TEL_AFFICHE), ('{{LIEN}}', TEL_LIEN), ('{{ADRESSE}}', ADRESSE),
                    ('{{MAPS}}', MAPS), ('{{ONGLETS}}', onglets), ('{{PANNEAUX}}', panneaux),
                    ('{{NB}}', str(len(produits)))):
    PAGE = PAGE.replace(cle, valeur)

open(os.path.join(ICI, 'index.html'), 'w', encoding='utf-8').write(PAGE)
print('Source : %s' % source)
print('%d articles publies, %d ecartes faute de prix : %s'
      % (len(produits), len(ecartes), ', '.join(ecartes)))
manquantes = [p['name'] for p in produits if slug(p['name']) not in photos]
print('%d categories. Photos : %d dans site/img/ (%d reprises du poste), %d manquantes.'
      % (len(cats), len(produits) - len(manquantes), posees, len(manquantes)))
if manquantes: print('Sans photo : ' + ', '.join(manquantes))
