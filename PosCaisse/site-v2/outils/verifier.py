"""Vérifie le livrable et la chaîne de génération, sans serveur ni dépendance Python."""
from pathlib import Path
from html.parser import HTMLParser
from decimal import Decimal, ROUND_HALF_UP
import json
import re
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parent.parent
VOID = {'area', 'base', 'br', 'col', 'embed', 'hr', 'img', 'input', 'link', 'meta', 'param', 'source', 'track', 'wbr'}


class Node:
    def __init__(self, tag='', attrs=()):
        self.tag, self.attrs, self.children = tag, dict(attrs), []

    def text(self):
        return ''.join(child if isinstance(child, str) else child.text() for child in self.children)

    def find(self, tag=None, attr=None, value=None):
        found = []
        for child in self.children:
            if not isinstance(child, Node):
                continue
            if (tag is None or child.tag == tag) and (attr is None or (attr in child.attrs and (value is None or child.attrs[attr] == value))):
                found.append(child)
            found.extend(child.find(tag, attr, value))
        return found


class Document(HTMLParser):
    def __init__(self, source):
        super().__init__(convert_charrefs=True)
        self.root = Node()
        self.stack = [self.root]
        self.feed(source)
        assert len(self.stack) == 1, 'Balises HTML non fermées'

    def handle_starttag(self, tag, attrs):
        node = Node(tag, attrs)
        self.stack[-1].children.append(node)
        if tag not in VOID:
            self.stack.append(node)

    def handle_endtag(self, tag):
        assert self.stack[-1].tag == tag, f'Fermeture HTML incorrecte : {tag}'
        self.stack.pop()

    def handle_data(self, data):
        self.stack[-1].children.append(data)


def money(value):
    # Conversion indépendante du formateur JavaScript du générateur.
    return f'{Decimal(str(value)).quantize(Decimal(".001"), rounding=ROUND_HALF_UP):.3f}'.replace('.', ',') + ' DT'


def verify_menu(root):
    data = json.loads((root / 'carte.json').read_text(encoding='utf-8'))
    html = (root / 'index.html').read_text(encoding='utf-8')
    doc = Document(html).root
    assert doc.find('html')[0].attrs['lang'] == 'fr'
    assert len(doc.find('h1')) == 1
    ids = [node.attrs['id'] for node in doc.find(attr='id')]
    assert len(ids) == len(set(ids)), 'Identifiants HTML dupliqués'
    cards = {node.attrs['data-article']: node for node in doc.find('article', 'data-article')}
    all_articles = [(f'{ci}-{ai}', article) for ci, category in enumerate(data['categories']) for ai, article in enumerate(category['articles'])]
    assert len(cards) == len(all_articles)
    price_count = 0
    for identifier, article in all_articles:
        card = cards[identifier]
        assert card.find('h3')[0].text() == article['nom'], article['nom']
        assert card.find('img')[0].attrs['src'] == article['photo']
        image = root / article['photo']
        assert image.is_file(), f'Photo manquante : {image}'
        assert image.read_bytes().startswith(b'\xff\xd8'), f'JPEG invalide : {image}'
        if 'prixParPate' in article:
            values = card.find('dd', 'data-price-pate')
            assert len(values) == len(data['pates'])
            assert [node.text() for node in card.find('dt')] == data['pates']
            for value in values:
                assert value.text() == money(article['prixParPate'][value.attrs['data-price-pate']]), article['nom']
                assert re.fullmatch(r'\d+,\d{3} DT', value.text())
                price_count += 1
        else:
            assert card.find('strong', 'data-price')[0].text() == money(article['prix'])
            assert not card.find('dd', 'data-price-pate')
            price_count += 1
    double = doc.find('dl', 'class', 'double-prices')[0]
    assert [node.text() for node in double.find('dt')] == data['pates']
    assert [node.text() for node in double.find('dd')] == ['+ ' + money(data['supplementDoublePate'][pate]) for pate in data['pates']]
    for anchor in doc.find('a', 'href'):
        href = anchor.attrs['href']
        if href.startswith('#'):
            assert href[1:] in ids, href
        elif href.startswith('tel:'):
            assert href == 'tel:' + data['restaurant']['telephoneLien']
        else:
            assert href == data['restaurant']['maps'], f'Lien externe inattendu : {href}'
    for node in doc.find(attr='src') + doc.find('link', 'href'):
        path = node.attrs.get('src', node.attrs.get('href'))
        assert not re.match(r'(?:https?:|//|/|\.\./)', path), f'Ressource non autonome : {path}'
        assert (root / path).is_file(), path
    payload = json.loads(doc.find('script', 'id', 'menu-data')[0].text())
    assert [article['nom'] for article in payload['articles']] == [article['nom'] for _, article in all_articles]
    assert '{{' not in html
    return len(all_articles), price_count


subprocess.run(['node', str(ROOT / 'outils/generer.mjs')], check=True)
total, prices = verify_menu(ROOT)
print(f'Carte vérifiée : {total} noms et photos, {prices} prix complets, trois suppléments, liens et ressources locales.')
original_html = (ROOT / 'index.html').read_bytes()
subprocess.run(['node', str(ROOT / 'outils/generer.mjs')], check=True, capture_output=True)
assert (ROOT / 'index.html').read_bytes() == original_html, 'Génération non déterministe'

# Un catalogue temporaire prouve que les prix et les noms du HTML relisent la source.
with tempfile.TemporaryDirectory(prefix='number-one-verification-') as temp:
    target = Path(temp)
    (target / 'outils').mkdir()
    for path in ('outils/generer.mjs', 'outils/modele.html', 'style.css', 'app.js'):
        shutil.copy2(ROOT / path, target / path)
    shutil.copytree(ROOT / 'img', target / 'img')
    shutil.copytree(ROOT / 'fonts', target / 'fonts')
    modified = json.loads((ROOT / 'carte.json').read_text(encoding='utf-8'))
    variant = next(a for c in modified['categories'] for a in c['articles'] if 'prixParPate' in a)
    variant['nom'] = 'Essai <carte> & "nom"'
    for i, pate in enumerate(modified['pates']):
        variant['prixParPate'][pate] += (i + 1) * 0.123
        modified['supplementDoublePate'][pate] += (i + 1) * 0.111
    singleton = next(a for c in modified['categories'] for a in c['articles'] if 'prixParPate' not in a)
    singleton['prix'] += 0.321
    (target / 'carte.json').write_text(json.dumps(modified, ensure_ascii=False), encoding='utf-8')
    subprocess.run(['node', str(target / 'outils/generer.mjs')], check=True, capture_output=True)
    verify_menu(target)
    del variant['prixParPate'][modified['pates'][-1]]
    (target / 'carte.json').write_text(json.dumps(modified, ensure_ascii=False), encoding='utf-8')
    rejected = subprocess.run(['node', str(target / 'outils/generer.mjs')], capture_output=True)
    assert rejected.returncode != 0, 'Une déclinaison incomplète doit bloquer la génération'
print('Régénération vérifiée avec tarifs modifiés, noms échappés et rejet des données incomplètes.')
subprocess.run(['node', str(ROOT / 'outils/verifier-recherche.mjs')], check=True)
print('Tous les contrôles ont réussi.')
