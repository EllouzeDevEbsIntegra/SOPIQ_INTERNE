# -*- coding: utf-8 -*-
"""
Engendre site/index.html depuis la carte de la caisse.

Pourquoi engendrer plutot qu'ecrire la page : les prix vivent en caisse. Recopier
111 articles a la main, c'est se condamner a un site qui ment des la premiere hausse.
On relance ce script, la page suit.

    python3 outils/generer-site.py

Deux fichiers sortent :
  - index.html          la page, qui va chercher ses photos dans img/ ;
  - apercu-artifact.html la meme, photos embarquees, pour la publier d'un bloc.

Regles tenues ici, et nulle part ailleurs :
  - un article sans prix (0) n'est PAS publie. Un menu public faux coute plus cher
    qu'un menu incomplet ;
  - trois colonnes de prix pour un article decline : Normale, Cereale, Chia. Les
    doubles pates ne font pas trois colonnes de plus - la regle est dite une fois en
    tete de page, et chaque prix porte sa valeur double, que la case a cocher revele ;
  - la photo est cherchee par le nom de l'article, accents et casse ignores. Absente,
    la vignette laisse un logement vide, jamais un cadre casse.
"""
import json, os, re, base64, unicodedata, html, datetime

ICI = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
# La carte exportee du poste passe AVANT le fichier d'import : depuis ce chargement, des
# articles ont ete ajoutes a la main, des noms corriges, des prix rectifies et les
# categories reordonnees. Le fichier d'import ne sait rien de tout cela, la caisse si.
LIVE = os.path.join(ICI, 'carte-live.json')
RETOUCHES = os.path.join(ICI, 'retouches.json')
IMPORT = os.path.join(ICI, '..', 'catalogs', 'number-one-2026.json')
IMG = os.path.join(ICI, 'img')

TEL_AFFICHE = '26 473 741'
TEL_LIEN = '+21626473741'
ADRESSE = 'Route Tenyour Km 5, Chihia, Sfax'
# Le lien donne par le client, pas une recherche : il mene a SA fiche, avec ses avis et
# son itineraire, la ou une recherche par adresse peut tomber sur le voisin.
MAPS = 'https://maps.app.goo.gl/KzE3dShY9iCtMxAB9'

# Ce que chaque rubrique contient, dit en une ligne. La caisse ne porte que des noms :
# << Fromage >> ne dit pas a un client que ce sont les memes sandwichs, au fromage.
DITS = {
    'Classic':          'La garniture seule, ou avec l’omelette.',
    'Mozarilla':        'Les mêmes, avec la mozarilla.',
    'Mozarilla 3arbi':  'Les mêmes, avec la mozarilla 3arbi.',
    'Fromage':          'Les mêmes, avec le fromage.',
    'Spécial':     'Les compositions de la maison.',
    'Lablebi':          'Le bol de pois chiches, servi chaud.',
    'Boissons':         'Fraîches.',
    'Extras':           'À ajouter dans n’importe quel sandwich.',
}

PATES = ['Normale', 'Céréale', 'Chia']
CLE = {'Normale': 'normale', 'Céréale': 'cereale', 'Chia': 'chia'}
# Ecart de la double pate, verifie sur les 86 articles declines de la carte : partout
# +1,000 en normale et cereale, +1,500 en chia.
DOUBLE = {'Normale': 1.0, 'Céréale': 1.0, 'Chia': 1.5}


def sans_accent(s):
    return ''.join(c for c in unicodedata.normalize('NFD', s)
                   if unicodedata.category(c) != 'Mn')


def slug(s):
    return re.sub(r'-+', '-', re.sub(r'[^a-z0-9]+', '-', sans_accent(s).lower())).strip('-')


def prix(v):
    return ('%.3f' % float(v)).replace('.', ',')


def e(s):
    return html.escape(str(s), quote=True)


