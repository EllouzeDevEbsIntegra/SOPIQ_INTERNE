<script setup>
import { onMounted, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useAuthStore } from '../stores/auth'
import { useCatalogStore } from '../stores/catalog'
import Icon from '../components/common/Icon.vue'

const route = useRoute(); const router = useRouter(); const auth = useAuthStore(); const catalog = useCatalogStore()
const open = ref(false)
onMounted(() => catalog.load().catch(() => {}))

const nav = [
  { group: 'Activité', items: [
    { to: '/admin/dashboard', label: 'Tableau de bord', icon: 'chart', perm: 'REPORTS_VIEW' },
    { to: '/admin/tickets', label: 'Tickets', icon: 'receipt', perm: 'TICKETS_VIEW' },
    { to: '/admin/journal', label: 'Journal de caisse', icon: 'book', perm: 'REVENUE_VIEW' },
    { to: '/admin/sessions', label: 'Sessions de caisse', icon: 'lock', perm: 'REVENUE_VIEW' },
    { to: '/admin/daily', label: 'Clôture journalière', icon: 'moon', perm: 'DAILY_CLOSE' },
    { to: '/admin/reports', label: 'Rapports', icon: 'trend', perm: 'REPORTS_VIEW' },
    { to: '/admin/accounts', label: 'Comptes clients & livreurs', icon: 'coins', perm: 'CUSTOMER_CREDIT' } ] },
  { group: 'Catalogue', items: [
    { to: '/admin/products', label: 'Produits & menus', icon: 'box', perm: 'PRODUCTS_MANAGE' },
    { to: '/admin/categories', label: 'Catégories', icon: 'layers', perm: 'PRODUCTS_MANAGE' },
    { to: '/admin/modifiers', label: 'Options & suppléments', icon: 'sliders', perm: 'PRODUCTS_MANAGE' },
    { to: '/admin/kitchen-notes', label: 'Remarques cuisine', icon: 'note', perm: 'PRODUCTS_MANAGE' },
    { to: '/admin/layout', label: 'Disposition POS', icon: 'grid', perm: 'PRODUCTS_MANAGE' },
    { to: '/admin/customers', label: 'Clients', icon: 'users', perm: 'BACKOFFICE_ACCESS' },
    { to: '/admin/couriers', label: 'Livreurs', icon: 'truck', perm: 'BACKOFFICE_ACCESS' } ] },
  { group: 'Paramètres', items: [
    { to: '/admin/users', label: 'Utilisateurs', icon: 'user', perm: 'USERS_MANAGE' },
    { to: '/admin/roles', label: 'Rôles & permissions', icon: 'shield', perm: 'USERS_MANAGE' },
    { to: '/admin/company', label: 'Entreprise & caisses', icon: 'store', perm: 'SETTINGS_MANAGE' },
    { to: '/admin/payments', label: 'Moyens de paiement', icon: 'card', perm: 'SETTINGS_MANAGE' },
    { to: '/admin/printing', label: 'Tickets & impression', icon: 'printer', perm: 'SETTINGS_MANAGE' },
    { to: '/admin/settings', label: 'Paramètres POS', icon: 'settings', perm: 'SETTINGS_MANAGE' },
    { to: '/admin/audit', label: "Journal d'audit", icon: 'eye', perm: 'AUDIT_VIEW' } ] }
]
const initials = (n) => (n || '').split(/\s+/).slice(0, 2).map(w => w[0]).join('').toUpperCase()
function logout() { auth.logout(); router.replace('/login') }
</script>

<template>
  <div class="admin">
    <nav class="admin-nav" :class="{ open }" @click="open = false">
      <div class="brand">
        <span class="mark"><Icon name="store" :size="17" /></span>
        <span>PosCaisse<em>back-office</em></span>
      </div>
      <template v-for="g in nav" :key="g.group">
        <template v-if="g.items.some(i => auth.can(i.perm))">
          <div class="group">{{ g.group }}</div>
          <router-link v-for="i in g.items.filter(i => auth.can(i.perm))" :key="i.to" :to="i.to">
            <Icon :name="i.icon" :size="17" />{{ i.label }}
          </router-link>
        </template>
      </template>
      <div class="nav-foot">
        <router-link v-if="auth.can('SELL')" class="btn accent block" :to="auth.session ? '/pos' : '/open'">
          <Icon name="cart" :size="18" />Aller au POS
        </router-link>
        <button class="quit" @click="logout"><Icon name="logout" :size="17" />Déconnexion</button>
      </div>
    </nav>

    <div class="admin-main">
      <header class="admin-top">
        <button class="btn ghost icon burger" @click="open = !open"><Icon name="menu" :size="20" /></button>
        <h1>{{ route.meta.title }}</h1>
        <span class="shop">{{ catalog.company?.tradeName || catalog.company?.name }}</span>
        <span class="me" :title="auth.user?.roleName">
          <em>{{ initials(auth.user?.fullName) }}</em>
          <span class="who"><b>{{ auth.user?.fullName }}</b><i>{{ auth.user?.roleName }}</i></span>
        </span>
      </header>
      <div class="admin-content"><router-view /></div>
    </div>
  </div>
</template>

<style scoped>
.brand .mark { width: 28px; height: 28px; border-radius: var(--r-sm); background: var(--brand); color: #fff; display: flex; align-items: center; justify-content: center; }
.brand span { display: flex; flex-direction: column; line-height: 1.1; }
.brand em { font-style: normal; font-size: 10.5px; font-weight: 600; letter-spacing: .1em; text-transform: uppercase; color: #7C7167; }
.nav-foot { margin-top: auto; padding: 14px 14px 16px; display: flex; flex-direction: column; gap: 7px; }
.quit { display: flex; align-items: center; justify-content: center; gap: 8px; min-height: 40px; border-radius: var(--r); color: #A69C90; font-size: 14px; font-weight: 600; border: 1px solid rgba(255, 255, 255, .13); }
.quit:hover { background: rgba(255, 255, 255, .07); color: #fff; }

.shop { font-size: 12.5px; font-weight: 650; letter-spacing: .02em; color: var(--ink-3); text-transform: uppercase; }
.me { display: flex; align-items: center; gap: 9px; padding-left: 14px; border-left: 1px solid var(--line); }
.me em {
  width: 32px; height: 32px; border-radius: 50%; background: var(--ink); color: #fff;
  display: flex; align-items: center; justify-content: center;
  font-style: normal; font-size: 12px; font-weight: 700; letter-spacing: .02em;
}
.who { display: flex; flex-direction: column; line-height: 1.15; }
.who b { font-size: 13.5px; font-weight: 650; }
.who i { font-style: normal; font-size: 11px; color: var(--ink-3); }
.burger { display: none; }
@media (max-width: 1000px) { .burger { display: inline-flex; } .shop, .who { display: none; } }
</style>
