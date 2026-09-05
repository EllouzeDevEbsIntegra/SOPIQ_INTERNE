# PosCaisse — Guide d'installation et de mise en service

**Destinataire : le technicien qui se déplace chez le client.**
Ce document se suit dans l'ordre, de haut en bas. Comptez **45 minutes** sur place.

Le PC du client n'a besoin ni d'internet, ni de Java, ni de PostgreSQL, ni de droits
administrateur. Rien n'est installé dans Windows : aucun service, aucune clé de registre.
Copier le dossier déplace l'installation, le supprimer la désinstalle.

---

## 0. Avant de partir — à vérifier sur la clé USB

Trois éléments, et rien d'autre :

| Fichier | Taille approximative | À quoi il sert |
|---|---|---|
| `PosCaisse-<date>.zip` | ~443 Mo | l'application complète, vierge |
| `poscaisse-<date>-sans-ventes.dump` | ~6 Mo | la carte, l'entreprise, les utilisateurs, les réglages |
| ce guide | — | |

**Le ZIP doit être le paquet d'origine**, jamais un dossier déjà installé qu'on aurait
recompressé. Un dossier installé contient une base de données vivante : recompressé, il
arrive corrompu, et `INSTALLER.bat` refuse de s'exécuter sur un dossier qui contient déjà
`donnees\`.

**À se faire communiquer avant de partir**, jamais écrit dans ce document :

- l'identifiant et le mot de passe administrateur de la caisse ;
- le nom et le modèle de l'imprimante à tickets du client.

---

## 1. Reconnaître le poste

Avant de copier quoi que ce soit :

- **Windows 64 bits.** Le paquet ne fonctionne pas sur un Windows 32 bits.
- **8 Go d'espace libre** au minimum sur le disque cible.
- **Ne pas ouvrir de session administrateur, et ne jamais lancer `INSTALLER.bat` par
  « Exécuter en tant qu'administrateur ».** PostgreSQL refuse de fonctionner avec ces
  droits : c'est une protection du moteur, pas un réglage à contourner. Une fenêtre
  élevée se reconnaît à son titre, qui commence par `Administrateur :`.
- **Prévoyez malgré tout un compte administrateur sous la main.** Un seul geste en a
  besoin — voir l'encadré ci-dessous — et il vaut mieux ne pas le découvrir sur place.
- **Un antivirus agressif** peut retenir les fichiers pendant l'installation. Si l'étape 3
  échoue sans raison apparente, mettez la protection en pause le temps de l'installation.

---

### Les deux besoins sont opposés

C'est le piège de cette installation, et il vaut d'être compris avant de partir :

| Ce qu'on fait | Droits nécessaires |
|---|---|
| Installer la bibliothèque Microsoft VC++ (`outils\vc_redist.x64.exe`) | **administrateur** — c'est un composant de Windows |
| Tout le reste : `INSTALLER.bat`, la caisse, la base | **surtout pas administrateur** |

Sur un PC qui n'a jamais eu de PostgreSQL, la bibliothèque manque souvent.
`INSTALLER.bat` le détecte et propose de l'installer : acceptez, et **fournissez le compte
administrateur** à la fenêtre d'autorisation qui s'ouvre. Elle n'élève que ce composant —
la caisse, elle, reste sans privilèges.

Si l'autorisation est refusée ou que le compte n'en dispose pas, le programme vous le dit
et vous donne la marche à suivre en deux temps : installer `outils\vc_redist.x64.exe` par
clic droit → *Exécuter en tant qu'administrateur*, puis revenir lancer `INSTALLER.bat`
par un simple double-clic.

---

## 2. Copier et décompresser

Décompressez le ZIP dans un chemin **court et local** :

```
C:\PosCaisse
```

À éviter absolument : le Bureau, *Mes documents*, un dossier OneDrive. Chemins trop longs
et synchronisation cloud, qui corrompt une base de données à coup sûr.

Vérifiez qu'après extraction vous avez bien `C:\PosCaisse\INSTALLER.bat`, et non
`C:\PosCaisse\PosCaisse-<date>\INSTALLER.bat`. Si c'est le second cas, remontez le contenu
d'un niveau.

Copiez aussi le fichier `.dump` dans `C:\PosCaisse\` — vous aurez un chemin court à taper
à l'étape 4.

---

## 3. Installer

Double-clic sur **`INSTALLER.bat`**. Comptez 2 à 3 minutes.

Il doit se terminer par :

```
== Installation terminee
  Ouvrez la caisse avec DEMARRER.bat. Identifiants de depart : admin / admin123.
  Changez ce mot de passe des la premiere connexion (Back-office -> Utilisateurs).
