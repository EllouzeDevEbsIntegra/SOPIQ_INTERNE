#!/usr/bin/env bash
# =============================================================================
# Audit LECTURE SEULE du VPS OVH avant déploiement de site-v2.
# Ne modifie rien : inventorie les projets, ports, reverse-proxies, services.
#
# Usage (depuis votre session SSH sur le VPS) :
#   bash audit-vps.sh > audit-vps.txt 2>&1 ; cat audit-vps.txt
# Puis collez le contenu de audit-vps.txt dans la conversation.
# =============================================================================
set -u
sec() { printf '\n\n######## %s ########\n' "$1"; }
run() { printf '\n$ %s\n' "$*"; "$@" 2>&1 || true; }
has() { command -v "$1" >/dev/null 2>&1; }

sec "SYSTEME"
run hostname
run cat /etc/os-release
run uname -r
run uptime
run nproc
run free -h
run df -h
run id

sec "PORTS EN ECOUTE (processus -> port)"
if has ss; then run sudo ss -tulpn; else run sudo netstat -tulpn; fi

sec "PROCESSUS SERVEURS (node, python, java, dotnet, php, nginx, apache...)"
run bash -c "ps -eo user,pid,etime,%cpu,%mem,cmd --sort=-%mem | grep -Ei 'node|python|gunicorn|uvicorn|java|dotnet|php|nginx|apache|httpd|caddy|traefik|pm2|next|vite|serve' | grep -v grep"

sec "REVERSE PROXY : NGINX"
if has nginx; then
  run nginx -v
  run sudo nginx -T
  run ls -la /etc/nginx/sites-enabled /etc/nginx/sites-available /etc/nginx/conf.d
else echo "nginx absent"; fi

sec "REVERSE PROXY : APACHE"
if has apache2ctl; then
  run apache2ctl -S
  run ls -la /etc/apache2/sites-enabled
else echo "apache absent"; fi

sec "REVERSE PROXY : CADDY / TRAEFIK"
if has caddy; then run caddy version; run cat /etc/caddy/Caddyfile; else echo "caddy absent"; fi
run ls -la /etc/traefik 2>/dev/null

sec "PM2"
if has pm2; then run pm2 -v; run pm2 ls; run pm2 jlist; run pm2 startup; else echo "pm2 absent (user courant)"; fi
run bash -c "for u in \$(cut -d: -f1 /etc/passwd); do [ -d /home/\$u/.pm2 ] && echo \"pm2 dir trouvé pour \$u\"; done"

sec "DOCKER"
if has docker; then
  run docker --version
  run sudo docker ps -a --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}'
  run sudo docker network ls
  run bash -c "sudo find / -maxdepth 4 -name 'docker-compose*.y*ml' -o -maxdepth 4 -name 'compose*.y*ml' 2>/dev/null | grep -v /snap/"
else echo "docker absent"; fi

sec "SERVICES SYSTEMD (custom, hors système)"
run bash -c "systemctl list-units --type=service --state=running --no-pager --no-legend"
run bash -c "ls -la /etc/systemd/system/*.service 2>/dev/null"

sec "CERTIFICATS TLS (certbot / letsencrypt)"
if has certbot; then run sudo certbot certificates; else echo "certbot absent"; fi
run sudo ls -la /etc/letsencrypt/live 2>/dev/null

sec "PARE-FEU"
if has ufw; then run sudo ufw status verbose; fi
run sudo iptables -L -n --line-numbers

sec "REPERTOIRES DE PROJETS"
run bash -c "ls -la /var/www /srv /opt /home/*/ 2>/dev/null"
run bash -c "sudo find /var/www /srv /opt /home -maxdepth 3 \( -name package.json -o -name requirements.txt -o -name '*.csproj' -o -name composer.json -o -name Dockerfile -o -name .env \) 2>/dev/null | grep -v node_modules"

sec "RUNTIMES DISPONIBLES"
for c in node npm pnpm yarn nvm python3 pip3 php dotnet java git; do
  if has "$c"; then printf '%-8s %s\n' "$c" "$("$c" --version 2>&1 | head -1)"; else printf '%-8s absent\n' "$c"; fi
done
run bash -c "ls -la /home/*/.nvm/versions/node 2>/dev/null"

sec "BASES DE DONNEES"
run bash -c "systemctl is-active postgresql mysql mariadb mongod redis-server 2>/dev/null | paste - - - - - "
run bash -c "sudo ss -tlnp | grep -E ':(5432|3306|27017|6379)\b'"

sec "DNS / DOMAINES REFERENCES DANS LES CONFIGS"
run bash -c "sudo grep -rhoE 'server_name[^;]+;' /etc/nginx 2>/dev/null | sort -u"
run bash -c "sudo grep -rhoE 'ServerName[^\n]+' /etc/apache2 2>/dev/null | sort -u"
run bash -c "curl -s -m 5 ifconfig.me; echo"

sec "CRON"
run bash -c "sudo ls -la /etc/cron.d; for u in \$(cut -d: -f1 /etc/passwd); do sudo crontab -l -u \$u 2>/dev/null | sed \"s/^/[\$u] /\"; done"

sec "FIN DE L'AUDIT"
