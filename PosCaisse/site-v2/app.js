/* La carte complète est déjà dans le HTML. Ce script ajoute uniquement les filtres. */
(function () {
  'use strict';
  const normalise = value => String(value).normalize('NFD').replace(/[\u0300-\u036f]/g, '').toLocaleLowerCase('fr').replace(/[^a-z0-9]+/g, ' ').trim();
  const matches = (article, query) => {
    const words = normalise(query).split(/\s+/).filter(Boolean);
    const text = normalise(`${article.nom} ${article.category}`);
    return words.every(word => text.includes(word));
  };
  if (typeof module !== 'undefined' && module.exports) module.exports = { normalise, matches };
  if (typeof document === 'undefined') return;

  const payload = document.getElementById('menu-data');
  if (!payload) return;
  const { articles } = JSON.parse(payload.textContent);
  const search = document.getElementById('menu-search');
  const clear = document.querySelector('.clear-search');
  const status = document.querySelector('.result-status');
  const empty = document.querySelector('.empty-state');
  const links = [...document.querySelectorAll('[data-category]')];
  const sections = [...document.querySelectorAll('[data-section]')];
  const cards = new Map([...document.querySelectorAll('[data-article]')].map(node => [node.dataset.article, node]));
  const toolbar = document.getElementById('menu-toolbar');
  let category = 'all';
  let previousQuery = '';
  let announceTimer;

  function applyFilters(announce = true) {
    const query = search.value.trim();
    const counts = new Map();
    let total = 0;
    for (const article of articles) {
      const visible = (category === 'all' || String(article.ci) === category) && matches(article, query);
      cards.get(article.id).hidden = !visible;
      if (visible) { total++; counts.set(String(article.ci), (counts.get(String(article.ci)) || 0) + 1); }
    }
    for (const section of sections) {
      const count = counts.get(section.dataset.section) || 0;
      section.hidden = count === 0;
      section.querySelector('.section-count').textContent = count;
    }
    for (const link of links) {
      const active = link.dataset.category === category;
      link.classList.toggle('is-active', active);
      if (active) link.setAttribute('aria-current', 'true');
      else link.removeAttribute('aria-current');
    }
    clear.hidden = search.value.length === 0;
    empty.hidden = total !== 0;
    const filtered = query.length > 0 || category !== 'all';
    status.hidden = !filtered;
    const message = `${total} article${total === 1 ? '' : 's'}${query ? ` pour « ${query} »` : ''}`;
    clearTimeout(announceTimer);
    if (announce) announceTimer = setTimeout(() => { status.textContent = message; }, 180);
    else status.textContent = message;
  }

  function scrollToMenu() {
    // Un offset mesuré conserve les contrôles visibles, même avec un texte agrandi.
    const headerHeight = window.matchMedia('(max-width: 760px)').matches ? 0 : document.querySelector('.site-header').getBoundingClientRect().height;
    window.scrollTo({ top: Math.max(0, window.scrollY + document.querySelector('.menu-heading').getBoundingClientRect().bottom - headerHeight), behavior: 'instant' });
  }

  function chooseCategory(value, scroll = false) {
    category = value;
    search.value = '';
    previousQuery = '';
    applyFilters();
    if (scroll) scrollToMenu();
    // Défile seulement la rangée horizontale, sans déplacer toute la page.
    const active = links.find(link => link.dataset.category === category);
    const nav = active?.parentElement;
    if (nav && nav.scrollWidth > nav.clientWidth) nav.scrollTo({ left: active.offsetLeft - nav.offsetLeft - 20, behavior: 'instant' });
  }

  links.forEach(link => link.addEventListener('click', event => {
    event.preventDefault();
    chooseCategory(link.dataset.category, true);
  }));
  document.querySelector('[data-hero-category]')?.addEventListener('click', event => {
    event.preventDefault();
    chooseCategory(event.currentTarget.dataset.heroCategory, true);
  });
  search.addEventListener('input', () => {
    // Une recherche porte toujours sur l'ensemble de la carte.
    if (search.value !== previousQuery) category = 'all';
    previousQuery = search.value;
    applyFilters();
    scrollToMenu();
  });
  function resetSearch() {
    chooseCategory('all');
    search.focus({ preventScroll: true });
  }
  clear.addEventListener('click', resetSearch);
  document.querySelector('.reset-menu').addEventListener('click', resetSearch);
  search.addEventListener('keydown', event => {
    if (event.key === 'Escape') { event.preventDefault(); resetSearch(); }
    if (event.key === 'Enter') { event.preventDefault(); search.blur(); scrollToMenu(); }
  });
  window.addEventListener('hashchange', () => {
    const match = /^#categorie-(\d+)$/.exec(window.location.hash);
    if (match && sections.some(section => section.dataset.section === match[1])) chooseCategory(match[1], true);
    else if (window.location.hash === '#carte') chooseCategory('all');
  });
  document.querySelectorAll('a[href="#carte"]:not([data-category])').forEach(link => link.addEventListener('click', () => chooseCategory('all')));
  const syncHeights = () => {
    document.documentElement.style.setProperty('--toolbar-height', `${toolbar.getBoundingClientRect().height}px`);
    if (window.matchMedia('(min-width: 761px)').matches) document.documentElement.style.setProperty('--header-height', `${document.querySelector('.site-header').getBoundingClientRect().height}px`);
    else document.documentElement.style.setProperty('--header-height', '0px');
  };
  document.body.classList.add('js');
  applyFilters(false);
  syncHeights();
  if ('ResizeObserver' in window) {
    const observer = new ResizeObserver(syncHeights);
    observer.observe(toolbar);
    observer.observe(document.querySelector('.site-header'));
  } else window.addEventListener('resize', syncHeights);
  const initialCategory = /^#categorie-(\d+)$/.exec(window.location.hash);
  if (initialCategory && sections.some(section => section.dataset.section === initialCategory[1])) chooseCategory(initialCategory[1]);
})();
