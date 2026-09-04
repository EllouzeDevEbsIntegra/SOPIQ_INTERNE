# Tickets & impression

## Flux
1. `POST /api/pos/checkout` → `PrintService.createJobs(order)` :
   - une destination de type **CUSTOMER** active → *Ticket client* (tous les produits, prix, total, paiements, rendu) ;
   - pour chaque destination **PREP** active (Cuisine, Pizza, Boissons, Passe…) : les lignes dont le produit (ou un composant du menu) est associé à la destination — directement (`product_print_destination`) ou via la catégorie (`category.print_destination_id`) ; s'il y a au moins une ligne → un `print_job` ;
   - `copies` de la destination (0 = jamais imprimée).
2. Le contenu est du **texte monospace** : 42 colonnes (80 mm) ou 32 colonnes (58 mm), généré par `ReceiptRenderer` selon le modèle actif (`receipt_template`, code `receipt.template` dans les paramètres).
3. Le frontend affiche les tickets (`ReceiptDialog` / écran « Vente enregistrée ») et imprime via une iframe (`usePrinter.js`) : `@page { size: 58mm|80mm auto }`, N copies, saut de page entre tickets ; puis `POST /api/pos/print-jobs/ack`.
4. Réimpression : `POST /api/orders/{id}/reprint` → nouveaux jobs marqués `duplicate` (mention *** DUPLICATA ***).

## Exemple de routage
Commande : 2 Burgers, 1 Pizza, 3 Coca → *Ticket client* (tout), *Cuisine* (burgers), *Pizza* (pizza), *Boissons* (Coca).

## Configuration
- **Destinations** (back-office → Tickets & impression) : code, nom, type, copies, prix affichés, ordre, actif.
- **Modèle** : largeur 58/80, police, marges, logo, en-tête, pied, séparateur, champs affichés (ticket, date, heure, caissier, caisse, mode, client, articles, prix unitaire, options, remises, sous-total, TVA, paiements, rendu, duplicata) — aperçu live sur la dernière vente.
- **Produits** : destinations spécifiques (sinon celle de la catégorie). Nom court ticket.

## Imprimantes thermiques (évolution)
Les `print_job` restent en `PENDING` jusqu'à acquittement. Un agent local (Windows, Node ou Java) peut :
```
GET  /api/pos/print-jobs/pending   → [{id, destinationCode, copies, content}]
→ conversion ESC/POS (ESC @, texte CP858/CP1252, GS V 0 pour la coupe, ESC p pour le tiroir)
POST /api/pos/print-jobs/ack {ids:[...], failed:false}
```
Le texte est déjà calibré en colonnes, aucune mise en page supplémentaire n'est nécessaire. Un mapping destination → imprimante (USB/réseau) suffit.
