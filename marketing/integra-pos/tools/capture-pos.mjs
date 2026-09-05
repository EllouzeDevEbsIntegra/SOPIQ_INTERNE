import { chromium } from 'playwright';
const OUT = '../screenshots/';
const BASE = 'http://localhost:8080';
const b = await chromium.launch({ });
const ctx = await b.newContext({ viewport: { width: 1440, height: 900 }, deviceScaleFactor: 2, locale: 'fr-FR', timezoneId: 'Africa/Tunis' });
const p = await ctx.newPage();
const errors = [];
p.on('console', m => { if (m.type() === 'error') errors.push(m.text().slice(0, 200)); });
p.on('pageerror', e => errors.push('PAGEERROR ' + e.message));
let n = 0;
const shot = async (name) => { await p.waitForTimeout(500); n++; const f = `${String(n).padStart(2, '0')}-${name}.png`; await p.screenshot({ path: OUT + f }); console.log('📸', f); };
const step = async (name, fn) => { try { await fn(); } catch (e) { console.log('⚠️ step failed:', name, '-', e.message.split('\n')[0]); await p.screenshot({ path: '/home/user/poscaisse-run/debug-' + name.replace(/\W+/g, '_') + '.png' }).catch(() => {}); } };
const numpad = async (digits) => { for (const d of digits) await p.locator('.numpad button, .pad button', { hasText: new RegExp(`^${d}$`) }).first().click(); };

// ---------- caissier ----------
await p.goto(BASE + '/login', { waitUntil: 'networkidle' });
await p.waitForSelector('.person');
await shot('connexion-pin');
await p.locator('.person', { hasText: 'Ahmed' }).click();
await numpad('1234');
await p.getByRole('button', { name: 'Entrer' }).click();
await p.waitForURL(/\/(open|pos)/);
if (p.url().includes('/open')) {
  await p.waitForSelector('.reg');
  const free = p.locator('.reg:not(.taken)').first();
  await (await free.count() ? free : p.locator('.reg').first()).click();
  await numpad('100');
  await shot('ouverture-caisse');
  await p.locator('.go').click();
  await p.waitForURL(/\/pos/);
}
await p.waitForSelector('.tile');
await shot('pos-favoris-vide');

const addTile = async (name) => {
  const t = p.locator('.tile', { hasText: name }).first();
  await t.dispatchEvent('pointerdown'); await p.waitForTimeout(80); await t.dispatchEvent('pointerup');
  await p.waitForTimeout(300);
};
const confirmDialog = async () => {
  const btn = p.locator('.modal-foot .btn.success').last();
  if (await btn.count()) await btn.click();
};
const handleOptions = async (shotName) => {
  await p.waitForTimeout(400);
  if (!(await p.locator('.modal .group').count())) return false;
  const pickRequired = async (scope) => {
    const groups = p.locator(scope + ' .group'); const c = await groups.count();
    for (let i = 0; i < c; i++) {
      const g = groups.nth(i);
      if (await g.locator('.opt.on').count()) continue;
      const badge = await g.locator('.badge').first().textContent().catch(() => '');
      if (/obligatoire|au choix/.test(badge || '')) { await g.locator('.opt').first().click(); await p.waitForTimeout(250); }
    }
  };
  for (let k = 0; k < 4; k++) {
    if (await p.locator('.sub').count()) {
      await pickRequired('.sub');
      await p.locator('.sub button', { hasText: 'Terminer' }).click(); await p.waitForTimeout(300);
      continue;
    }
    await pickRequired('.modal-body');
    if (!(await p.locator('.sub').count())) break;
  }
  if (shotName) await shot(shotName);
  await confirmDialog();
  await p.waitForTimeout(400);
  return true;
};

