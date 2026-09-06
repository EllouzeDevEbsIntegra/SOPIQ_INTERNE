import { readFileSync, writeFileSync, existsSync } from 'node:fs';
import { resolve, dirname, sep } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const source = resolve(root, 'carte.json');
const carte = JSON.parse(readFileSync(source, 'utf8').replace(/^\uFEFF/, ''));
const { restaurant: resto, categories, pates, supplementDoublePate } = carte;
const escape = value => String(value).replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
const money = value => `${new Intl.NumberFormat('fr-FR', { minimumFractionDigits: 3, maximumFractionDigits: 3 }).format(value)} ${escape(resto.symbole)}`;
const assert = (condition, message) => { if (!condition) throw new Error(message); };
assert(resto.symbole === 'DT' && resto.decimales === 3, 'La carte doit utiliser DT et trois décimales.');
assert(/^\+?\d+$/.test(resto.telephoneLien), 'Lien de téléphone invalide.');
assert(new URL(resto.maps).protocol === 'https:', 'Lien Google Maps invalide.');
assert(pates.length === 3 && new Set(pates).size === 3, 'Trois pâtes distinctes sont attendues.');
const checkPrice = value => assert(typeof value === 'number' && Number.isFinite(value) && value >= 0, `Prix invalide : ${value}`);
pates.forEach(pate => checkPrice(supplementDoublePate[pate]));
const articles = categories.flatMap((category, ci) => category.articles.map((article, ai) => ({ ...article, category: category.nom, ci, id: `${ci}-${ai}` })));
for (const article of articles) {
  checkPrice(article.prix);
  if (article.prixParPate) pates.forEach(pate => checkPrice(article.prixParPate[pate]));
  const imagePath = resolve(root, article.photo);
  assert(imagePath.startsWith(resolve(root, 'img') + sep) && existsSync(imagePath), `Photo absente ou hors du dossier img : ${article.photo}`);
}
assert(existsSync(resolve(root, 'img/logo-number-one.png')), 'Logo manquant.');

const icon = name => {
  const paths = {
    arrow: '<path d="M5 12h14m-6-6 6 6-6 6"/>',
    upRight: '<path d="M6 18 18 6M6 6h12v12"/>',
    down: '<path d="M12 4v16m-6-6 6 6 6-6"/>',
    phone: '<path d="m7 3 3 5-2.5 2a14 14 0 0 0 6.5 6.5l2-2.5 5 3-1 3c-.3.8-1 1.1-2 1C10 20 4 14 3 6c-.1-1 .2-1.7 1-2l3-1Z"/>',
    pin: '<path d="M19 10c0 5-7 11-7 11S5 15 5 10a7 7 0 1 1 14 0Z"/><circle cx="12" cy="10" r="2.5"/>',
    search: '<circle cx="10.5" cy="10.5" r="6.5"/><path d="m16 16 5 5"/>',
    close: '<path d="m6 6 12 12M6 18 18 6"/>',
    plus: '<path d="M5 12h14M12 5v14"/>',
    grid: '<rect x="3" y="3" width="6" height="6" rx="1"/><rect x="15" y="3" width="6" height="6" rx="1"/><rect x="3" y="15" width="6" height="6" rx="1"/><rect x="15" y="15" width="6" height="6" rx="1"/>',
    chevron: '<path d="m7 10 5 5 5-5"/>',
    check: '<path d="m5 12 4 4L19 6"/>',
  };
  return `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">${paths[name]}</svg>`;
};
const tel = `tel:${escape(resto.telephoneLien)}`;
const prices = article => article.prixParPate
  ? `<dl class="prices">${pates.map(pate => `<div><dt>${escape(pate)}</dt><dd data-price-pate="${escape(pate)}">${money(article.prixParPate[pate])}</dd></div>`).join('')}</dl>`
  : `<div class="single-price"><span>Prix</span><strong data-price>${money(article.prix)}</strong></div>`;

const card = article => `<article class="food-card${article.prixParPate ? '' : ' food-card--single'}" data-article="${article.id}">
  <div class="food-card-top"><div class="food-photo"><img src="${escape(article.photo)}" alt="" width="240" height="240" loading="lazy" decoding="async"></div>
  <h3>${escape(article.nom)}</h3></div>${prices(article)}</article>`;

