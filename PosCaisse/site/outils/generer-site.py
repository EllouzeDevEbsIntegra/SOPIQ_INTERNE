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

ICI = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CARTE = os.path.join(ICI, '..', 'catalogs', 'number-one-2026.json')
IMG = os.path.join(ICI, 'img')

TEL_AFFICHE = '26 473 741'
TEL_LIEN = '+21626473741'
ADRESSE = 'Route Tenyour Km 5, Chihia, Sfax'
MAPS = 'https://www.google.com/maps/search/?api=1&query=' + \
       'Number+One+Route+Tenyour+Km+5+Chihia+Sfax'

def sans_accent(s):
    return ''.join(c for c in unicodedata.normalize('NFD', s)
                   if unicodedata.category(c) != 'Mn')

def slug(s):
    return re.sub(r'-+', '-', re.sub(r'[^a-z0-9]+', '-', sans_accent(s).lower())).strip('-')

def prix(v):
    return ('%.3f' % float(v)).replace('.', ',')

def e(s):
    return html.escape(str(s), quote=True)

# ---------------------------------------------------------------- donnees
carte = json.load(open(CARTE, encoding='utf-8'))
produits = [p for p in carte['products'] if float(p['price']) > 0]
ecartes = [p['name'] for p in carte['products'] if float(p['price']) <= 0]

photos = set()
if os.path.isdir(IMG):
    for f in os.listdir(IMG):
        base, ext = os.path.splitext(f)
        if ext.lower() in ('.png', '.jpg', '.jpeg', '.webp'):
            photos.add(base)

PATES = ['Normale', 'Céréale', 'Chia']
def prix_pates(p):
    m = {v['value']: v['price'] for v in p.get('variantPrices', [])}
    return [m.get(x) for x in PATES] if p.get('variant') else None

par_cat = {}
for p in produits:
    par_cat.setdefault(p['category'], []).append(p)
cats = [c for c in carte['categories'] if par_cat.get(c['name'])]

# ---------------------------------------------------------------- pages
def ligne(p):
    """
    La vignette porte TOUJOURS l'image et TOUJOURS l'initiale, l'une par-dessus l'autre.

    C'est ce qui permet de deposer les photos dans site/img/ sans rien regenerer : le
    fichier absent, le navigateur retire l'image et l'initiale reparait. Une page qui
    exigerait de relancer un script pour voir une photo serait une page qu'on ne met
    jamais a jour.
    """
    vign = ('<span class="vign"><i aria-hidden="true">%s</i>'
            '<img src="img/%s.png" alt="" loading="lazy" decoding="async" onerror="this.remove()"></span>'
            % (e(p['name'][0]), e(slug(p['name']))))
    pv = prix_pates(p)
    if pv and any(x is not None for x in pv):
        cells = ''.join(
            '<div class="px"><span class="px-lib">%s</span><span class="px-val">%s</span></div>'
            % (e(n), prix(v) if v is not None else '&mdash;')
            for n, v in zip(PATES, pv))
        prix_html = '<div class="prix trois">%s</div>' % cells
    else:
        prix_html = ('<div class="prix seul"><div class="px"><span class="px-val">%s</span>'
                     '<span class="px-dev">DT</span></div></div>' % prix(p['price']))
    return ('<li class="art" data-nom="%s">%s<span class="nom">%s</span>%s</li>'
            % (e(sans_accent(p['name']).lower()), vign, e(p['name']), prix_html))

def section(c):
    liste = par_cat[c['name']]
    decline = any(prix_pates(p) for p in liste)
    entete = ('<div class="col-titres" aria-hidden="true">%s</div>'
              % ''.join('<span>%s</span>' % e(n) for n in PATES)) if decline else ''
    return """
<section class="cat" id="cat-%s" style="--teinte:%s">
  <div class="cat-tete">
    <h2>%s</h2>
    <span class="cat-nb">%d</span>
  </div>
  %s
  <ul class="arts">%s</ul>
</section>""" % (slug(c['name']), e(c.get('color') or '#D93A2B'), e(c['name']),
                 len(liste), entete, ''.join(ligne(p) for p in liste))