await step('burgers', async () => {
  await p.locator('.rail .cat', { hasText: 'Burgers' }).click();
  await p.waitForTimeout(400);
  await addTile('Cheeseburger');
  await handleOptions('options-supplements-tap');
  await addTile('Cheeseburger');
  await handleOptions(null);
  await shot('pos-burgers-panier');
});
await step('options via cart', async () => {
  const opt = p.locator('.cart .act', { hasText: 'Options' }).first();
  if (await opt.count()) {
    await opt.click(); await p.waitForTimeout(500);
    // add a paid extra
    const extra = p.locator('.opt', { hasText: /Supplément fromage|fromage/i }).first();
    if (await extra.count()) await extra.click();
    await shot('options-supplements');
    await confirmDialog();
  }
});
await step('extras & drinks', async () => {
  await p.locator('.rail .cat', { hasText: 'Extras' }).click(); await p.waitForTimeout(300);
  await addTile('Frites'); await handleOptions(null);
  await p.locator('.rail .cat', { hasText: 'Boissons' }).click(); await p.waitForTimeout(300);
  await addTile('Coca'); await handleOptions(null);
  await addTile('Coca'); await handleOptions(null);
});
await step('menu', async () => {
  await p.locator('.rail .cat', { hasText: 'Menus' }).click(); await p.waitForTimeout(300);
  await addTile('Menu Burger');
  await handleOptions('composition-menu');
  await shot('pos-panier-complet');
});
await step('recherche', async () => {
  await p.fill('#pos-search', 'pizza'); await p.waitForTimeout(500);
  await shot('recherche-instantanee');
  await p.fill('#pos-search', '');
});
await step('remise', async () => {
  const d = p.locator('.cart .act', { hasText: 'Remise' }).first();
  if (await d.count()) { await d.click(); await p.waitForTimeout(500); await shot('remise-ligne');
    await p.reload({ waitUntil: 'networkidle' }); await p.waitForSelector('.tile'); await p.waitForTimeout(400); }
});
await step('paiement', async () => {
  await p.locator('.pay').click();
  await p.waitForSelector('.pay-grid');
  await shot('encaissement-a-payer');
  await p.locator('.chip', { hasText: /^50/ }).click(); await p.waitForTimeout(400);
  await shot('encaissement-especes-rendu');
  await p.locator('.btn.success.xl').click();
  await p.waitForSelector('.done', { timeout: 10000 });
  await shot('vente-enregistree');
});
await step('ticket', async () => {
  const nb = p.getByRole('button', { name: /Nouvelle commande/ });
  if (await nb.isVisible().catch(() => false)) await nb.click();
});
// several more sales for dashboard data
const quickSale = async (cat, items, method) => {
  await p.locator('.rail .cat', { hasText: cat }).click(); await p.waitForTimeout(250);
  for (const it of items) { await addTile(it); await handleOptions(null); }
  await p.locator('.pay').click(); await p.waitForSelector('.pay-grid');
  if (method) { await p.locator('.method', { hasText: method }).click(); await p.waitForTimeout(200); await p.locator('.chip.exact').click(); }
  else await p.locator('.chip.exact').click();
  await p.waitForTimeout(300);
  await p.locator('.btn.success.xl').click();
  await p.waitForSelector('.done', { timeout: 10000 });
  await p.getByRole('button', { name: /Nouvelle commande/ }).click();
  await p.waitForTimeout(300);
};
await step('paiement mixte', async () => {
  await p.locator('.rail .cat', { hasText: 'Pizzas' }).click(); await p.waitForTimeout(250);
  await addTile('Pepperoni'); await handleOptions(null);
  await addTile('Margherita'); await handleOptions(null);
  await p.locator('.rail .cat', { hasText: 'Desserts' }).click(); await p.waitForTimeout(250);
  await addTile('Tiramisu'); await handleOptions(null);
  await p.locator('.pay').click(); await p.waitForSelector('.pay-grid');
  await p.locator('.chip', { hasText: /^20/ }).click(); await p.waitForTimeout(200);
  await p.locator('.method', { hasText: 'Carte' }).click(); await p.waitForTimeout(200);
  await p.locator('.chip.exact').click(); await p.waitForTimeout(300);
  await shot('paiement-mixte');
  await p.locator('.btn.success.xl').click();
  await p.waitForSelector('.done', { timeout: 10000 });
  await p.getByRole('button', { name: /Nouvelle commande/ }).click();
});
await step('more sales', async () => {
  await quickSale('Sandwichs', ['Chawarma', 'Escalope']);
  await quickSale('Boissons', ['Jus', 'Café']);
  await quickSale('Salades', ['César'], 'Carte');
  await quickSale('Menus', ['Menu Pizza']);
  await quickSale('Burgers', ['Double Cheese', 'Chicken'], 'Ticket');
  await quickSale('Extras', ['Nuggets', 'Grande Frites']);
});
await step('attente', async () => {
  await p.locator('.rail .cat', { hasText: 'Sandwichs' }).click(); await p.waitForTimeout(250);
  await addTile('Kebab'); await handleOptions(null);
  await addTile('Thon'); await handleOptions(null);
  await p.locator('.cart .btn', { hasText: 'Attente' }).click(); await p.waitForTimeout(600);
  const tbHeld = p.locator('.tb-actions .tb-btn').first();
  await tbHeld.click(); await p.waitForTimeout(600);
  await shot('commandes-en-attente');
  await p.locator('button', { hasText: 'REPRENDRE' }).first().click(); await p.waitForTimeout(400);
  await p.locator('.cart .btn.danger', { hasText: 'Vider' }).click(); await p.waitForTimeout(300);
  const conf = p.locator('button', { hasText: /^(Vider|Confirmer|Oui)/ }).last(); if (await conf.isVisible().catch(() => false)) await conf.click();
});
await step('mouvement caisse', async () => {
  await p.locator('.tb-btn', { hasText: 'Caisse' }).click(); await p.waitForTimeout(500);
  await p.locator('.btn.chip').first().click().catch(() => {});
  await shot('entree-sortie-caisse');
  await p.reload({ waitUntil: 'networkidle' }); await p.waitForSelector('.tile');
});
await step('tickets', async () => {
  await p.locator('.tb-btn', { hasText: 'Tickets' }).click(); await p.waitForTimeout(800);
  await shot('historique-tickets');
  const row = p.locator('tr.clickable').first();
  if (await row.count()) { await row.click(); await p.waitForTimeout(600); await shot('detail-ticket'); }
  await p.reload({ waitUntil: 'networkidle' }); await p.waitForSelector('.tile');
});
await step('menu', async () => {
  await p.locator('.tb-icon').first().click(); await p.waitForTimeout(500);
  await shot('menu-caissier');
  await p.reload({ waitUntil: 'networkidle' }); await p.waitForSelector('.tile');
});
await step('cloture', async () => {
  await p.goto(BASE + '/close', { waitUntil: 'networkidle' });
  await p.waitForSelector('.close-card'); await p.waitForTimeout(500);
  await shot('cloture-caisse');
  await numpad('1'); await numpad('9'); await numpad('7');
  await p.waitForTimeout(300); await shot('cloture-ecart');
  await p.locator('.btn.danger.solid.xl').click();
  await p.waitForTimeout(1500); await shot('cloture-resultat');
});