def pate(nom):
    """
    Le nom d'une version, ramene a la pate qu'il designe : la caisse les appelle
    << Pate Normale >>, << Normale >> ou << Cereale >> selon la saisie, et les doubles
    portent le meme mot precede de << Double >>. Le site n'affiche que les trois
    simples : six colonnes ne se lisent pas sur un telephone, et l'ecart des doubles
    est le meme partout - il se dit une fois, en tete de page.
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

def retoucher(tous):
    """
    Les corrections decidees pour la carte publiee, en attendant qu'elles soient faites
    dans la caisse.

    Elles vivent dans un fichier a part, nommees une par une, et le script dit a chaque
    passage lesquelles il a appliquees - et lesquelles sont devenues inutiles parce que
    la caisse les porte enfin. Sans cela, une correction faite ici disparaitrait au
    prochain export sans que personne ne s'en apercoive, ou survivrait des annees apres
    etre devenue fausse.
    """
    if not os.path.exists(RETOUCHES): return tous, [], []
    r = json.load(open(RETOUCHES, encoding='utf-8'))
    faites, inutiles = [], []

    retirer = set(r.get('retirer', []))
    presents = {p['name'] for p in tous}
    for nom in sorted(retirer):
        (faites if nom in presents else inutiles).append('retire   ' + nom)
    tous = [p for p in tous if p['name'] not in retirer]

    for d in r.get('deplacer', []):
        cible = next((p for p in tous if p['name'] == d['article']), None)
        if cible is None:
            inutiles.append('deplace  %s (absent de la carte)' % d['article'])
        elif cible['category'] == d['vers']:
            inutiles.append('deplace  %s (deja dans %s)' % (d['article'], d['vers']))
        else:
            faites.append('deplace  %s : %s -> %s' % (d['article'], cible['category'], d['vers']))
            cible['category'] = d['vers']
            cible['_tete'] = d.get('position') == 'debut'
    return tous, faites, inutiles


tous, faites, inutiles = retoucher(tous)
produits = [p for p in tous if float(p['price']) > 0]
ecartes = [p['name'] for p in tous if float(p['price']) <= 0]

photos = {}
if os.path.isdir(IMG):
    for f in sorted(os.listdir(IMG)):
        base, ext = os.path.splitext(f)
        if ext.lower() in ('.jpg', '.jpeg', '.png', '.webp') and base not in photos:
            photos[base] = f


def poser_photos():
    """
    Les vignettes du poste, ecrites dans img/ pour les articles qui n'ont pas deja leur
    fichier. Un fichier deja present N'EST PAS ecrase : il peut venir du dossier
    d'origine, en pleine definition, alors que la caisse n'en garde qu'une vignette.
    """
    poses = 0
    for p in produits:
        u = p.get('imageUrl') or ''
        if not u.startswith('data:image/') or slug(p['name']) in photos: continue
        tete, _, data = u.partition(',')
        ext = tete.split('/')[1].split(';')[0].replace('jpeg', 'jpg')
        try: octets = base64.b64decode(data)
        except Exception: continue
        nom = slug(p['name']) + '.' + ext
        open(os.path.join(IMG, nom), 'wb').write(octets)
        photos[slug(p['name'])] = nom
        poses += 1
    return poses


os.makedirs(IMG, exist_ok=True)
posees = poser_photos()


def prix_pates(p):
    m = {v['value']: v['price'] for v in p.get('variantPrices', [])}
    return [m.get(x) for x in PATES] if p.get('variant') else None


par_cat = {}
for p in produits:
    # Un article deplace en tete y va vraiment : range a la suite, il se lirait comme
    # une exception ajoutee apres coup.
    if p.get('_tete'): par_cat.setdefault(p['category'], []).insert(0, p)
    else: par_cat.setdefault(p['category'], []).append(p)
cats = [c for c in categories if par_cat.get(c['name'])]


# ---------------------------------------------------------------- rendu
# L'article mis en couverture. S'il quittait la carte, la page prendrait le premier
# venu plutot que de se casser - une couverture vide se voit, une page blanche aussi.
VEDETTE = 'Number One'


def vignette(p, taille=146):
    """
    La photo d'un article, ou son initiale. Les photos du poste sont detourees sur
    blanc : la carte les fond dans le papier (mix-blend-mode), et un article sans photo
    laisse une lettre claire, jamais un cadre casse.
    """
    f = photos.get(slug(p['name']))
    if not f:
        return '<div class="sans-photo" aria-hidden="true">%s</div>' % e(p['name'][:1].upper())
    return ('<div class="photo"><img src="{{IMG:%s}}" alt="" loading="lazy" decoding="async" '
            'width="%d" height="%d"></div>' % (f, taille, taille))


def tarifs(p):
    """
    Trois colonnes pour un article decline, une seule sinon. Chaque prix porte aussi sa
    valeur en double pate (data-d) : la case a cocher echange le texte, sans recharger
    ni recalculer quoi que ce soit.
    """
    pv = prix_pates(p)
    if pv and any(x is not None for x in pv):
        cases = ''
        for n, v in zip(PATES, pv):
            if v is None:
                cases += ('<div class="tarif" data-pate="%s"><dt>%s</dt><dd>&mdash;</dd></div>'
                          % (CLE[n], e(n)))
            else:
                cases += ('<div class="tarif" data-pate="%s"><dt>%s</dt>'
                          '<dd data-p="%s" data-d="%s">%s</dd></div>'
                          % (CLE[n], e(n), prix(v), prix(float(v) + DOUBLE[n]), prix(v)))
        return '<dl class="tarifs">%s</dl>' % cases
    return ('<dl class="tarifs un"><div class="tarif"><dt>Prix</dt><dd>%s DT</dd></div></dl>'
            % prix(p['price']))


def plat(p):
    """La carte d'un article : sa photo, son nom, ses prix. data-nom sert a la recherche."""
    return ('<article class="plat" data-nom="%s">%s<div class="haut"><h4>%s</h4></div>%s</article>'
            % (e(sans_accent(p['name']).lower()), vignette(p), e(p['name']), tarifs(p)))