```

Le navigateur s'ouvre alors tout seul sur la caisse : c'est prévu, l'installateur la
démarre pour vous. Vous pouvez le laisser ouvert, `RESTAURER.bat` fermera ce qu'il faut.

L'installation crée un serveur PostgreSQL privé dans le dossier, avec un mot de passe tiré
au hasard, à l'écoute de `127.0.0.1` seulement, sur le port 5433 pour cohabiter avec un
PostgreSQL déjà présent sur le PC.

À ce stade la caisse contient un jeu de **démonstration** — enseigne fictive, articles
d'exemple. C'est normal. On le remplace à l'étape suivante.

> **Si l'installation échoue**, voir le tableau des pannes en fin de guide. Ne relancez pas
> `INSTALLER.bat` en boucle : il refusera de repartir tant que `donnees\` existe.

---

## 4. Installer les données du client

Double-clic sur **`RESTAURER.bat`**. Quand il demande le chemin, tapez le nom du fichier
`.dump` que vous avez copié à l'étape 2.

**Le programme vous montre ce que contient le fichier AVANT de toucher à quoi que ce soit :**

```
  Ce que contient ce fichier :
    Enseigne   : Number One
    Articles   : 55
    Categories : 5
    Tickets    : 0

  Le poste contient aujourd'hui : FAST FOOD DEMO, 39 articles, 0 tickets
  Tout cela sera REMPLACE par le contenu ci-dessus.
  Tapez OUI pour remplacer:
```

### C'est le point de contrôle du déplacement

- L'enseigne affichée est bien celle du client → tapez `OUI`.
- Vous lisez `FAST FOOD DEMO` dans le **contenu du fichier** → tapez n'importe quoi
  d'autre. Vous n'avez pas le bon fichier. Rien n'aura été modifié.

Ne tapez jamais `OUI` sans avoir lu ces quatre lignes.

---

## 5. Vérifier de vos yeux

Double-clic sur **`DEMARRER.bat`**, puis connectez-vous.

Quatre contrôles, dans cet ordre :

1. **L'écran de caisse** — les catégories et les articles du client, à ses prix.
2. **Un ticket d'essai** — ajoutez un article, encaissez en espèces. Sur l'aperçu :
   l'enseigne du client, le logo à gauche, la date et l'heure à droite.
3. **Le numéro de ticket** — il doit être **1**. Le client démarre avec un journal vierge.
4. **Paramètres → Entreprise** — adresse et téléphone, ceux qui s'impriment en pied de
   ticket.

Si l'un des quatre ne va pas, arrêtez-vous là et signalez-le. Ne poursuivez pas la mise en
service sur une installation douteuse.

---

## 6. Sécuriser l'accès

**Changez le mot de passe administrateur avec le client**, à son clavier, sans le noter.

Si le compte livré est encore `admin` / `admin123`, c'est un compte connu de tous : il ne
doit pas survivre à votre visite.

---

## 7. L'imprimante à tickets

1. Dans Windows, **l'imprimante à tickets doit être l'imprimante par défaut**. La caisse
   imprime sur celle-là, sans poser de question.
2. Imprimez un ticket d'essai depuis la caisse et vérifiez le rendu papier : largeur,
   logo, lisibilité du numéro de ticket.
3. Si une boîte de dialogue d'impression s'ouvre au lieu d'imprimer directement, c'est que
   ni Chrome ni Edge n'est installé sur le poste. L'impression directe demande l'un des
   deux.

---

## 8. Démarrage automatique

Pour que la caisse s'ouvre toute seule quand le PC s'allume :

1. `Windows + R`, tapez `shell:startup`, Entrée.
2. Faites un raccourci vers **`C:\PosCaisse\DEMARRER-AUTO.vbs`**.

**Ce fichier-là, pas `DEMARRER.bat`.** Windows ouvre toujours une fenêtre noire pour un
`.bat` ; le `.vbs` démarre la caisse sans rien afficher, et prévient par un message si le
démarrage échoue.

---

## 9. Choisir l'affichage

Ouvrez `C:\PosCaisse\config\poscaisse.conf` avec le Bloc-notes. La ligne `AFFICHAGE`
commande la façon dont la caisse s'ouvre :

| Valeur | Effet | Quand la choisir |
|---|---|---|
| `plein-ecran` *(défaut)* | comme la touche F11 ; F11 rend la main | cas général |
| `kiosque` | plein écran verrouillé : ni F11, ni onglets, ni barre d'adresse. Sortie par Alt+F4 | poste où le personnel ne doit rien faire d'autre |
| `fenetre` | fenêtre ordinaire | poste partagé avec d'autres usages |

**Attention au mode `kiosque` :** sans barre d'outils, le navigateur n'affiche plus ce
qu'il télécharge. Un relevé de compte en PDF arrive bien dans le dossier Téléchargements,
mais rien ne le signale à l'écran. Sur un poste où le client consulte les relevés clients
et livreurs, restez en `plein-ecran`.

Les modifications s'appliquent au redémarrage de la caisse.

---

## 10. La sauvegarde — ne pas sauter cette étape

C'est l'étape qu'on oublie parce que tout marche. C'est aussi celle qui décide de ce qui
se passera le jour d'une panne de disque.

1. Double-clic sur **`SAUVEGARDER.bat`**. Il écrit un fichier dans
   `C:\PosCaisse\sauvegardes\`.
2. **Copiez ce fichier sur une clé USB, devant le client.** Les sauvegardes s'écrivent sur
   le même disque que la caisse : elles protègent d'une fausse manœuvre, **pas** d'une
   panne de ce disque ni d'un vol du PC.
3. Montrez au client comment refaire ces deux gestes, et à quelle fréquence : une fois par
   semaine au minimum, tous les soirs si le restaurant tourne fort.

---

## 11. Ce qu'il faut expliquer au client avant de partir

Trois gestes, pas plus. S'il n'en retient qu'un, que ce soit le premier.

| Geste | Pourquoi |
|---|---|
| **`ARRETER.bat` avant d'éteindre le PC** | couper le courant sur une base ouverte est le seul vrai moyen d'abîmer les données |
| **`SAUVEGARDER.bat` puis copie sur clé USB** | une sauvegarde restée sur le PC ne protège pas d'une panne du PC |
| **`ETAT.bat` quand quelque chose semble bloqué** | il dit en trois lignes ce qui tourne et quand remonte la dernière sauvegarde — c'est la première chose à demander au téléphone |

Laissez le fichier `LISEZ-MOI.txt` du dossier bien visible : il reprend tout cela.

---

## Fiche de mise en service

À remplir et à conserver.

```
Client : ......................................  Date : ........../........../..........
Technicien : ..................................

