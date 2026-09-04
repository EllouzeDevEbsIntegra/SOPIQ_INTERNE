<script setup>
import { onMounted, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useAuthStore } from '../stores/auth'
import { useCatalogStore } from '../stores/catalog'
const route = useRoute(); const router = useRouter(); const auth = useAuthStore(); const catalog = useCatalogStore()
const open = ref(false)
onMounted(() => catalog.load().catch(() => {}))
const nav = [
  { group: 'Activité', items: [
    { to: '/admin/dashboard', label: 'Tableau de bord', icon: '📊', perm: 'REPORTS_VIEW' }, { to: '/admin/tickets', label: 'Tickets', icon: '🧾', perm: 'TICKETS_VIEW' },
    { to: '/admin/journal', label: 'Journal de caisse', icon: '📒', perm: 'REVENUE_VIEW' }, { to: '/admin/sessions', label: 'Sessions de caisse', icon: '🔐', perm: 'REVENUE_VIEW' },
    { to: '/admin/daily', label: 'Clôture journalière', icon: '🌙', perm: 'DAILY_CLOSE' }, { to: '/admin/reports', label: 'Rapports', icon: '📈', perm: 'REPORTS_VIEW' } ] },
  { group: 'Catalogue', items: [
    { to: '/admin/products', label: 'Produits & menus', icon: '🍔', perm: 'PRODUCTS_MANAGE' }, { to: '/admin/categories', label: 'Catégories', icon: '🗂', perm: 'PRODUCTS_MANAGE' },
    { to: '/admin/modifiers', label: 'Options & suppléments', icon: '➕', perm: 'PRODUCTS_MANAGE' }, { to: '/admin/layout', label: 'Disposition POS', icon: '⭐', perm: 'PRODUCTS_MANAGE' },
    { to: '/admin/customers', label: 'Clients', icon: '👤', perm: 'BACKOFFICE_ACCESS' } ] },
  { group: 'Paramètres', items: [
    { to: '/admin/users', label: 'Utilisateurs', icon: '👥', perm: 'USERS_MANAGE' }, { to: '/admin/roles', label: 'Rôles & permissions', icon: '🛡', perm: 'USERS_MANAGE' },
    { to: '/admin/company', label: 'Entreprise & caisses', icon: '🏪', perm: 'SETTINGS_MANAGE' }, { to: '/admin/payments', label: 'Moyens de paiement', icon: '💳', perm: 'SETTINGS_MANAGE' },
    { to: '/admin/printing', label: 'Tickets & impression', icon: '🖨', perm: 'SETTINGS_MANAGE' }, { to: '/admin/settings', label: 'Paramètres POS', icon: '⚙', perm: 'SETTINGS_MANAGE' },
    { to: '/admin/audit', label: "Journal d'audit", icon: '🔎', perm: 'AUDIT_VIEW' } ] }
]
function logout() { auth.logout(); router.replace('/login') }
</script>
<template>
  <div class="admin">
    <nav class="admin-nav" :class="{ open }" @click="open=false">
      <div class="brand">🧾 PosCaisse <span class="tiny" style="color:#64748b;font-weight:500">back-office</span></div>
      <template v-for="g in nav" :key="g.group">
        <template v-if="g.items.some(i => auth.can(i.perm))">
          <div class="group">{{ g.group }}</div>
          <router-link v-for="i in g.items.filter(i => auth.can(i.perm))" :key="i.to" :to="i.to"><span>{{ i.icon }}</span>{{ i.label }}</router-link>
        </template>
      </template>
      <div style="margin-top:auto;padding:14px 18px" class="col gap-6">
        <router-link class="btn accent block" v-if="auth.can('SELL')" :to="auth.session ? '/pos' : '/open'">🛒 Aller au POS</router-link>
        <button class="btn block" style="background:transparent;color:#cbd5e1;border-color:#334155" @click="logout">Déconnexion</button>
      </div>
    </nav>
    <div class="admin-main">
      <div class="admin-top">
        <button class="btn ghost icon burger" @click="open=!open">☰</button>
        <h1>{{ route.meta.title }}</h1>
        <span class="badge">{{ catalog.company?.tradeName || catalog.company?.name }}</span>
        <span class="badge info">{{ auth.user.fullName }} · {{ auth.user.roleName }}</span>
      </div>
      <div class="admin-content"><router-view /></div>
    </div>
  </div>
</template>
<style scoped>
.burger { display: none; } @media (max-width: 900px) { .burger { display: inline-flex; } }
</style>
