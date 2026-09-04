import { createRouter, createWebHistory } from 'vue-router'
import { useAuthStore } from '../stores/auth'

const routes = [
  { path: '/login', name: 'login', component: () => import('../views/LoginView.vue'), meta: { public: true } },
  { path: '/', redirect: '/pos' },
  { path: '/open', name: 'open', component: () => import('../views/pos/OpenRegisterView.vue') },
  { path: '/pos', name: 'pos', component: () => import('../views/pos/PosView.vue'), meta: { needsSession: true } },
  { path: '/close', name: 'close', component: () => import('../views/pos/CloseRegisterView.vue'), meta: { needsSession: true } },
  { path: '/tickets', name: 'tickets', component: () => import('../views/pos/TicketsView.vue') },
  {
    path: '/admin', component: () => import('../layouts/AdminLayout.vue'), meta: { perm: 'BACKOFFICE_ACCESS' },
    children: [
      { path: '', redirect: '/admin/dashboard' },
      { path: 'dashboard', name: 'admin-dashboard', component: () => import('../views/admin/DashboardView.vue'), meta: { title: 'Tableau de bord', perm: 'REPORTS_VIEW' } },
      { path: 'tickets', name: 'admin-tickets', component: () => import('../views/pos/TicketsView.vue'), meta: { title: 'Historique des tickets', perm: 'TICKETS_VIEW', embedded: true } },
      { path: 'journal', name: 'admin-journal', component: () => import('../views/admin/JournalView.vue'), meta: { title: 'Journal de caisse', perm: 'REVENUE_VIEW' } },
      { path: 'sessions', name: 'admin-sessions', component: () => import('../views/admin/SessionsView.vue'), meta: { title: 'Sessions & clôtures de caisse', perm: 'REVENUE_VIEW' } },
      { path: 'daily', name: 'admin-daily', component: () => import('../views/admin/DailyClosureView.vue'), meta: { title: 'Clôture journalière', perm: 'DAILY_CLOSE' } },
      { path: 'reports', name: 'admin-reports', component: () => import('../views/admin/ReportsView.vue'), meta: { title: 'Rapports', perm: 'REPORTS_VIEW' } },
      { path: 'products', name: 'admin-products', component: () => import('../views/admin/ProductsView.vue'), meta: { title: 'Produits & menus', perm: 'PRODUCTS_MANAGE' } },
      { path: 'categories', name: 'admin-categories', component: () => import('../views/admin/CategoriesView.vue'), meta: { title: 'Catégories', perm: 'PRODUCTS_MANAGE' } },
      { path: 'modifiers', name: 'admin-modifiers', component: () => import('../views/admin/ModifiersView.vue'), meta: { title: 'Options & suppléments', perm: 'PRODUCTS_MANAGE' } },
      { path: 'layout', name: 'admin-layout', component: () => import('../views/admin/PosLayoutView.vue'), meta: { title: 'Disposition POS & favoris', perm: 'PRODUCTS_MANAGE' } },
      { path: 'customers', name: 'admin-customers', component: () => import('../views/admin/CustomersView.vue'), meta: { title: 'Clients', perm: 'BACKOFFICE_ACCESS' } },
      { path: 'kitchen-notes', name: 'admin-kitchen-notes', component: () => import('../views/admin/KitchenNotesView.vue'), meta: { title: 'Remarques cuisine', perm: 'PRODUCTS_MANAGE' } },
      { path: 'couriers', name: 'admin-couriers', component: () => import('../views/admin/CouriersView.vue'), meta: { title: 'Livreurs', perm: 'BACKOFFICE_ACCESS' } },
      { path: 'users', name: 'admin-users', component: () => import('../views/admin/UsersView.vue'), meta: { title: 'Utilisateurs', perm: 'USERS_MANAGE' } },
      { path: 'roles', name: 'admin-roles', component: () => import('../views/admin/RolesView.vue'), meta: { title: 'Rôles & permissions', perm: 'USERS_MANAGE' } },
      { path: 'company', name: 'admin-company', component: () => import('../views/admin/CompanyView.vue'), meta: { title: 'Entreprise, points de vente & caisses', perm: 'SETTINGS_MANAGE' } },
      { path: 'payments', name: 'admin-payments', component: () => import('../views/admin/PaymentMethodsView.vue'), meta: { title: 'Moyens de paiement', perm: 'SETTINGS_MANAGE' } },
      { path: 'printing', name: 'admin-printing', component: () => import('../views/admin/PrintingView.vue'), meta: { title: 'Tickets & impression', perm: 'SETTINGS_MANAGE' } },
      { path: 'settings', name: 'admin-settings', component: () => import('../views/admin/SettingsView.vue'), meta: { title: 'Paramètres POS', perm: 'SETTINGS_MANAGE' } },
      { path: 'accounts', name: 'admin-accounts', component: () => import('../views/admin/AccountsView.vue'), meta: { title: 'Comptes clients & livreurs', perm: 'CUSTOMER_CREDIT' } },
      { path: 'audit', name: 'admin-audit', component: () => import('../views/admin/AuditView.vue'), meta: { title: "Journal d'audit", perm: 'AUDIT_VIEW' } }
    ]
  },
  { path: '/:pathMatch(.*)*', redirect: '/pos' }
]

const router = createRouter({ history: createWebHistory(), routes })

router.beforeEach(async (to) => {
  const auth = useAuthStore()
  if (!auth.ready) await auth.restore()
  if (to.meta.public) return auth.isAuthenticated && to.name === 'login' ? '/pos' : true
  if (!auth.isAuthenticated) return { name: 'login', query: { redirect: to.fullPath } }
  const perm = to.matched.map(r => r.meta.perm).filter(Boolean).pop()
  if (perm && !auth.can(perm)) return auth.can('SELL') ? '/pos' : '/admin/dashboard'
  if (to.meta.needsSession && !auth.session) return { name: 'open' }
  return true
})
export default router
