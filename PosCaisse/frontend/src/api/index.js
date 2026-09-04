import { http } from './http'
const g = (u, params) => http.get(u, { params }).then(r => r.data)
const p = (u, d) => http.post(u, d).then(r => r.data)
const put = (u, d) => http.put(u, d).then(r => r.data)
const patch = (u, d) => http.patch(u, d).then(r => r.data)
const del = (u) => http.delete(u).then(r => r.data)
/* Telechargement d'un fichier produit par le serveur : on passe par axios pour garder
   le jeton et le traitement d'erreur communs, puis on declenche l'enregistrement. */
const download = (u, params, fallbackName) => http.get(u, { params, responseType: 'blob' }).then(r => {
  const disp = r.headers['content-disposition'] || ''
  const m = /filename\*?=(?:UTF-8'')?"?([^";]+)"?/i.exec(disp)
  const name = m ? decodeURIComponent(m[1]) : fallbackName
  const url = URL.createObjectURL(r.data)
  const a = document.createElement('a')
  a.href = url; a.download = name
  document.body.appendChild(a); a.click(); a.remove()
  setTimeout(() => URL.revokeObjectURL(url), 4000)
  return name
})

export const api = {
  auth: {
    users: () => g('/auth/users'), pin: (userId, pin) => p('/auth/pin', { userId, pin }),
    login: (username, password) => p('/auth/login', { username, password }), me: () => g('/auth/me'),
    logout: () => p('/auth/logout'), changePin: (currentPin, newPin) => p('/auth/change-pin', { currentPin, newPin }),
    branding: () => g('/public/branding')
  },
  pos: {
    catalog: () => g('/pos/catalog'), registers: (posId) => g('/pos/registers', { posId }), session: () => g('/pos/session'),
    openSession: (registerId, openingFloat) => p('/pos/session/open', { registerId, openingFloat }),
    summary: (id) => g(`/pos/session/${id}/summary`), close: (id, body) => p(`/pos/session/${id}/close`, body),
    movements: (id) => g(`/pos/session/${id}/movements`), addMovement: (id, body) => p(`/pos/session/${id}/movements`, body),
    quote: (cart) => p('/pos/quote', cart), checkout: (body) => p('/pos/checkout', body), hold: (cart) => p('/pos/hold', cart),
    held: (posId) => g('/pos/held', { posId }), abandon: (id) => del(`/pos/held/${id}`),
    availability: (id, available) => patch(`/pos/products/${id}/availability`, { available }),
    ackPrint: (ids, failed = false) => p('/pos/print-jobs/ack', { ids, failed })
  },
  orders: {
    search: (params) => g('/orders', params), get: (id) => g(`/orders/${id}`), byTicket: (t) => g(`/orders/by-ticket/${encodeURIComponent(t)}`),
    jobs: (id) => g(`/orders/${id}/print-jobs`), reprint: (id) => p(`/orders/${id}/reprint`),
    cancel: (id, reason, refundMethodId) => p(`/orders/${id}/cancel`, { reason, refundMethodId }),
    refund: (id, body) => p(`/orders/${id}/refund`, body)
  },
  catalog: {
    categories: () => g('/categories'), saveCategory: (id, b) => id ? put(`/categories/${id}`, b) : p('/categories', b), deleteCategory: (id) => del(`/categories/${id}`),
    reorderCategories: (ids) => p('/categories/reorder', { ids }),
    products: () => g('/products'), product: (id) => g(`/products/${id}`), saveProduct: (id, b) => id ? put(`/products/${id}`, b) : p('/products', b),
    deleteProduct: (id) => del(`/products/${id}`), availability: (id, available) => patch(`/products/${id}/availability`, { available }),
    reorderProducts: (ids) => p('/products/reorder', { ids }), favorites: (productIds) => put('/products/favorites', { productIds }),
    modifiers: () => g('/modifiers'), saveModifier: (id, b) => id ? put(`/modifiers/${id}`, b) : p('/modifiers', b), deleteModifier: (id) => del(`/modifiers/${id}`),
    paymentMethods: () => g('/payment-methods'), savePaymentMethod: (id, b) => id ? put(`/payment-methods/${id}`, b) : p('/payment-methods', b)
  },
  registers: {
    sessions: (params) => g('/register-sessions', params), session: (id) => g(`/register-sessions/${id}`), summary: (id) => g(`/register-sessions/${id}/summary`),
    movements: (id) => g(`/register-sessions/${id}/movements`), journal: (params) => g('/journal', params),
    closures: () => g('/closures'), closurePreview: (posId, date) => g('/closures/preview', { posId, date }), dailyClose: (b) => p('/closures', b)
  },
  admin: {
    users: () => g('/users'), saveUser: (id, b) => id ? put(`/users/${id}`, b) : p('/users', b), deleteUser: (id) => del(`/users/${id}`),
    roles: () => g('/roles'), saveRole: (id, b) => id ? put(`/roles/${id}`, b) : p('/roles', b), deleteRole: (id) => del(`/roles/${id}`), permissions: () => g('/permissions'),
    company: () => g('/settings/company'), saveCompany: (b) => put('/settings/company', b),
    pointsOfSale: () => g('/points-of-sale'), savePos: (id, b) => id ? put(`/points-of-sale/${id}`, b) : p('/points-of-sale', b),
    registers: () => g('/registers'), saveRegister: (id, b) => id ? put(`/registers/${id}`, b) : p('/registers', b),
    destinations: () => g('/print-destinations'), saveDestination: (id, b) => id ? put(`/print-destinations/${id}`, b) : p('/print-destinations', b), deleteDestination: (id) => del(`/print-destinations/${id}`),
    templates: () => g('/receipts/templates'), activeTemplate: () => g('/receipts/active'), saveTemplate: (code, b) => put(`/receipts/templates/${code}`, b), previewReceipt: (b) => p('/receipts/preview', b),
    settings: () => g('/settings'), saveSettings: (b) => put('/settings', b),
    customers: (q) => g('/customers', { q }), saveCustomer: (id, b) => id ? put(`/customers/${id}`, b) : p('/customers', b),
    couriers: (q, activeOnly) => g('/couriers', { q, activeOnly }), saveCourier: (id, b) => id ? put(`/couriers/${id}`, b) : p('/couriers', b),
    kitchenNotes: () => g('/kitchen-notes'), saveKitchenNote: (id, b) => id ? put(`/kitchen-notes/${id}`, b) : p('/kitchen-notes', b),
    deleteKitchenNote: (id) => del(`/kitchen-notes/${id}`), reorderKitchenNotes: (ids) => p('/kitchen-notes/reorder', { ids }),
    audit: (params) => g('/audit', params)
  },
  /* Comptes a credit : « party » vaut CUSTOMER ou COURIER, les deux se tiennent pareil. */
  accounts: {
    balances: (party, withDebtOnly) => g(`/accounts/${party}`, { withDebtOnly }),
    statement: (party, partyId, params) => g(`/accounts/${party}/${partyId}`, params),
    statementPdf: (party, partyId, params) => download(`/accounts/${party}/${partyId}/pdf`, params, 'releve.pdf'),
    pay: (party, b) => p(`/accounts/${party}/payments`, b),
    deletePayment: (party, id) => del(`/accounts/${party}/payments/${id}`)
  },
  reports: {
    dashboard: (params) => g('/reports/dashboard', params), report: (type, params) => g(`/reports/${type}`, params),
    csvUrl: (type, params) => '/api/reports/' + type + '/csv?' + new URLSearchParams(Object.fromEntries(Object.entries(params || {}).filter(([, v]) => v !== null && v !== undefined && v !== ''))).toString()
  }
}
