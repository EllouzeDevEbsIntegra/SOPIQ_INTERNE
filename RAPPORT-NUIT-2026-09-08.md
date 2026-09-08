# Ce qui a été fait cette nuit — 08/09/2026

Résumé pour la reprise. Tout est sur la branche `claude/poscaisse-full-app-omsdd4`,
poussé au fur et à mesure. **`PosCaisse/` — la verticale Resto livrée à NUMBER ONE — n'a
pas été touchée d'une ligne.**

---

## 1. Le code vivant est sorti du code livré

`Plateforme/` est la copie de la caisse prise cette nuit. C'est elle qui évolue désormais ;
`PosCaisse/` reste figée, et ne bougera plus que pour une anomalie de ce client.

Le métier n'y est plus un logiciel mais un **profil** : des réglages, une carte de
démonstration, des écrans activés. Le noyau — caisse, panier, encaissement, tickets,
clôtures — ne se duplique jamais.

## 2. Six métiers, six cartes de démonstration

| Métier | Carte | Articles | Ce qu'elle démontre |
|---|---|---:|---|
| Resto | `number-one-2026.json` | 117 | *(client réel — à remplacer par une carte neutre avant de vendre ce profil)* |
| **Café** | `mistral-coffee.json` | 112 | goûts de chicha en variante, jeux de table facturés |
| **Shop** | `superette-el-baraka.json` | 187 | codes-barres, prix d'achat, stock par article |
| **Pâtisserie** | `dar-halwa.json` | 71 | vente au kilo, commandes de fête |
| **Parfumerie** | `nour-parfums.json` | 76 | contenances 30/50/100/200 ml en variante |
| **Prêt-à-porter** | `style-boutique.json` | 65 | tailles en variante, prix d'achat |

Les six s'importent sans un avertissement, et le café comme la boutique ont été vérifiés à
l'écran, dans un navigateur.

**Les codes-barres.** 36 sont **réels** — relevés en base publique sur de vrais produits
tunisiens (Safia, Marwa, Boga, Délice, Vitalait, Saïda, Céréalis, Warda, Sidi Daoud, Sicam,
Jouda, Bondin, Ben Yedder). Les autres sont construits sur le **préfixe 2, réservé à l'usage
interne des magasins** : ils ne peuvent entrer en conflit avec aucun produit du commerce, et
se remplacent au scan à la mise en service. Inventer des 619 aurait produit des codes qui
ont l'air vrais et faussent un inventaire.

## 3. La verticale Shop, de bout en bout

- **Code-barres** sur la fiche article, unique quand il existe, et **le scan en caisse** :
  le lecteur est un clavier, on le reconnaît à sa vitesse de frappe — rien à installer.
- **Stock par article**, à côté de celui des pâtes, avec le même verrou : prix d'achat gardé
  sur chaque entrée, casse avec motif, et un **inventaire qui pose le chiffre compté** et
  déduit l'écart — on ne fait pas de soustraction devant un rayon.
- **Trois réglages** commandent tout : qui est compté (rien / certains / tous), ce qui
  arrive en rupture (refuser / avertir / laisser passer), comment le stock entre (achat
  tracé / saisie libre). Aucun n'est réservé à un métier.
- Un écran de stock bâti sur la recherche et le scan : deux cents articles ne se parcourent
  pas.

## 4. Sécurité : cinq défauts trouvés, cinq corrigés

Détail complet dans `Plateforme/SECURITE.md`.

1. **On pouvait essayer les dix mille PIN à la suite** → l'attente double à chaque échec,
   par adresse *et* par compte, sans jamais bloquer un caissier.
2. **Une clé de signature commune à toutes les installations** → chacune tire la sienne,
   rangée là où aucun endpoint ne la lit.
3. **Un caissier lisait la caisse d'un collègue** en devinant un numéro → fermé.
4. **La marge du patron partait dans chaque catalogue** → le catalogue n'envoie plus qu'une
   liste nommée de réglages, et le bénéfice est réservé au droit « voir les recettes ».
5. CORS refuse le joker avec identifiants ; BCrypt passe au coût de référence.

Chacun a son test. Ce qui reste à faire avant d'ouvrir sur internet est listé, honnêtement.

## 5. La plateforme SaaS

**L'architecture est tranchée** (`Plateforme/ARCHITECTURE-SAAS.md`) : une application, une
base par client, aiguillée par le client porté dans le jeton ; deux applications séparées
— la caisse et le back-office éditeur — parce qu'une faille dans la caisse d'un commerçant
ne doit pas donner la liste de trois cents commerçants.

**Le back-office éditeur existe et tourne** (`Plateforme/plateforme/`) : clients,
abonnements, licences, facturation, impayés, journal. Avec son écran.

Trois décisions y sont écrites plutôt que supposées :
- la **licence est vérifiée au serveur**, pas posée sur le poste ;
- **suspendu n'est pas coupé** : la caisse passe en lecture seule et le dit en français —
  prendre ses données à un commerçant pour quarante dinars serait une faute ;
- le **solde se déduit** au lieu d'être stocké.

## 6. Les tests

**58 au vert** : 50 sur la caisse (dont 11 scénarios d'intégration, y compris le Shop
complet et la sécurité) et 8 sur la plateforme (du prospect à l'impayé).

---

## Pour voir tourner, au réveil

```bash
# la caisse, profil Café
createdb mistral && cd Plateforme/backend
POSCAISSE_DB_NAME=mistral mvn spring-boot:run          # puis charger mistral-coffee.json

# la caisse, profil Shop (code-barres + stock)
createdb elbaraka
POSCAISSE_DB_NAME=elbaraka mvn spring-boot:run         # puis superette-el-baraka.json

# le back-office éditeur
createdb plateforme && cd Plateforme/plateforme
mvn spring-boot:run                                    # http://localhost:8090 — admin / plateforme123
```

## Ce que je n'ai pas fait, et pourquoi

- **Le provisionnement automatique** d'un client (créer sa base, la migrer, y charger sa
  carte, rendre les accès). Le modèle prévoit déjà où l'écrire ; c'est la prochaine étape
  et elle demande d'être faite proprement, pas à 5 h du matin.
- **L'aiguillage multi-clients** dans la caisse : c'est le chantier suivant, avec le test
  qui interdit qu'une requête parte sans contexte.
- **Taille × couleur** pour le prêt-à-porter (un seul axe de variante aujourd'hui), la
  **vente au poids** pour la pâtisserie, les **pointures**. Les trois sont notés dans
  `Plateforme/catalogs/LISEZ-MOI-CARTES.md`.
- **L'interface du back-office éditeur** est un premier écran, pas le produit fini : il
  faudra la refaire avec le même jeu de composants que la caisse.
