# Site vitrine — NUMBER ONE (Chihia, Sfax)

Ce dossier contient le **site vitrine** du fast-food NUMBER ONE : une seule page
qui présente la carte et, surtout, le numéro de téléphone pour commander.
Il est totalement indépendant du logiciel de caisse : il ne fait que **lire** le
catalogue de la caisse pour en tirer les prix.

## Contenu du dossier

| Fichier | Rôle |
| --- | --- |
| `index.html` | La page complète (CSS et JavaScript inclus dedans, aucun fichier à côté). |
| `img/logo-number-one.png` | **À fournir** — voir `img/LISEZ-MOI.txt`. |
| `outils/generer-menu.py` | Régénère la carte de la page depuis le catalogue de la caisse. |

## Ouvrir la page

Double-cliquez sur `index.html` : elle s'ouvre dans le navigateur, sans
installation ni serveur. Pour la tester comme sur un téléphone, ouvrez-la sur
Chrome puis « Outils de développement » → mode mobile (360 px de large).

Pour la mettre en ligne, il suffit de déposer le dossier `site/` entier
(la page **et** le dossier `img/`) chez n'importe quel hébergeur de pages
statiques. Aucune base de données, aucun PHP.

## Ce qu'il reste à fournir par le client

La page ne contient **que des informations vérifiées**. Rien n'a été inventé :
ni horaires, ni avis, ni photos, ni livraison. Il manque :

1. **Le logo** — déposer `logo-number-one.png` dans `img/` (détails dans
   `img/LISEZ-MOI.txt`). Sans lui la page reste correcte, mais moins jolie.
2. **Les horaires d'ouverture** — l'emplacement est déjà prévu dans
   `index.html`, dans l'encadré « Commander » de la section « Nous trouver » :
   cherchez le commentaire `EMPLACEMENT À COMPLÉTER : horaires`, et remplacez-le
   par la ligne d'exemple qui s'y trouve.
3. **Réseaux sociaux et e-mail** (Facebook, Instagram…) — même principe, dans
   l'encadré « Adresse » : commentaire `EMPLACEMENT À COMPLÉTER : réseaux`.
4. **Photos des sandwichs** — aucune n'est présente. Si le client en fournit,
   les placer dans `img/` et les insérer dans les sections concernées.
5. **Le nom de domaine** — une fois connu, remplacer dans l'en-tête de
   `index.html` la valeur de `og:image` (`img/logo-number-one.png`) par
   l'adresse complète (`https://…/img/logo-number-one.png`), sinon l'aperçu de
   partage sur Facebook / WhatsApp restera vide.
6. **Confirmation des prix manquants** — 7 articles n'ont pas encore de tarif
   dans le catalogue et sont donc **absents de la page** (voir plus bas).

## Régénérer le menu quand la carte change

La carte affichée est produite automatiquement à partir de
`../catalogs/number-one-2026.json` (le catalogue chargé dans la caisse).
**Ne modifiez pas les prix à la main dans `index.html`** : la prochaine
régénération les écraserait. Modifiez le catalogue, puis lancez, depuis la
racine du projet :

```bash
python3 site/outils/generer-menu.py
```

Le script réécrit les deux blocs balisés dans `index.html` — le sommaire des
catégories (`<!-- NAV:DEBUT -->` … `<!-- NAV:FIN -->`) et la carte
(`<!-- MENU:DEBUT -->` … `<!-- MENU:FIN -->`) — et affiche un compte rendu :
nombre d'articles publiés et liste des articles écartés. Tout le reste de la
page (design, textes, contact) est intact : vous pouvez l'éditer librement,
il suffit de conserver les quatre lignes de marqueurs.

Pour travailler sur un autre fichier de carte :

```bash
python3 site/outils/generer-menu.py --catalogue catalogs/ma-carte.json
```

### Règles que le script applique tout seul

- **Prix à 0 = article non publié.** Un tarif à 0 dans le catalogue signifie
  « pas encore fixé » : l'article n'apparaît pas sur le site. Dès qu'un prix est
  saisi dans le catalogue, l'article apparaît à la régénération suivante.
- **Prix affiché = pâte Normale.** Le supplément des autres pâtes
  (Céréale +1,000 DT, Chia +1,500 DT) est expliqué **une seule fois**, dans
  l'encadré « Les pâtes » en haut de la carte, et non sur chaque ligne.
- **Format des prix :** dinars, trois décimales, virgule (`6,500 DT`).
- **Les noms ne sont jamais corrigés** (« Omlette », « Mozarilla », « Kabeb »,
  « Jombon » sont écrits comme le client les écrit).
- Une catégorie dont tous les articles sont écartés disparaît du sommaire.
  C'est le cas aujourd'hui de **Boissons**, dont les deux articles sont à 0.

## Articles actuellement absents du site (prix à 0 dans le catalogue)

| Code | Article | Catégorie |
| --- | --- | --- |
| BOI-01 | Coca | Boissons |
| BOI-02 | Eau 0,5 L | Boissons |
| COT-02 | Grillade | À côté |
| COT-03 | Nuggets x6 | À côté |
| EX-14 | Extra Fromage Slice | Extras |
| EX-16 | Extra Grillade | Extras |
| EX-17 | Extra Nuggets x6 | Extras |

## Point à faire confirmer par le client

La catégorie **Extras** contient « Extra Pâte Céréale 2,000 DT » et
« Extra Pâte Chia 2,500 DT », alors que l'encadré « Les pâtes » annonce
+1,000 DT et +1,500 DT pour le choix de pâte d'un sandwich. Les deux
informations viennent du catalogue et ne désignent probablement pas la même
chose (choisir sa pâte ≠ commander une pâte en plus), mais mieux vaut le faire
confirmer pour éviter une question au téléphone.

## Notes techniques

- Aucune dépendance : pas de framework, pas de bundler, pas de build.
  La seule ressource externe est **Google Fonts** (polices Anton et Inter) ;
  sans connexion, la page bascule automatiquement sur des polices système.
- Mobile d'abord, lisible dès 360 px de large. Une barre d'appel fixe reste
  visible en bas de l'écran sur téléphone.
- Le téléphone est cliquable partout : `tel:+21626473741`.
- La recherche d'article fonctionne avec JavaScript ; sans JavaScript, la
  carte complète reste lisible et le champ de recherche est simplement masqué.
- Accessibilité : un seul `<h1>`, contrastes élevés, lien d'évitement,
  animations désactivées si le visiteur a demandé « réduire les animations ».
