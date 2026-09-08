# Revue de sécurité — 08/09/2026

Revue du code de la caisse avant d'en faire une plateforme exposée sur internet. Cinq
défauts trouvés, **cinq corrigés cette nuit**, chacun avec le test qui empêche qu'il
revienne. Ce qui reste à faire est en bas, honnêtement listé.

Tout est dans `Plateforme/` : la verticale Resto livrée (`PosCaisse/`) n'a pas été touchée.

---

## 1. On pouvait essayer les dix mille PIN à la suite — **corrigé**

**Ce qui était possible.** Un PIN fait quatre chiffres. Rien ne comptait les échecs : un
programme les essaie tous en quelques secondes et entre dans la caisse. Sur un PC de
restaurant c'était déjà mauvais ; sur un serveur exposé, c'est la porte ouverte. Le mot de
passe du back-office n'était pas mieux protégé.

**Ce qui a été fait.** `AntiForceBrute` : après quatre échecs, l'attente double à chaque
essai (2 s, 4 s, 8 s… plafonnée à cinq minutes) et s'oublie au bout de trente minutes.

Deux compteurs séparés, et c'est le point important : **par adresse** *et* **par compte**.
Le premier arrête la machine qui essaie mille mots de passe depuis un poste ; le second
arrête l'attaque répartie sur mille adresses contre le compte « admin », que le premier ne
verrait jamais passer.

**On ne bloque jamais un compte** : un caissier verrouillé à 19 h, c'est un service perdu.
On ralentit celui qui cherche — un humain qui se trompe deux fois ne s'en aperçoit pas.

*Test : huit essais faux, les premiers refusés puis la porte se ferme ; et le bon PIN passe
depuis une autre adresse dans la seconde qui suit.*

## 2. Une clé de signature commune à toutes les installations — **corrigé**

**Ce qui était possible.** La clé qui signe les jetons était écrite dans le fichier de
configuration, avec une valeur par défaut. Qui l'a lue peut fabriquer un jeton valide —
pour n'importe quelle installation, avec n'importe quels droits, **sans jamais connaître un
seul mot de passe**.

**Ce qui a été fait.** Chaque installation tire sa clé au sort à la première connexion et la
garde dans une table `app_secret` que **aucun endpoint ne lit** (rangée dans les réglages,
elle serait ressortie par `GET /api/settings`). Une clé posée par l'exploitant l'emporte
toujours — c'est ce qu'on fera sur le serveur. Deux instances qui démarrent ensemble ne se
marchent pas dessus : c'est la base qui tranche, en une instruction.

Aucun réglage à penser à poser : un réglage de sécurité qu'il faut se rappeler d'activer
n'est pas activé.

## 3. Un caissier pouvait lire la caisse d'un autre — **corrigé**

**Ce qui était possible.** `GET /api/pos/session/{id}/summary`, `/report` et `/movements` ne
vérifiaient rien : un identifiant se devine en comptant, et n'importe quel caissier lisait
la recette d'un collègue — ou celle du patron.

**Ce qui a été fait.** On ne lit une session que si c'est la sienne, ou si l'on a le droit
« voir les recettes » (ou « voir les rapports »). *Test : deux caissiers, chacun chez soi ;
403 sur la caisse du voisin, 200 sur la sienne.*

## 4. La marge du patron partait dans chaque catalogue — **corrigé**

**Ce qui était possible.** L'écran de vente recevait **tous** les réglages, taux de marge
compris. N'importe quel caissier lisait le taux du patron dans la réponse du catalogue,
sans même avoir à chercher. Et l'écran de clôture affichait le bénéfice estimé à qui
fermait la caisse.

**Ce qui a été fait.** Le catalogue n'envoie plus qu'une liste **nommée** de réglages — ceux
dont l'écran se sert. Un réglage nouveau n'arrive en caisse que si quelqu'un décide qu'il
doit y arriver. Et le bénéfice n'est calculé que pour qui a le droit « voir les recettes ».

*C'est un changement de comportement assumé :* pour qu'un caissier voie de nouveau le
bénéfice, il suffit d'ajouter ce droit à son rôle. C'est une décision du patron, pas du
logiciel.

## 5. Deux durcissements — **corrigés**

- **CORS** : une origine « `*` » avec identifiants autorisait n'importe quelle page piégée à
  agir au nom du caissier connecté. C'est désormais refusé au démarrage, avec un message
  qui nomme le réglage fautif.
- **Empreintes de mots de passe** : coût BCrypt porté de 8 à 10 (la référence). Un mot de
  passe volé se casse quatre fois moins vite ; les empreintes existantes restent valides,
  chacune porte son propre coût.

---

## Ce qui reste à faire avant d'ouvrir sur internet

Par ordre d'importance. Aucun de ces points n'est un défaut du code d'aujourd'hui : ce sont
les conditions d'un service hébergé.

1. **HTTPS obligatoire, sans exception.** Un jeton qui voyage en clair se vole en Wi-Fi
   partagé. Redirection HTTP → HTTPS, HSTS, cookies `Secure`.
2. **Le secret de signature vient de l'environnement**, pas de la base, dès qu'il y a
   plusieurs instances derrière un répartiteur.
3. **Ralentisseur aussi au niveau du proxy** : le nôtre est en mémoire, donc par instance.
   Un pare-feu applicatif complète, il ne remplace pas.
4. **Durée de vie des jetons** : 12 h aujourd'hui, ce qui convient à une caisse ouverte du
   matin au soir. Pour le back-office éditeur, il faudra plus court, avec renouvellement.
5. **Deuxième facteur pour le back-office éditeur** — celui qui voit tous les clients.
6. **Cloisonnement des bases** : une base par client (décidé), donc un utilisateur PostgreSQL
   par base, et jamais un compte unique qui les voit toutes.
7. **Journal d'accès conservé** : qui a lu quoi, pas seulement qui a écrit.
8. **Sauvegardes chiffrées et testées** : une sauvegarde qu'on n'a jamais restaurée n'est
   pas une sauvegarde.
9. **En-têtes de sécurité** sur l'application web (CSP, `X-Frame-Options`) : la caisse ne
   doit pas pouvoir être affichée dans un cadre sur un autre site.
10. **Revue des dépendances** à chaque version, et mise à jour de celles qui portent un
    avis de sécurité.