def panneau(c, rang):
    """Une rubrique, numerotee : les huit se suivent, on n'en cache aucune."""
    liste = par_cat[c['name']]
    dit = DITS.get(c['name'], '')
    return (
      '<section class="rubrique" id="cat-%s">'
        '<div class="rubrique-tete">'
          '<div class="ligne"><span class="numero">%02d</span><h3>%s</h3>'
          '<span class="combien">%d articles</span></div>%s'
        '</div>'
        '<div class="grille">%s</div>'
      '</section>'
    ) % (slug(c['name']), rang, e(c['name']), len(liste),
         ('<p class="dit">%s</p>' % e(dit)) if dit else '',
         ''.join(plat(p) for p in liste))


def vedette():
    """
    La couverture : un article de la maison, incline comme une photo posee sur la table.
    Le prix montre est celui de la pate normale - le plus bas, celui qu'on annonce.
    """
    p = next((x for x in produits if x['name'] == VEDETTE), produits[0])
    pv = prix_pates(p)
    montant = pv[0] if pv and pv[0] is not None else p['price']
    f = photos.get(slug(p['name']))
    img = ('<img src="{{IMG:%s}}" alt="%s" width="280" height="280">' % (f, e(p['name']))) if f else ''
    return (
      '<figure class="vedette">'
        '<div class="haut"><span>La maison</span><span>%s</span></div>%s'
        '<figcaption><strong>%s</strong><span class="prix">%s DT</span></figcaption>'
      '</figure>'
    ) % (e(p['category']), img, e(p['name']), prix(montant))


# Les rubriques sont des ancres, pas des onglets : la page entiere se fait defiler, et
# le rail sert de raccourci. Le nombre d'articles y est dit, pour savoir ou l'on va.
onglets = ''.join(
    '<a class="rubrique-lien%s" href="#cat-%s">%s<span>%d</span></a>'
    % (' on' if i == 0 else '', slug(c['name']), e(c['name']), len(par_cat[c['name']]))
    for i, c in enumerate(cats))

panneaux = ''.join(panneau(c, i + 1) for i, c in enumerate(cats))

MOIS = ['janvier', 'fevrier', 'mars', 'avril', 'mai', 'juin', 'juillet', 'aout',
        'septembre', 'octobre', 'novembre', 'decembre']
h = datetime.date.today()
CORPS = open(os.path.join(ICI, 'outils', 'modele.html'), encoding='utf-8').read()
for cle, valeur in (('{{TEL}}', TEL_AFFICHE), ('{{LIEN}}', TEL_LIEN), ('{{ADRESSE}}', ADRESSE),
                    ('{{MAPS}}', MAPS), ('{{ONGLETS}}', onglets), ('{{PANNEAUX}}', panneaux),
                    ('{{VEDETTE}}', vedette()),
                    ('{{NB}}', str(len(produits))), ('{{NBCAT}}', str(len(cats))),
                    ('{{DATE}}', '%d %s %d' % (h.day, MOIS[h.month - 1], h.year))):
    CORPS = CORPS.replace(cle, valeur)


