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

# La suite — matin du 08/09

## 7. Un poste neuf s'installe seul dans son métier

Vendre un abonnement créait une base vide. Il fallait ensuite ouvrir un terminal chez le
client, lancer un script contre la caisse avec le mot de passe administrateur, et cocher
une à une les cases du métier. Trois cents clients, c'est trois cents fois ça.

Le poste se configure maintenant **lui-même**, à partir de la commande que le back-office
rend à la vente. Il pose son schéma, écrit les réglages de son métier, et charge la carte
de sa verticale depuis son propre JAR.

```
LANG=C.UTF-8 POSCAISSE_DB_NAME=pos_cli0004_cafe POSCAISSE_DB_USER=… POSCAISSE_DB_PASSWORD=… \
POSCAISSE_PROFIL=CAFE POSCAISSE_ENSEIGNE='CAFÉ DES DÉLICES' POSCAISSE_DEMO_DATA=true \
java -jar poscaisse.jar
```

Le bouton du back-office demande d'abord **« la carte de démonstration »** ou **« repartir
de zéro »**. À zéro : la maison, une caisse, le compte administrateur, les réglages du
métier — et un catalogue vide, sans adresse inventée sur les tickets.

Les six métiers tiennent dans une table de déclarations. Ouvrir le septième : un fichier
de carte et une ligne. **`Plateforme/PROFILS-METIER.md`** explique comment.

## 8. Vendre au poids — la pâtisserie fait enfin son métier

Un article à 58 dinars le kilo ne se vendait qu'au kilo entier. Toucher sa tuile ouvre
maintenant une pesée : on tape des **grammes**, ou un **montant en dinars** (« pour cinq
dinars de baklawa »), et la caisse fait la division. Le ticket dit `0,300 kg x Baklawa
amande` puis `à 58,000 le kg`.

## 9. Trois défauts de sécurité et de justesse, trouvés en s'en servant

- **Le compte d'un client ouvrait la base d'un autre.** Il n'y lisait aucune vente, mais il
  entrait, et le catalogue partagé lui donnait le nom de toutes les bases — donc de tous
  nos clients. PostgreSQL accorde `CONNECT` à `PUBLIC` sur toute base neuve. Corrigé, et
  relancer le provisionnement **répare** une base ancienne : les quatre déjà créées ont été
  refermées sans interrompre la caisse qui tournait sur l'une d'elles. *(`SECURITE.md` § 6)*
- **L'enseigne accentuée arrivait abîmée.** Une machine démarrée sans langue lit son
  environnement en ASCII : « SUPÉRETTE » y perdait son É, et ce nom se serait imprimé sur
  chaque ticket. La commande porte `LANG=C.UTF-8`, et la caisse refuse d'enregistrer un nom
  abîmé plutôt que de le graver.
- **La deuxième facture de l'année s'appelait `FAC-2026-0000`**, et la troisième aussi.

## 10. Deux suites de tests qui ne passaient qu'une fois

Le scénario de vente laissait une caisse ouverte et un catalogue purgé ; rejoué, il
recevait 409 puis 404 sur ses propres articles. Le scénario de la plateforme comptait les
clients créés au navigateur : le chiffre d'affaires attendu à 49 dinars en trouvait 207.
Chacun refait maintenant **sa** base.

**106 au vert** : 97 sur la caisse, 9 sur la plateforme — deux exécutions de suite.

---

## Pour voir tourner, au réveil

```bash
# le back-office éditeur — c'est par là qu'on commence
cd Plateforme/plateforme && createdb plateforme && mvn spring-boot:run
#   http://localhost:8090 — admin / plateforme123
#   Clients → Nouveau client → Souscrire un module → Préparer la base du client
#   Il rend une commande de lancement : la coller dans un terminal, et la caisse est prête.

# ou directement une caisse, sans passer par le back-office
cd Plateforme/backend && createdb demo_cafe
LANG=C.UTF-8 POSCAISSE_DB_NAME=demo_cafe POSCAISSE_PROFIL=CAFE mvn spring-boot:run
#   PROFIL : RESTO | CAFE | SHOP | VETEMENT | PATISSERIE | PARFUMERIE
#   POSCAISSE_DEMO_DATA=false pour partir d'un catalogue vide
```

## Ce qui reste, et pourquoi

- **L'aiguillage multi-clients** dans la caisse. Aujourd'hui le provisionnement lance **un
  processus par client** — ce qui est exactement juste pour une installation chez le
  commerçant, et ce que l'architecture écarte pour l'offre hébergée (300 clients = 300
  processus). Le chantier : le jeton porte le client, un filtre le pose, la source de
  données aiguille — **avec le test qui interdit qu'une requête parte sans contexte**.
  C'est le prochain, et c'est celui qu'il ne faut pas bâcler.
- **Taille × couleur** pour le prêt-à-porter (un seul axe aujourd'hui) et les **pointures**.
  Un deuxième axe règle les deux d'un coup.
- **Les menus composés dans le format d'import** : c'est la seule raison pour laquelle la
  carte du profil Resto est écrite dans le code au lieu d'être un fichier comme les cinq
  autres.
- **L'interface du back-office éditeur** : un premier écran, pas le produit fini.
- **Les relances par courriel** avant suspension.
- **Une carte Resto neutre** : `number-one-2026.json` est la carte réelle d'un client, avec
  ses prix. Elle est volontairement **exclue du JAR** ; le profil Resto livre la
  démonstration générique « FAST FOOD DÉMO ».
