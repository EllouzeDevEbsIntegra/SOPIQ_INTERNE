# API REST — PosCaisse

Base : `http://localhost:8080/api`. Authentification : `Authorization: Bearer <jwt>` (sauf `/api/auth/**`). Réponses d'erreur : `{ status, code, message, fields?, timestamp }` avec message humain.

## Auth
| Méthode | URL | Description |
|---|---|---|
| GET | `/auth/users` | tuiles caissiers (public) |
| POST | `/auth/pin` `{userId?, pin}` | connexion PIN → `{token, user, openSession}` |
| POST | `/auth/login` `{username, password}` | connexion mot de passe |
| GET | `/auth/me` | utilisateur courant + session ouverte |
| POST | `/auth/change-pin`, `/auth/logout` | |

## POS (`/pos`)
| Méthode | URL | Description |
|---|---|---|
| GET | `/pos/catalog` | catégories, produits (options, menus), moyens de paiement, paramètres, entreprise |
| PATCH | `/pos/products/{id}/availability` `{available}` | disponible / indisponible |
| GET | `/pos/registers?posId=` | caisses + session ouverte éventuelle |
| GET | `/pos/session` | session ouverte de l'utilisateur |
| POST | `/pos/session/open` `{registerId, openingFloat}` | ouverture (409 si déjà ouverte) |
| GET | `/pos/session/{id}/summary` | totaux théoriques |
| POST | `/pos/session/{id}/close` `{countedCash, note}` | clôture |
| GET/POST | `/pos/session/{id}/movements` `{type IN/OUT, reason, amount, comment}` | mouvements |
| POST | `/pos/quote` | calcul de prix sans enregistrement |
| POST | `/pos/checkout` | **encaissement** (voir ci-dessous) |
| POST | `/pos/hold` | mise en attente (`heldOrderId` pour mettre à jour) |
| GET/DELETE | `/pos/held`, `/pos/held/{id}` | commandes en attente / abandon |
| GET/POST | `/pos/print-jobs/pending`, `/pos/print-jobs/ack` `{ids, failed}` | file d'impression (agent ESC/POS) |

### Checkout
```json
{
  "clientRef": "uuid-genere-par-le-frontend",
  "registerId": 1, "serviceMode": "TAKEAWAY", "customerName": null, "note": null,
  "discountPercent": 0, "discountAmount": 0, "heldOrderId": null,
  "lines": [
    { "productId": 2, "quantity": 2, "modifierIds": [6], "discountPercent": 0, "note": null },
    { "productId": 36, "quantity": 1, "components": [ { "productId": 2, "quantity": 1, "modifierIds": [6] }, { "productId": 27, "quantity": 1 }, { "productId": 17, "quantity": 1 } ] }
  ],
  "payments": [ { "paymentMethodId": 1, "amount": 20, "tendered": 20 }, { "paymentMethodId": 2, "amount": 12.5 } ]
}
```
Réponse : `OrderDto` (ticket, totaux, lignes, paiements, `changeAmount`, `printJobs[]` avec contenu texte). Un renvoi avec le même `clientRef` renvoie la même vente.

## Tickets (`/orders`)
`GET /orders?from&to&status&registerId&cashierId&posId&ticket&minAmount&maxAmount&method&sessionId&page&size`, `GET /orders/{id}`, `GET /orders/by-ticket/{n}`, `GET /orders/{id}/print-jobs`, `POST /orders/{id}/reprint`, `POST /orders/{id}/cancel {reason, refundMethodId?}`, `POST /orders/{id}/refund {amount, reason, paymentMethodId}`.

## Catalogue (permission PRODUCTS_MANAGE)
`/categories` (CRUD, `/reorder`), `/products` (CRUD, `/{id}/availability`, `/reorder`, `PUT /favorites`), `/modifiers` (CRUD), `/payment-methods` (SETTINGS_MANAGE).

## Caisse & clôtures
`GET /register-sessions?from&to`, `/register-sessions/{id}`, `/summary`, `/movements` ; `GET /journal?from&to&posId&registerId&userId&sessionId&event&limit` ; `GET /closures`, `GET /closures/preview?posId&date`, `POST /closures {pointOfSaleId, businessDate, note}`.

## Rapports (REPORTS_VIEW)
`GET /reports/dashboard?from&to&posId&registerId&cashierId` ; `GET /reports/{type}` et `GET /reports/{type}/csv` avec `type` ∈ daily, hourly, products, categories, cashiers, registers, pos, payments, discounts, cancellations, refunds, movements, closures, differences.

## Administration
`/users`, `/roles`, `/permissions` (USERS_MANAGE) ; `/settings/company`, `/points-of-sale`, `/registers`, `/print-destinations`, `/receipts/templates/{code}`, `/receipts/preview`, `/receipts/active`, `/settings` (SETTINGS_MANAGE pour l'écriture) ; `/customers` ; `/audit` (AUDIT_VIEW).