// ---------- back-office ----------
const a = await ctx.newPage();
a.on('console', m => { if (m.type() === 'error') errors.push('ADMIN ' + m.text().slice(0, 200)); });
await a.goto(BASE + '/login', { waitUntil: 'networkidle' });
await a.evaluate(() => localStorage.clear());
await a.goto(BASE + '/login', { waitUntil: 'networkidle' });
await a.getByRole('button', { name: 'Administration' }).click();
await a.fill('input.input >> nth=0', 'admin'); await a.fill('input[type=password]', 'admin123');
await a.getByRole('button', { name: 'Se connecter' }).click();
await a.waitForTimeout(800);
const admin = async (path, name) => { await a.goto(BASE + '/admin/' + path, { waitUntil: 'networkidle' }); await a.waitForTimeout(900); n++; const f = `${String(n).padStart(2, '0')}-admin-${name}.png`; await a.screenshot({ path: OUT + f }); console.log('📸', f); };
for (const [path, name] of [['dashboard','tableau-de-bord'],['tickets','tickets'],['journal','journal-caisse'],['sessions','sessions'],['daily','cloture-journaliere'],['reports','rapports'],['products','produits-menus'],['categories','categories'],['modifiers','options-supplements'],['layout','disposition-pos'],['customers','clients'],['users','utilisateurs'],['roles','roles-permissions'],['company','entreprise-caisses'],['payments','moyens-paiement'],['printing','tickets-impression'],['settings','parametres-pos'],['audit','journal-audit']]) await admin(path, name);

console.log('ERRORS:', errors.length); errors.slice(0, 10).forEach(e => console.log(' -', e));
await b.close();
