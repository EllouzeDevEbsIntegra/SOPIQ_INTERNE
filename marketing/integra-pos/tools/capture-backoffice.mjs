import { chromium } from 'playwright';
import { execSync } from 'node:child_process';
const OUT = '../screenshots/';
const BASE = 'http://localhost:8080';
const b = await chromium.launch({ });
const ctx = await b.newContext({ viewport: { width: 1440, height: 900 }, deviceScaleFactor: 2, locale: 'fr-FR', timezoneId: 'Africa/Tunis' });
const p = await ctx.newPage();
const numpad = async (digits) => { for (const d of digits) await p.locator('.numpad button, .pad button', { hasText: new RegExp(`^${d === ',' ? ',' : d}$`) }).first().click(); };
await p.goto(BASE + '/login', { waitUntil: 'networkidle' });
await p.locator('.person', { hasText: 'Ahmed' }).click(); await numpad('1234'); await p.getByRole('button', { name: 'Entrer' }).click();
await p.waitForURL(/\/(open|pos)/);
await p.goto(BASE + '/close', { waitUntil: 'networkidle' }); await p.waitForSelector('.l.total'); await p.waitForTimeout(600);
const theo = (await p.locator('.l.total .num').first().textContent()).replace(/[^\d,]/g, '');
console.log('théorique', theo);
await numpad('C'); await numpad(theo.replace(/\s/g, ''));
await p.waitForTimeout(400); await p.screenshot({ path: OUT + '19-cloture-ecart.png' });
await p.locator('.btn.danger.solid.xl').click(); await p.waitForTimeout(500);
await p.locator('.modal-foot button', { hasText: /^Clôturer$/ }).click();
await p.waitForSelector('.result', { timeout: 10000 }); await p.waitForTimeout(600);
await p.screenshot({ path: OUT + '20-cloture-resultat.png' }); console.log('📸 clôture ok');

// spread demo sale times across the day (11h → 21h Tunis) so hourly charts show a real service curve
execSync(`su postgres -c "psql -d poscaisse -q -c \\"
WITH o AS (SELECT id, row_number() OVER (ORDER BY paid_at) AS rn, count(*) OVER () AS n FROM sale_order WHERE paid_at IS NOT NULL),
t AS (SELECT id, (date_trunc('day', now() AT TIME ZONE 'Africa/Tunis') + interval '11 hours' + (interval '10 hours' * (rn - 1) / greatest(n - 1, 1))) AT TIME ZONE 'Africa/Tunis' AS ts FROM o)
UPDATE sale_order s SET paid_at = t.ts, created_at = t.ts - interval '3 minutes', updated_at = t.ts FROM t WHERE s.id = t.id;\\""`);
execSync(`su postgres -c "psql -d poscaisse -q -c \\"UPDATE payment p SET created_at = s.paid_at FROM sale_order s WHERE p.order_id = s.id;\\""`, { stdio: 'ignore' });
console.log('SQL ok');

const a = await ctx.newPage();
await a.goto(BASE + '/login', { waitUntil: 'networkidle' }); await a.evaluate(() => localStorage.clear());
await a.goto(BASE + '/login', { waitUntil: 'networkidle' });
await a.getByRole('button', { name: 'Administration' }).click();
await a.fill('input.input >> nth=0', 'admin'); await a.fill('input[type=password]', 'admin123');
await a.getByRole('button', { name: 'Se connecter' }).click(); await a.waitForTimeout(800);
let n = 20;
for (const [path, name] of [['dashboard','tableau-de-bord'],['tickets','tickets'],['journal','journal-caisse'],['sessions','sessions'],['daily','cloture-journaliere'],['reports','rapports'],['products','produits-menus'],['categories','categories'],['modifiers','options-supplements'],['layout','disposition-pos'],['customers','clients'],['users','utilisateurs'],['roles','roles-permissions'],['company','entreprise-caisses'],['payments','moyens-paiement'],['printing','tickets-impression'],['settings','parametres-pos'],['audit','journal-audit']]) {
  await a.goto(BASE + '/admin/' + path, { waitUntil: 'networkidle' }); await a.waitForTimeout(900); n++;
  await a.screenshot({ path: `${OUT}${n}-admin-${name}.png` });
}
console.log('📸 admin ok'); await b.close();