def rendu(fichier, incruster):
    """
    Deux sorties du meme corps. La page du dossier va chercher ses photos dans img/ ;
    celle de l'apercu les porte, pour tenir dans un seul fichier qu'on publie ou qu'on
    envoie d'un bloc. Les chemins ne sont donc ecrits qu'ici, une fois.
    """
    def source_image(f):
        chemin = os.path.join(IMG, f)
        if not incruster or not os.path.exists(chemin): return 'img/' + f
        t = 'image/png' if f.lower().endswith('.png') else 'image/jpeg'
        return 'data:%s;base64,%s' % (t, base64.b64encode(open(chemin, 'rb').read()).decode())

    txt = re.sub(r'\{\{IMG:([^}]+)\}\}', lambda m: source_image(m.group(1)), CORPS)
    txt = txt.replace('{{LOGO}}', source_image('logo-number-one.png'))
    if not incruster:
        txt = ('<!doctype html><html lang="fr"><head><meta charset="utf-8">'
               '<meta name="viewport" content="width=device-width, initial-scale=1">'
               '<meta name="description" content="La carte de NUMBER ONE, Chihia, Sfax. '
               'Sandwichs en pate normale, cereale ou chia. Tel 26 473 741.">'
               + txt + '</body></html>')
    open(os.path.join(ICI, fichier), 'w', encoding='utf-8').write(txt)
    return len(txt)


def carte_lisible():
    """
    La carte en petit : le meme contenu que carte-live.json, sans les photos, avec les
    noms de pate en clair. carte-live.json fait 16 Mo - il porte les images en base64,
    et aucun outil ne le relit confortablement. Celui-ci fait quelques dizaines de Ko :
    c'est lui qu'on donne a qui doit refaire la page.
    """
    data = {
        'restaurant': {
            'nom': 'NUMBER ONE', 'ville': 'Chihia, Sfax', 'adresse': ADRESSE,
            'telephone': TEL_AFFICHE, 'telephoneLien': TEL_LIEN, 'maps': MAPS,
            'monnaie': 'TND', 'symbole': 'DT', 'decimales': 3,
        },
        'pates': PATES,
        'supplementDoublePate': DOUBLE,
        'categories': [],
    }
    for c in cats:
        rub = {'nom': c['name'], 'description': DITS.get(c['name'], ''), 'articles': []}
        for p in par_cat[c['name']]:
            a = {'nom': p['name'], 'prix': float(p['price'])}
            f = photos.get(slug(p['name']))
            if f: a['photo'] = 'img/' + f
            pv = prix_pates(p)
            if pv and any(x is not None for x in pv):
                a['prixParPate'] = {n: (None if v is None else float(v)) for n, v in zip(PATES, pv)}
            rub['articles'].append(a)
        data['categories'].append(rub)
    open(os.path.join(ICI, 'carte.json'), 'w', encoding='utf-8').write(
        json.dumps(data, ensure_ascii=False, indent=2))
    return os.path.getsize(os.path.join(ICI, 'carte.json'))


n3 = carte_lisible()
n1 = rendu('index.html', False)
n2 = rendu('apercu-artifact.html', True)

print('Source : %s' % source)
if faites:
    print('Retouches appliquees - LA CAISSE NE LES DIT PAS ENCORE :')
    for x in faites: print('  ' + x)
    print('  (site/retouches.json ; sans effet une fois faites en caisse)')
for x in inutiles:
    print('Retouche devenue inutile, la caisse la porte deja : ' + x)
print('%d articles publies, %d ecartes faute de prix%s'
      % (len(produits), len(ecartes), (' : ' + ', '.join(ecartes)) if ecartes else ''))
manquantes = [p['name'] for p in produits if slug(p['name']) not in photos]
print('%d rubriques. Photos : %d dans site/img/ (%d reprises du poste), %d manquantes.'
      % (len(cats), len(produits) - len(manquantes), posees, len(manquantes)))
if manquantes: print('Sans photo : ' + ', '.join(manquantes))
print('index.html %d Ko, apercu-artifact.html %d Ko, carte.json %d Ko.'
      % (n1 // 1024, n2 // 1024, n3 // 1024))
