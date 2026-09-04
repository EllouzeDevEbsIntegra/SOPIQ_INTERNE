// Minimal i18n structure: French today, Arabic/English can be added as new dictionaries.
const fr = {
  serviceMode: { DINE_IN: 'Sur place', TAKEAWAY: 'À emporter', DELIVERY: 'Livraison' },
  orderStatus: { HELD: 'En attente', PAID: 'Encaissé', CANCELLED: 'Annulé', REFUNDED: 'Remboursé', PARTIALLY_REFUNDED: 'Remb. partiel' },
  journalEvent: { SESSION_OPEN: 'Ouverture caisse', SALE: 'Vente', PAYMENT: 'Paiement', CANCELLATION: 'Annulation', REFUND: 'Remboursement', CASH_IN: 'Entrée espèces', CASH_OUT: 'Sortie espèces', SESSION_CLOSE: 'Clôture caisse', DAILY_CLOSE: 'Clôture journée' },
  paymentKind: { CASH: 'Espèces', CARD: 'Carte', CHECK: 'Chèque', MEAL_VOUCHER: 'Ticket restaurant', OTHER: 'Autre' },
  permission: {
    REGISTER_OPEN: 'Ouvrir la caisse', SELL: 'Vendre', DISCOUNT_APPLY: 'Appliquer une remise', DISCOUNT_HIGH: 'Remise supérieure au seuil', PRICE_EDIT: 'Modifier un prix',
    LINE_DELETE: 'Supprimer une ligne', ORDER_CANCEL: 'Abandonner une commande', TICKET_CANCEL: 'Annuler un ticket encaissé', REFUND: 'Rembourser', DRAWER_OPEN: 'Ouvrir le tiroir',
    REVENUE_VIEW: 'Consulter le CA', CASH_MOVEMENT: 'Mouvements de caisse', REGISTER_CLOSE: 'Clôturer la caisse', DAILY_CLOSE: 'Clôture journalière', PRODUCTS_MANAGE: 'Gérer le catalogue',
    USERS_MANAGE: 'Gérer les utilisateurs', SETTINGS_MANAGE: 'Gérer les paramètres', REPORTS_VIEW: 'Consulter les rapports', TICKETS_VIEW: 'Consulter les tickets', TICKETS_REPRINT: 'Réimprimer',
    BACKOFFICE_ACCESS: 'Accès back-office', AUDIT_VIEW: "Consulter l'audit"
  }
}
const dict = { fr }
let lang = 'fr'
export function setLang(l) { if (dict[l]) lang = l }
export function t(group, key) { return dict[lang]?.[group]?.[key] ?? key }
export const serviceModeLabel = (k) => t('serviceMode', k)
export const statusLabel = (k) => t('orderStatus', k)
export const eventLabel = (k) => t('journalEvent', k)
export const permissionLabel = (k) => t('permission', k)
