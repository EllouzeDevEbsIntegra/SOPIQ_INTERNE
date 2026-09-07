# Déploiement de site-v2 sur le VPS OVH (135.125.100.21)

Le VPS héberge déjà plusieurs projets en production, chacun sur son port.
Règle : **rien n'est déployé avant l'audit** et le choix d'un port libre + d'un
nom de domaine/sous-domaine dédié.

## Étape 1 – Audit (lecture seule)

Depuis votre session SSH (`ssh ubuntu@135.125.100.21`) :

```bash
# copier le script (depuis votre PC, dans un autre terminal)
scp deploy/site-v2/audit-vps.sh ubuntu@135.125.100.21:~/

# sur le VPS
bash ~/audit-vps.sh > ~/audit-vps.txt 2>&1
cat ~/audit-vps.txt
```

Le script ne modifie rien : il liste les ports écoutés, les vhosts
nginx/apache, les process pm2/docker/systemd, les certificats, le pare-feu,
les runtimes installés et les répertoires de projets existants.

## Étape 2 – Informations à fournir pour préparer le déploiement

1. Le contenu de `audit-vps.txt`.
2. La stack de `site-v2` (contenu de `D:\SOPIQ_INTERNE_POS\PosCaisse\site-v2`) :
   `package.json` s'il existe, framework (Next.js, Vite/React, Angular,
   site statique HTML, PHP, .NET ...), commande de build, variables `.env`
   nécessaires (sans les valeurs secrètes).
3. Le nom de domaine ou sous-domaine prévu pour site-v2 (ou « IP + port »
   si aucun domaine pour l'instant).

## Étape 3 – Déploiement (à générer après l'audit)

Sera produit dans ce dossier une fois les éléments ci-dessus connus :
- `deploy.sh` : build + copie vers `/var/www/site-v2` (ou pm2/docker selon la stack)
- `nginx-site-v2.conf` : vhost sur un port libre vérifié à l'étape 1
- procédure de rollback