[ ]  Dossier installe dans : C:\...........................
[ ]  INSTALLER.bat termine sans erreur
[ ]  RESTAURER.bat : enseigne lue a l'ecran = ...........................
                     articles = ........   categories = ........
[ ]  Ticket d'essai imprime, numero 1, rendu papier conforme
[ ]  Mot de passe administrateur change par le client
[ ]  Imprimante a tickets definie par defaut dans Windows
[ ]  Demarrage automatique en place (DEMARRER-AUTO.vbs)
[ ]  AFFICHAGE choisi : ........................
[ ]  Premiere sauvegarde faite ET copiee sur cle USB
[ ]  Les trois gestes expliques au client

Observations : ...........................................................
..........................................................................
```

---

## En cas de panne

| Ce qui s'affiche | Cause | Ce qu'il faut faire |
|---|---|---|
| `Droits d'administration : installation impossible` | la fenêtre a été ouverte élevée (titre `Administrateur :`) | fermez-la, simple double-clic sur `INSTALLER.bat`. Si le titre revient, UAC est désactivé : créez un compte Windows standard pour la caisse et installez depuis là |
| `Les programmes PostgreSQL ne demarrent pas` + `code de retour : -1073741515` | bibliothèque Microsoft VC++ manquante — Windows n'a pas pu charger le programme, donc aucun message ne s'affiche | acceptez l'installation proposée, et fournissez le compte administrateur à la fenêtre d'autorisation |
| `Ce composant n'a PAS ete installe` *(code 5, 1223 ou 1602)* | l'autorisation administrateur a été refusée, ou le compte n'en dispose pas | installez `outils\vc_redist.x64.exe` par clic droit → *Exécuter en tant qu'administrateur*, puis relancez `INSTALLER.bat` **sans** élévation |
| `Le port 5433 est deja pris` | un autre PostgreSQL occupe le port | ouvrez `config\poscaisse.conf`, mettez `PG_PORT=5434`, relancez |
| `Le port 8080 est deja pris` | un autre programme occupe le port | ouvrez `config\poscaisse.conf`, mettez `APP_PORT=8081`, relancez |
| `version non supportee` à la restauration | le `.dump` vient d'un PostgreSQL plus récent que ce paquet | **ne touchez à rien sur place.** Le poste est intact. Signalez-le : c'est le paquet qu'il faut refabriquer |
| `Une base existe deja dans ce dossier : installation deja faite` | `INSTALLER.bat` relancé sur un dossier déjà installé | c'est une protection, pas une panne. Si vous voulez repartir de zéro : sauvegardez, renommez `donnees\`, relancez |
| La caisse ne répond pas | — | `ETAT.bat` d'abord, puis `journaux\poscaisse-erreurs.log` |

**Trois choses à ne jamais faire :**

1. **Ne supprimez jamais le dossier `donnees\`** — ce sont les ventes du client.
2. **Ne recompressez jamais un dossier installé** pour le porter ailleurs. Utilisez
   `SAUVEGARDER.bat`, qui produit un fichier fait pour ça.
3. **N'éteignez jamais le PC sans `ARRETER.bat`** pendant que vous travaillez dessus.

---

## Mettre à jour la caisse, plus tard

Une mise à jour ne remplace que le fichier `poscaisse.jar` :

1. `ARRETER.bat`
2. `SAUVEGARDER.bat`, et copie du fichier sur clé USB
3. remplacer `poscaisse.jar` par le nouveau
4. `DEMARRER.bat`

Les données vivent à part, dans `donnees\` : elles ne sont jamais touchées par une mise à
jour.