puces = ''.join('<a class="puce" href="#cat-%s">%s</a>' % (slug(c['name']), e(c['name'])) for c in cats)
volet = ''.join('<a href="#cat-%s"><span>%s</span><b>%d</b></a>'
                % (slug(c['name']), e(c['name']), len(par_cat[c['name']])) for c in cats)

PAGE = """<!doctype html>
<html lang="fr">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
<title>NUMBER ONE — mlewi et sandwichs à Chihia, Sfax</title>
<meta name="description" content="La carte de NUMBER ONE : mlewi, omlette, chawarma, escalope, lablebi. Trois pâtes au choix. Commande par téléphone au %(tel)s — Route Tenyour Km 5, Chihia, Sfax.">
<meta name="theme-color" content="#141110">
<meta property="og:type" content="restaurant.restaurant">
<meta property="og:title" content="NUMBER ONE — mlewi et sandwichs à Chihia">
<meta property="og:description" content="La carte complète et le numéro pour commander : %(tel)s.">
<meta property="og:locale" content="fr_TN">
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Instrument+Serif:ital@0;1&family=Manrope:wght@400;500;600;700&display=swap">
<style>
:root{
  --nuit:#141110; --fond:#1B1614; --carte:#221B18; --ligne:#332822;
  --creme:#F4EAE0; --sourd:#A8968A; --rouge:#D93A2B; --braise:#E8A33A;
  --serif:"Instrument Serif",Georgia,serif;
  --sans:"Manrope",-apple-system,BlinkMacSystemFont,"Segoe UI",sans-serif;
  --marge:clamp(16px,4vw,40px);
}
*{box-sizing:border-box}
html{scroll-behavior:smooth;scroll-padding-top:118px}
@media (prefers-reduced-motion:reduce){html{scroll-behavior:auto}*{animation:none!important;transition:none!important}}
body{margin:0;background:var(--nuit);color:var(--creme);font-family:var(--sans);font-size:16px;line-height:1.5;-webkit-font-smoothing:antialiased;overflow-x:hidden}
a{color:inherit}
img{max-width:100%%}
.enveloppe{max-width:960px;margin:0 auto;padding-inline:var(--marge)}

/* ---------- entete ---------- */
.hero{position:relative;padding:clamp(28px,7vw,64px) 0 clamp(24px,5vw,44px);text-align:center;
      background:radial-gradient(120%% 80%% at 50%% 0%%,#2A1D17 0%%,var(--nuit) 62%%)}
.logo{width:clamp(132px,34vw,188px);height:auto;margin:0 auto 6px;display:block}
.mot{font-family:var(--serif);font-size:clamp(46px,13vw,86px);line-height:.92;margin:0;letter-spacing:-.01em}
.mot i{display:block;font-style:italic;color:var(--rouge)}
.accroche{margin:14px auto 0;max-width:34ch;color:var(--sourd);font-size:clamp(14px,3.6vw,17px)}
.appel{display:inline-flex;align-items:center;gap:12px;margin-top:22px;padding:14px 26px 15px;border-radius:999px;
       background:var(--braise);color:#20160C;text-decoration:none;font-weight:700;
       font-size:clamp(22px,6.4vw,30px);letter-spacing:.01em;font-variant-numeric:tabular-nums;
       box-shadow:0 10px 34px -12px rgba(232,163,58,.6)}
.appel svg{width:24px;height:24px;flex:none}
.sous-appel{margin:12px 0 0;font-size:14px;color:var(--sourd)}
.sous-appel a{color:var(--braise)}
.filet{height:1px;background:linear-gradient(90deg,transparent,var(--ligne) 18%%,var(--ligne) 82%%,transparent)}

/* ---------- navigation ---------- */
.nav{position:sticky;top:0;z-index:40;background:rgba(20,17,16,.94);backdrop-filter:blur(10px);
     border-bottom:1px solid var(--ligne)}
.nav-rang{display:flex;align-items:center;gap:10px;padding:10px 0}
.nav-bt{flex:none;display:inline-flex;align-items:center;gap:7px;height:38px;padding:0 14px;border-radius:10px;
        border:1px solid var(--ligne);background:var(--carte);color:var(--creme);font:600 13px var(--sans);cursor:pointer}
.nav-bt svg{width:15px;height:15px}
.puces{display:flex;gap:8px;overflow-x:auto;scrollbar-width:none;-webkit-overflow-scrolling:touch;
       mask-image:linear-gradient(90deg,#000 88%%,transparent)}
.puces::-webkit-scrollbar{display:none}
.puce{flex:none;padding:8px 14px;border-radius:999px;border:1px solid var(--ligne);background:var(--carte);
      color:var(--sourd);text-decoration:none;font-size:13px;font-weight:600;white-space:nowrap}
.puce.on{background:var(--rouge);border-color:var(--rouge);color:#fff}
.recherche{display:none;padding:0 0 12px}
.recherche.ouverte{display:block}
.recherche input{width:100%%;height:44px;padding:0 14px;border-radius:10px;border:1px solid var(--ligne);
                 background:var(--fond);color:var(--creme);font:400 15px var(--sans)}
.recherche input::placeholder{color:#6E5F55}

/* ---------- volet des categories ---------- */
.volet{position:fixed;inset:0;z-index:60;background:rgba(10,8,7,.72);display:none}
.volet.ouvert{display:block}
.volet-boite{position:absolute;left:0;right:0;bottom:0;max-height:78vh;overflow:auto;background:var(--fond);
             border-top:1px solid var(--ligne);border-radius:18px 18px 0 0;padding:8px var(--marge) calc(18px + env(safe-area-inset-bottom))}
.volet-poignee{width:42px;height:4px;border-radius:2px;background:var(--ligne);margin:8px auto 14px}
.volet-boite h2{font-family:var(--serif);font-size:26px;margin:0 0 12px}
.volet-liste{display:grid;grid-template-columns:1fr 1fr;gap:8px}
.volet-liste a{display:flex;justify-content:space-between;align-items:center;gap:8px;padding:13px 14px;border-radius:12px;
               background:var(--carte);border:1px solid var(--ligne);text-decoration:none;font-size:14px;font-weight:600}
.volet-liste b{color:var(--sourd);font-weight:600;font-size:12px;font-variant-numeric:tabular-nums}
@media (max-width:420px){.volet-liste{grid-template-columns:1fr}}

/* ---------- carte ---------- */
.carte-tete{padding:clamp(30px,7vw,54px) 0 6px}
.carte-tete h1{font-family:var(--serif);font-size:clamp(34px,9vw,52px);margin:0;line-height:1}
.carte-tete p{color:var(--sourd);max-width:56ch;margin:10px 0 0;font-size:15px}
.pates{display:flex;flex-wrap:wrap;gap:8px;margin:18px 0 0;padding:0;list-style:none}
.pates li{padding:9px 14px;border-radius:10px;background:var(--carte);border:1px solid var(--ligne);font-size:13.5px}
.pates b{color:var(--braise)}

.cat{padding-top:34px}
.cat-tete{display:flex;align-items:baseline;gap:12px;padding-bottom:10px;border-bottom:2px solid var(--teinte)}
.cat-tete h2{font-family:var(--serif);font-size:clamp(24px,6vw,34px);margin:0;line-height:1.1}
.cat-nb{margin-left:auto;font-size:12px;color:var(--sourd);font-variant-numeric:tabular-nums}
.col-titres{display:none}
.arts{list-style:none;margin:0;padding:0}
.art{display:grid;grid-template-columns:52px 1fr;grid-template-areas:"v n" "v p";
     gap:4px 12px;align-items:center;padding:12px 0;border-bottom:1px solid var(--ligne)}
.art:last-child{border-bottom:0}
.vign{grid-area:v;position:relative;display:grid;place-items:center;width:52px;height:52px;border-radius:12px;
      background:var(--carte);border:1px solid var(--ligne);overflow:hidden}
.vign i{font-family:var(--serif);font-size:22px;font-style:normal;color:var(--teinte);opacity:.9}
.vign img{position:absolute;inset:0;width:100%%;height:100%%;object-fit:cover;background:var(--carte)}
.nom{grid-area:n;font-weight:600;font-size:15px;line-height:1.3}
.prix{grid-area:p}
.prix.trois{display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:6px;max-width:340px}
.px{display:flex;flex-direction:column;gap:1px;padding:6px 8px;border-radius:9px;background:var(--carte);
    border:1px solid var(--ligne)}
.px-lib{font-size:10.5px;letter-spacing:.06em;text-transform:uppercase;color:var(--sourd)}
.px-val{font-weight:700;font-size:15px;font-variant-numeric:tabular-nums;color:var(--braise)}
.prix.seul .px{background:none;border:0;padding:0;flex-direction:row;align-items:baseline;gap:5px}
.prix.seul .px-val{font-size:17px}
.px-dev{font-size:12px;color:var(--sourd)}
.art.masque{display:none}

@media (min-width:700px){
  .art{grid-template-columns:64px 1fr auto;grid-template-areas:"v n p";gap:16px;padding:11px 0}
  .vign{width:64px;height:64px}
  .nom{font-size:16px}
  .prix.trois{max-width:none;grid-template-columns:repeat(3,84px);gap:8px}
  .px{align-items:flex-end;background:none;border:0;padding:4px 0}
  .px-lib{display:none}
  .prix.seul{width:276px;text-align:right}
  .prix.seul .px{justify-content:flex-end}
  .col-titres{display:grid;grid-template-columns:repeat(3,84px);gap:8px;margin-left:auto;width:276px;
              padding:10px 0 2px;text-align:right}
  .col-titres span{font-size:10.5px;letter-spacing:.08em;text-transform:uppercase;color:var(--sourd)}
  .cat-tete{padding-bottom:8px}
}

/* ---------- pied ---------- */
.contact{margin-top:56px;padding:clamp(28px,6vw,44px) 0;background:var(--fond);border-top:1px solid var(--ligne)}
.contact h2{font-family:var(--serif);font-size:clamp(26px,7vw,38px);margin:0 0 16px}
.contact dl{display:grid;gap:16px;margin:0}
.contact dt{font-size:11.5px;letter-spacing:.1em;text-transform:uppercase;color:var(--sourd);margin-bottom:3px}
.contact dd{margin:0;font-size:17px;font-weight:600}
.contact dd a{color:var(--braise);text-decoration:none}
.pied{padding:26px 0 calc(96px + env(safe-area-inset-bottom));color:var(--sourd);font-size:13px;text-align:center}
@media (min-width:700px){.pied{padding-bottom:34px}}

/* ---------- barre d'appel mobile ---------- */
.barre{position:fixed;left:0;right:0;bottom:0;z-index:50;display:flex;
       padding:10px var(--marge) calc(10px + env(safe-area-inset-bottom));
       background:rgba(20,17,16,.96);backdrop-filter:blur(10px);border-top:1px solid var(--ligne)}
.barre a{flex:1;display:inline-flex;align-items:center;justify-content:center;gap:10px;padding:14px;
         border-radius:12px;background:var(--rouge);color:#fff;text-decoration:none;font-weight:700;font-size:17px;
         font-variant-numeric:tabular-nums}
.barre svg{width:19px;height:19px}
@media (min-width:700px){.barre{display:none}}
:focus-visible{outline:2px solid var(--braise);outline-offset:3px}
</style>
</head>
<body>

<header class="hero">
  <div class="enveloppe">
    <img class="logo" src="img/logo-number-one.png" alt="" onerror="this.remove()">
    <h1 class="mot">NUMBER<i>ONE</i></h1>
    <p class="accroche">Mlewi, omlette, chawarma, escalope et lablebi &mdash; pr&eacute;par&eacute;s &agrave; la commande, &agrave; Chihia.</p>
    <a class="appel" href="tel:%(lien)s">
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" aria-hidden="true"><path d="M22 16.9v3a2 2 0 0 1-2.2 2 19.8 19.8 0 0 1-8.6-3.1 19.5 19.5 0 0 1-6-6A19.8 19.8 0 0 1 2.1 4.2 2 2 0 0 1 4.1 2h3a2 2 0 0 1 2 1.7c.1 1 .4 1.9.7 2.8a2 2 0 0 1-.5 2.1L8.1 9.9a16 16 0 0 0 6 6l1.3-1.2a2 2 0 0 1 2.1-.5c.9.3 1.8.6 2.8.7a2 2 0 0 1 1.7 2z"/></svg>
      %(tel)s
    </a>
    <p class="sous-appel">%(adresse)s &middot; <a href="%(maps)s" target="_blank" rel="noopener">voir sur la carte</a></p>
  </div>
</header>
<div class="filet"></div>

<nav class="nav" aria-label="Cat&eacute;gories">
  <div class="enveloppe">
    <div class="nav-rang">
      <button class="nav-bt" type="button" id="bt-volet" aria-haspopup="dialog">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" aria-hidden="true"><path d="M4 6h16M4 12h16M4 18h16"/></svg>
        Cat&eacute;gories
      </button>
      <div class="puces" id="puces">%(puces)s</div>
      <button class="nav-bt" type="button" id="bt-cherche" aria-label="Rechercher un article">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" aria-hidden="true"><circle cx="11" cy="11" r="7"/><path d="m20 20-3.5-3.5"/></svg>
      </button>
    </div>
    <div class="recherche" id="recherche">
      <input type="search" id="champ" placeholder="Chercher : thon, chawarma, lablebi&hellip;" aria-label="Chercher un article">
    </div>
  </div>
</nav>

<main class="enveloppe">
  <div class="carte-tete">
    <h1>La carte</h1>
    <p>Prix en dinars, service compris. Les sandwichs se pr&eacute;parent dans la p&acirc;te de votre choix &mdash; le prix de chacune est indiqu&eacute; sur la ligne.</p>
    <ul class="pates">
      <li><b>Normale</b> &mdash; la p&acirc;te du jour</li>
      <li><b>C&eacute;r&eacute;ale</b> &mdash; compl&egrave;te, plus rustique</li>
      <li><b>Chia</b> &mdash; aux graines</li>
    </ul>
  </div>
  %(sections)s
</main>

<section class="contact" id="contact">
  <div class="enveloppe">
    <h2>Commander</h2>
    <dl>
      <div><dt>Par t&eacute;l&eacute;phone</dt><dd><a href="tel:%(lien)s">%(tel)s</a></dd></div>
      <div><dt>Adresse</dt><dd>%(adresse)s<br><a href="%(maps)s" target="_blank" rel="noopener">Ouvrir dans Google&nbsp;Maps</a></dd></div>
    </dl>
  </div>
</section>

<footer class="pied"><div class="enveloppe">NUMBER ONE &mdash; Chihia, Sfax</div></footer>

<div class="barre">
  <a href="tel:%(lien)s">
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" aria-hidden="true"><path d="M22 16.9v3a2 2 0 0 1-2.2 2 19.8 19.8 0 0 1-8.6-3.1 19.5 19.5 0 0 1-6-6A19.8 19.8 0 0 1 2.1 4.2 2 2 0 0 1 4.1 2h3a2 2 0 0 1 2 1.7c.1 1 .4 1.9.7 2.8a2 2 0 0 1-.5 2.1L8.1 9.9a16 16 0 0 0 6 6l1.3-1.2a2 2 0 0 1 2.1-.5c.9.3 1.8.6 2.8.7a2 2 0 0 1 1.7 2z"/></svg>
    Appeler %(tel)s
  </a>
</div>

<div class="volet" id="volet" role="dialog" aria-modal="true" aria-label="Cat&eacute;gories">
  <div class="volet-boite">
    <div class="volet-poignee"></div>
    <h2>La carte</h2>
    <div class="volet-liste">%(volet)s</div>
  </div>
</div>

<script>
(function () {
  var volet = document.getElementById('volet');
  function fermer() { volet.classList.remove('ouvert'); document.body.style.overflow = ''; }
  document.getElementById('bt-volet').addEventListener('click', function () {
    volet.classList.add('ouvert'); document.body.style.overflow = 'hidden';
  });
  volet.addEventListener('click', fermer);
  document.addEventListener('keydown', function (ev) { if (ev.key === 'Escape') fermer(); });

  var zone = document.getElementById('recherche'), champ = document.getElementById('champ');
  document.getElementById('bt-cherche').addEventListener('click', function () {
    zone.classList.toggle('ouverte');
    if (zone.classList.contains('ouverte')) champ.focus(); else { champ.value = ''; champ.dispatchEvent(new Event('input')); }
  });
  champ.addEventListener('input', function () {
    var q = champ.value.trim().toLowerCase()
      .normalize('NFD').replace(/[\\u0300-\\u036f]/g, '');
    document.querySelectorAll('.art').forEach(function (a) {
      a.classList.toggle('masque', !!q && a.dataset.nom.indexOf(q) < 0);
    });
    document.querySelectorAll('.cat').forEach(function (c) {
      var reste = c.querySelectorAll('.art:not(.masque)').length;
      c.style.display = reste ? '' : 'none';
    });
  });

  /* La puce active suit la lecture : sur un telephone, elle dit ou l'on est
     dans une carte de cent lignes. */
  var puces = {};
  document.querySelectorAll('.puce').forEach(function (p) { puces[p.getAttribute('href').slice(1)] = p; });
  if ('IntersectionObserver' in window) {
    var obs = new IntersectionObserver(function (entrees) {
      entrees.forEach(function (en) {
        if (!en.isIntersecting) return;
        var p = puces[en.target.id];
        if (!p) return;
        document.querySelectorAll('.puce.on').forEach(function (x) { x.classList.remove('on'); });
        p.classList.add('on');
        p.scrollIntoView({ inline: 'center', block: 'nearest', behavior: 'smooth' });
      });
    }, { rootMargin: '-120px 0px -70%% 0px' });
    document.querySelectorAll('.cat').forEach(function (c) { obs.observe(c); });
  }
})();
</script>
</body>
</html>
""" % {'tel': TEL_AFFICHE, 'lien': TEL_LIEN, 'adresse': ADRESSE, 'maps': MAPS,
       'puces': puces, 'volet': volet, 'sections': ''.join(section(c) for c in cats)}

open(os.path.join(ICI, 'index.html'), 'w', encoding='utf-8').write(PAGE)
print('%d articles publies, %d ecartes faute de prix : %s'
      % (len(produits), len(ecartes), ', '.join(ecartes)))
manquantes = [p['name'] for p in produits if slug(p['name']) not in photos]
print('%d categories. Photos : %d presentes dans site/img/, %d manquantes.'
      % (len(cats), len(produits) - len(manquantes), len(manquantes)))
if manquantes and len(manquantes) < len(produits):
    print('  manquent : ' + ', '.join(manquantes[:12]) + ('...' if len(manquantes) > 12 else ''))
