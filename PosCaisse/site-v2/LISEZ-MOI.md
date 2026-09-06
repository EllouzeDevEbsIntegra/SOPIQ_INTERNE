# NUMBER ONE — site vitrine v2

Ouvrez **index.html** par double-clic. Tout fonctionne localement : carte, recherche,
catégories, photos et polices. Internet est nécessaire uniquement pour Google Maps ;
les liens d’appel utilisent l’application téléphone de l’appareil.

Pour un hébergement statique, copiez `index.html`, `style.css`, `app.js`, `img/` et
`fonts/` dans le même dossier. Aucun serveur applicatif ni installation n’est requis.

## La carte et les prix

`carte.json` est la copie intégrale du fichier fourni dans la demande, récupérée le
6 septembre 2026 depuis la branche `claude/poscaisse-full-app-omsdd4` du dépôt
[SOPIQ_INTERNE](https://github.com/EllouzeDevEbsIntegra/SOPIQ_INTERNE/blob/claude/poscaisse-full-app-omsdd4/PosCaisse/site/carte.json).
La version locale de `site/` ne contenait plus ce fichier ; son autre catalogue n’a
pas été substitué à la source demandée.

- 111 articles, 8 catégories, tous les noms conservés à l’identique.
- 86 articles avec leurs trois prix complets, affichés ensemble.
- Suppléments double pâte repris du JSON dans une section dédiée, accessible depuis
  la navigation et la barre de recherche sur ordinateur.
- Prix en DT, avec virgule et trois décimales.
- Recherche insensible aux accents et à la casse, sur toute la carte, y compris
  lorsqu’une catégorie était sélectionnée.
- Appel permanent sur mobile, adresse et lien Google Maps.
- Sans JavaScript, la carte complète et les liens restent accessibles.

Pour changer la carte, remplacez ou modifiez **ce dossier-ci** : `site-v2/carte.json`,
ajoutez les photos référencées dans `site-v2/img/`, puis lancez depuis `site-v2/` :

```powershell
node outils/generer.mjs
```

Le générateur relit toujours ce JSON. Il produit `index.html`, qui contient la carte
complète : le navigateur n’effectue aucun `fetch` de fichier local. Aucun prix n’est
saisi dans le modèle HTML, la feuille de style ou le code de recherche. La génération
échoue si un prix de pâte ou une photo manque. Node.js est nécessaire seulement pour
régénérer la page, jamais pour la consulter.

## Vérifications

```powershell
python outils/verifier.py
```

Python 3 et Node.js suffisent, sans module supplémentaire. Les contrôles comparent
chaque nom, image et montant au JSON, vérifient les ancres et les liens de contact,
contrôlent les ressources locales et les recherches. Un catalogue temporaire modifié
vérifie que la génération reflète effectivement les changements de prix et de noms.

Le modèle est dans `outils/modele.html`, la présentation dans `style.css`, et la
recherche dans `app.js`. Ces outils n’écrivent jamais dans le dossier `site/` d’origine.

## Images et polices

Les 111 JPEG proviennent exclusivement du dossier `PosCaisse/site/img/` de la branche
indiquée. Les fichiers sont conservés sans retouche. Le logo noir et blanc de 131 ×
131 pixels est celui du dépôt, récupéré à l’identique dans
`bf43f23:PosCaisse/site/img/logo-number-one.png` ; le lien `img/` à la racine du dépôt
fourni dans la demande renvoyait une erreur 404.

Les polices Barlow Condensed et DM Sans sont embarquées dans `fonts/`, avec leurs
licences SIL Open Font License. Elles proviennent du dépôt officiel Google Fonts.

## Informations non fournies

Les horaires, les réseaux sociaux, les avis clients et les promotions sont absents.
Aucune information correspondante n’a été inventée.
