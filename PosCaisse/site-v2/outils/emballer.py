# -*- coding: utf-8 -*-
"""
Emballe le site en UN SEUL fichier, pour le montrer sans l'heberger.

    python3 outils/emballer.py

index.html va chercher sa feuille de style, son code, ses photos et ses polices dans
des fichiers voisins : parfait pour un hebergement, inutilisable des qu'on veut
l'envoyer par messagerie ou le publier d'un bloc. Ce script en fabrique une copie qui
porte tout - apercu-artifact.html - sans rien changer a l'original.

Il ne touche a rien de ce que le generateur produit : il ne fait que remplacer des
chemins par le contenu des fichiers qu'ils designent.
"""
import base64, mimetypes, os, re

ICI = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def octets(chemin):
    return open(os.path.join(ICI, chemin), 'rb').read()


def donnees(chemin):
    t = mimetypes.guess_type(chemin)[0] or 'application/octet-stream'
    return 'data:%s;base64,%s' % (t, base64.b64encode(octets(chemin)).decode())


page = open(os.path.join(ICI, 'index.html'), encoding='utf-8').read()
style = open(os.path.join(ICI, 'style.css'), encoding='utf-8').read()
code = open(os.path.join(ICI, 'app.js'), encoding='utf-8').read()

# Les polices citees par la feuille de style, puis la feuille elle-meme.
style = re.sub(r"url\(\s*['\"]?([^'\")]+\.(?:ttf|woff2?|otf))['\"]?\s*\)",
               lambda m: "url('%s')" % donnees(m.group(1)), style)
page = page.replace('<link rel="stylesheet" href="style.css">', '<style>\n%s\n</style>' % style)
# Le code n'est PAS remis a la place du <script defer> d'origine : << defer >> ne
# retarde qu'un script EXTERNE. Ecrit en ligne dans l'en-tete, il s'executerait avant
# que la page existe et ne trouverait rien a animer - c'est ainsi que la recherche
# avait disparu du premier emballage. Il part donc a la fin, apres le corps.
page = page.replace('<script src="app.js" defer></script>', '')
page = re.sub(r'<link rel="preload"[^>]*>', '', page)

# Les images, y compris l'icone d'onglet.
vues = {}
def image(m):
    c = m.group(2)
    if c not in vues: vues[c] = donnees(c)
    return m.group(1) + vues[c] + m.group(3)
page = re.sub(r'(src=")((?:img|fonts)/[^"]+)(")', image, page)
page = re.sub(r'(<link rel="icon"[^>]*href=")([^"]+)(")', image, page)

# Un artifact recoit le CORPS de la page : son enveloppe est posee par la plateforme.
titre = re.search(r'<title>(.*?)</title>', page, re.S).group(1)
corps = re.search(r'<body[^>]*>(.*)</body>', page, re.S).group(1)
tetes = re.findall(r'<style>.*?</style>|<script[^>]*>.*?</script>', page[:page.index('<body')], re.S)

sortie = os.path.join(ICI, 'apercu-artifact.html')
open(sortie, 'w', encoding='utf-8').write(
    '<title>%s</title>\n%s\n<div id="haut">%s</div>\n<script>\n%s\n</script>'
    % (titre, '\n'.join(tetes), corps, code))
print('%s : %d Ko, %d images embarquees'
      % (os.path.basename(sortie), os.path.getsize(sortie) // 1024, len(vues)))