const categoryData = categories.map((category, i) => ({ id: String(i), nom: category.nom, description: category.description, count: category.articles.length, photo: category.articles[0]?.photo }));
const categoryLinks = categoryData.map(category => `<a class="category-link" href="#categorie-${category.id}" data-category="${category.id}"><span class="category-thumb"><img src="${escape(category.photo)}" width="36" height="36" alt="" loading="lazy"></span><span class="category-name">${escape(category.nom)}</span><span class="category-count">${category.count}</span></a>`).join('');
const categoryTiles = categoryData.map(category => `<button class="category-tile" type="button" data-category="${category.id}" aria-pressed="false"><span class="tile-photo"><img src="${escape(category.photo)}" width="64" height="64" alt="" loading="lazy"></span><span class="tile-copy"><strong>${escape(category.nom)}</strong><small>${category.count} articles</small></span><span class="tile-check">${icon('check')}</span></button>`).join('');
const sections = categories.map((category, i) => `<section class="menu-section" id="categorie-${i}" data-section="${i}" aria-labelledby="titre-categorie-${i}">
  <div class="section-heading"><div><span class="section-number">${String(i + 1).padStart(2, '0')}</span><h2 id="titre-categorie-${i}" tabindex="-1">${escape(category.nom)}</h2><span class="section-count">${category.articles.length}</span></div><p>${escape(category.description)}</p></div>
  <div class="food-grid">${articles.filter(article => article.ci === i).map(card).join('\n')}</div></section>`).join('\n');
const hero = articles.find(article => article.nom === 'Number One') ?? articles[0];
const primaryPate = pates[0];
const doublePrices = `<dl class="double-prices">${pates.map(pate => `<div><dt>${escape(pate)}</dt><dd>+ ${money(supplementDoublePate[pate])}</dd></div>`).join('')}</dl>`;
const headingWords = escape(resto.nom).split(' ');
const template = readFileSync(resolve(root, 'outils/modele.html'), 'utf8');
const fragments = {
  TITLE: `${escape(resto.nom)} — La carte · ${escape(resto.ville)}`,
  DESCRIPTION: `La carte de ${escape(resto.nom)} à ${escape(resto.ville)}. Sandwichs, lablebi, boissons et extras. Tous les prix et les pâtes au choix. Commandez au ${escape(resto.telephone)}.`,
  NAME: escape(resto.nom), CITY: escape(resto.ville), ADDRESS: escape(resto.adresse),
  PHONE: escape(resto.telephone), TEL: tel, MAPS: escape(resto.maps),
  BRAND_TITLE: `${headingWords.slice(0, -1).join(' ')}<br><span>${headingWords.at(-1)}</span>`,
  ICON_PHONE: icon('phone'), ICON_PIN: icon('pin'), ICON_ARROW: icon('arrow'), ICON_UP_RIGHT: icon('upRight'),
  ICON_DOWN: icon('down'), ICON_SEARCH: icon('search'), ICON_CLOSE: icon('close'), ICON_PLUS: icon('plus'),
  ICON_GRID: icon('grid'), ICON_CHEVRON: icon('chevron'),
  ARTICLE_COUNT: articles.length, CATEGORY_COUNT: categories.length,
  HERO_PHOTO: escape(hero.photo), HERO_NAME: escape(hero.nom), HERO_CATEGORY: escape(hero.category),
  HERO_PATE: hero.prixParPate ? escape(primaryPate) : 'Prix',
  HERO_PRICE: money(hero.prixParPate ? hero.prixParPate[primaryPate] : hero.prix),
  HERO_LINK: `#categorie-${hero.ci}`, HERO_CATEGORY_INDEX: hero.ci,
  CATEGORY_LINKS: categoryLinks, CATEGORY_TILES: categoryTiles, SECTIONS: sections,
  FIRST_CATEGORY_NAME: escape(categoryData[0].nom),
  DOUGH_NAMES: pates.map(escape).join(' · '), DOUBLE_PRICES: doublePrices,
  MENU_DATA: JSON.stringify({ articles, pates, categories: categoryData }).replace(/</g, '\\u003c').replace(/>/g, '\\u003e').replace(/&/g, '\\u0026'),
};
const html = template.replace(/\{\{([A-Z_]+)\}\}/g, (_, key) => {
  assert(Object.hasOwn(fragments, key), `Variable inconnue : ${key}`);
  return fragments[key];
});
assert(!/\{\{[A-Z_]+\}\}/.test(html), 'Variable non résolue.');
writeFileSync(resolve(root, 'index.html'), html, 'utf8');
console.log(`index.html généré depuis carte.json : ${articles.length} articles, ${articles.filter(a => a.prixParPate).length} déclinaisons en trois pâtes, ${categories.length} catégories.`);
