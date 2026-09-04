# TODO — éléments réellement restants

- [ ] Pilote d'impression thermique ESC/POS (agent local consommant `GET /api/pos/print-jobs/pending` puis `POST /api/pos/print-jobs/ack`) — l'architecture est prête, aucun matériel testé.
- [ ] Remboursement partiel par sélection de lignes (aujourd'hui : par montant).
- [ ] Export Excel natif (xlsx) — CSV disponible.
- [ ] Dictionnaires arabe / anglais (structure `utils/i18n.js` prête, RTL à prévoir).
- [ ] Stockage des images produits sur disque plutôt qu'en data-URI.
- [ ] Ouverture physique du tiroir-caisse (`payment_method.opens_drawer` est stocké, pas de commande matérielle).
- [ ] Tests end-to-end Playwright versionnés dans le dépôt (scénario exécuté manuellement pendant le développement).
