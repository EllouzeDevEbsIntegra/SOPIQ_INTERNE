<#
    PosCaisse - poste autonome, sans internet.

    Tout ce dont l'application a besoin vit dans ce dossier : le moteur Java, le serveur
    PostgreSQL, l'application elle-meme et ses donnees. Rien n'est installe dans Windows,
    rien n'est telecharge, aucun service n'est enregistre. Copier le dossier suffit a
    deplacer l'installation ; le supprimer suffit a la desinstaller.

    Actions : install | start | stop | backup | restore | status
#>
param(
  [ValidateSet('install', 'start', 'stop', 'backup', 'restore', 'status')]
  [string]$Action = 'start',
  [string]$Fichier = ''
)

$ErrorActionPreference = 'Stop'
$racine  = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$jre     = Join-Path $racine 'jre'
$pg      = Join-Path $racine 'pgsql'
$donnees = Join-Path $racine 'donnees'
$journal = Join-Path $racine 'journaux'
$config  = Join-Path $racine 'config\poscaisse.conf'
$sauve   = Join-Path $racine 'sauvegardes'

$java   = Join-Path $jre 'bin\java.exe'
$initdb = Join-Path $pg  'bin\initdb.exe'
$pgctl  = Join-Path $pg  'bin\pg_ctl.exe'
$psql   = Join-Path $pg  'bin\psql.exe'
$pgdump = Join-Path $pg  'bin\pg_dump.exe'
$restore= Join-Path $pg  'bin\pg_restore.exe'
$jar    = Join-Path $racine 'poscaisse.jar'

New-Item -ItemType Directory -Force -Path $journal, $sauve, (Split-Path $config) | Out-Null

function Info($m)   { Write-Host "  $m" }
function Etape($m)  { Write-Host ''; Write-Host "== $m" -ForegroundColor Cyan }
function Souci($m)  { Write-Host "  $m" -ForegroundColor Yellow }
function Stop-Net($m) { Write-Host ''; Write-Host "ARRET : $m" -ForegroundColor Red; exit 1 }

# ---------------------------------------------------------------- configuration
function Lire-Config {
  $c = @{ PG_PORT = '5433'; APP_PORT = '8080'; DB = 'poscaisse'; USER = 'poscaisse'; PASS = ''; KIOSQUE = '1' }
  if (Test-Path $config) {
    foreach ($l in Get-Content $config) {
      if ($l -match '^\s*([A-Z_]+)\s*=\s*(.*?)\s*$') { $c[$Matches[1]] = $Matches[2] }
    }
  }
  return $c
}
function Ecrire-Config($c) {
  $lignes = @('# Reglages du poste PosCaisse. Modifiable avec le Bloc-notes, application au redemarrage.')
  foreach ($k in @('PG_PORT', 'APP_PORT', 'DB', 'USER', 'PASS', 'KIOSQUE')) { $lignes += "$k=$($c[$k])" }
  Set-Content -Path $config -Value $lignes -Encoding UTF8
}
function Mot-De-Passe {
  # Le compte de la base n'est jamais tape par un humain : un secret long vaut mieux
  # qu'un mot de passe memorisable, et il ne sort pas de ce dossier.
  $o = New-Object byte[] 24
  [System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($o)
  return ([Convert]::ToBase64String($o) -replace '[^A-Za-z0-9]', '').Substring(0, 24)
}

# ---------------------------------------------------------------- PostgreSQL
function Pg-Tourne($c) {
  if (-not (Test-Path $donnees)) { return $false }
  & $pgctl -D $donnees status *> $null
  return ($LASTEXITCODE -eq 0)
}
function Pg-Demarre($c) {
  if (Pg-Tourne $c) { return }
  $opts = "-p $($c.PG_PORT) -c listen_addresses=127.0.0.1"
  $log = Join-Path $journal 'postgres.log'
  & $pgctl -D $donnees -l $log -o $opts -w -t 60 start
  if ($LASTEXITCODE -ne 0) {
    # Le cas de loin le plus frequent sur un poste deja equipe : un autre PostgreSQL
    # occupe le port. Le dire, plutot que de renvoyer l'utilisateur a un journal.
    if ((Test-Path $log) -and ((Get-Content $log -Tail 20) -match 'Address already in use')) {
      Souci "Le port $($c.PG_PORT) est deja pris par un autre programme."
      Souci "Ouvrez config\poscaisse.conf, remplacez PG_PORT=$($c.PG_PORT) par une autre valeur"
      Souci '(5434, 5435...), puis relancez.'
      Stop-Net 'Port de base de donnees indisponible.'
    }
    if (Test-Path $log) { Get-Content $log -Tail 6 | ForEach-Object { Write-Host "  $_" } }
    Stop-Net "PostgreSQL n'a pas demarre (voir ci-dessus, et journaux\postgres.log)."
  }
}
function Pg-Arrete($c) {
  if (-not (Pg-Tourne $c)) { return }
  & $pgctl -D $donnees -m fast -w -t 60 stop | Out-Null
}
function Psql($c, [string[]]$args) {
  $env:PGPASSWORD = $c.PASS
  & $psql -h 127.0.0.1 -p $c.PG_PORT -U $c.USER -d $c.DB @args
}

# ---------------------------------------------------------------- application
function App-Repond($c) {
  try {
    $r = Invoke-WebRequest -Uri "http://127.0.0.1:$($c.APP_PORT)/actuator/health" -UseBasicParsing -TimeoutSec 4
    # Actuator repond dans un type que PowerShell ne considere pas comme du texte :
    # sans cette conversion, .Content est un tableau d'octets et la comparaison echoue.
    $t = if ($r.Content -is [byte[]]) { [System.Text.Encoding]::UTF8.GetString($r.Content) } else { [string]$r.Content }
    return ($t -match '"status"\s*:\s*"UP"')
  } catch { return $false }
}
function App-Demarre($c) {
  if (App-Repond $c) { Info 'Application deja en service.'; return }
  $jdbc = "jdbc:postgresql://127.0.0.1:$($c.PG_PORT)/$($c.DB)"
  $args = @(
    '-Xms256m', '-Xmx768m',
    '-Duser.timezone=Africa/Tunis', '-Dfile.encoding=UTF-8',
    '-jar', $jar,
    "--server.port=$($c.APP_PORT)",
    "--spring.datasource.url=$jdbc",
    "--spring.datasource.username=$($c.USER)",
    "--spring.datasource.password=$($c.PASS)"
  )
  Start-Process -FilePath $java -ArgumentList $args -WorkingDirectory $racine -WindowStyle Hidden `
    -RedirectStandardOutput (Join-Path $journal 'poscaisse.log') `
    -RedirectStandardError  (Join-Path $journal 'poscaisse-erreurs.log') | Out-Null

  Info 'Demarrage de la caisse...'
  for ($i = 0; $i -lt 90; $i++) {
    if (App-Repond $c) { Info 'Caisse prete.'; return }
    Start-Sleep -Seconds 2
  }
  $err = Join-Path $journal 'poscaisse-erreurs.log'
  $out = Join-Path $journal 'poscaisse.log'
  $traces = @($err, $out) | Where-Object { Test-Path $_ } | ForEach-Object { Get-Content $_ -Tail 30 }
  if ($traces -match 'already in use') {
    Souci "Le port $($c.APP_PORT) est deja pris par un autre programme."
    Souci "Ouvrez config\poscaisse.conf, remplacez APP_PORT=$($c.APP_PORT) par une autre valeur (8081...),"
    Souci 'puis relancez.'
    Stop-Net 'Port de la caisse indisponible.'
  }
  $traces | Select-Object -Last 10 | ForEach-Object { Write-Host "  $_" }
  Stop-Net "La caisse n'a pas repondu en 3 minutes (voir ci-dessus)."
}
function App-Arrete($c) {
  Get-CimInstance Win32_Process -Filter "Name = 'java.exe'" | Where-Object { $_.CommandLine -like '*poscaisse.jar*' } |
    ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
}

function Navigateur($c) {
  $url = "http://127.0.0.1:$($c.APP_PORT)/"
  if ($c.KIOSQUE -eq '1') {
    $exe = @(
      "$env:ProgramFiles\Google\Chrome\Application\chrome.exe",
      "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe",
      "$env:ProgramFiles\Microsoft\Edge\Application\msedge.exe",
      "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe"
    ) | Where-Object { Test-Path $_ } | Select-Object -First 1
    if ($exe) {
      # Sans profil dedie, le drapeau est ignore si une fenetre du navigateur est deja ouverte.
      $profil = Join-Path $env:LOCALAPPDATA 'PosCaisse\navigateur'
      Start-Process -FilePath $exe -ArgumentList @('--kiosk-printing', "--user-data-dir=$profil",
        '--no-first-run', '--no-default-browser-check', $url) | Out-Null
      return
    }
    Souci "Ni Chrome ni Edge : impression directe indisponible, le navigateur par defaut s'ouvre."
  }
  Start-Process $url
}

# ---------------------------------------------------------------- diagnostics
<# Lance << initdb --version >>, qui ne touche a rien, et rapporte tout ce qu'on peut
   savoir : reussite, code de retour, message eventuel. #>
function Tester-Initdb {
  $sortie = ''
  $code = -1
  try {
    $sortie = (& $initdb --version 2>&1 | Out-String).Trim()
    $code = $LASTEXITCODE
  } catch {
    $sortie = "$_"
  }
  return @{ Ok = ($code -eq 0 -and $sortie -match 'initdb'); Code = $code; Sortie = $sortie }
}

function Est-Administrateur {
  $id = [Security.Principal.WindowsIdentity]::GetCurrent()
  return (New-Object Security.Principal.WindowsPrincipal($id)).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

<#
    PostgreSQL doit pouvoir demarrer avant qu'on lui demande quoi que ce soit. Deux
    obstacles reviennent sans cesse sur un poste Windows neuf, et tous deux produisent
    le meme echec muet si on ne les nomme pas :

      - le dossier a ete lance en tant qu'administrateur. PostgreSQL refuse par
        conception de tourner avec des droits d'administration ;
      - la bibliotheque Microsoft VC++ manque : les binaires ne demarrent meme pas.

    On execute donc << initdb --version >>, qui ne touche a rien, avant tout le reste.
#>
function Verifier-Postgres {
  if (Est-Administrateur) {
    Souci "Cette fenetre a ete ouverte EN TANT QU'ADMINISTRATEUR."
    Souci 'PostgreSQL refuse de fonctionner avec des droits d''administration.'
    Souci ''
    Souci 'Fermez cette fenetre et double-cliquez simplement sur INSTALLER.bat,'
    Souci 'sans passer par << Executer en tant qu''administrateur >>.'
    Stop-Net 'Droits d''administration : installation impossible.'
  }

  $r = Tester-Initdb
  if ($r.Ok) { Info ("PostgreSQL repond : " + $r.Sortie); return }

  # Un programme dont il manque une DLL n'ecrit RIEN : Windows refuse de le charger avant
  # meme qu'il ne demarre. Un message vide est donc une information, pas une absence
  # d'information, a condition de donner le code de retour, qui lui parle.
  Souci 'Les programmes PostgreSQL ne demarrent pas sur ce PC.'
  Souci ("Code de retour : " + $r.Code + $(if ($r.Sortie) { " - " + $r.Sortie } else { " (aucun message : Windows n'a pas pu charger le programme)" }))
  Souci ''

  $vc = Join-Path (Join-Path $racine 'outils') 'vc_redist.x64.exe'
  if (-not (Test-Path $vc)) {
    Souci 'Il manque tres probablement la bibliotheque Microsoft VC++ (Visual C++'
    Souci 'Redistributable x64), que PostgreSQL exige.'
    Souci 'Elle n''est pas fournie dans ce paquet : recuperez vc_redist.x64.exe sur'
    Souci 'https://aka.ms/vs/17/release/vc_redist.x64.exe, installez-le, puis relancez.'
    Stop-Net 'Composant Windows manquant.'
  }

  Souci 'Il manque tres probablement la bibliotheque Microsoft VC++, que PostgreSQL exige.'
  Souci 'Elle est fournie dans ce paquet et peut etre installee maintenant.'
  Souci 'Windows demandera votre autorisation (fenetre bleue).'
  Write-Host ''
  $rep = Read-Host '  Installer ce composant maintenant ? [O/n]'
  if ($rep -and $rep -notmatch '^[oOyY]') {
    Souci "Installez outils\vc_redist.x64.exe vous-meme, puis relancez INSTALLER.bat."
    Stop-Net 'Composant Windows manquant.'
  }

  Etape 'Installation du composant Microsoft VC++'
  try {
    $p = Start-Process -FilePath $vc -ArgumentList @('/install', '/passive', '/norestart') -Wait -PassThru
    # 0 = installe, 1638 = une version plus recente est deja la, 3010 = redemarrage demande.
    Info ("Programme d'installation termine (code " + $p.ExitCode + ").")
    if ($p.ExitCode -eq 3010) { Souci 'Windows demande un redemarrage : redemarrez le PC puis relancez INSTALLER.bat.'; exit 0 }
  } catch {
    Souci "L'installation a ete refusee ou annulee : $_"
    Stop-Net 'Composant Windows manquant.'
  }

  $r = Tester-Initdb
  if (-not $r.Ok) {
    Souci ("PostgreSQL ne demarre toujours pas (code " + $r.Code + ").")
    Souci 'Redemarrez le PC, puis relancez INSTALLER.bat. Si le probleme persiste, le'
    Souci 'paquet ne convient peut-etre pas a ce Windows (il exige un Windows 64 bits).'
    Stop-Net 'Composant Windows manquant.'
  }
  Info ("PostgreSQL repond : " + $r.Sortie)
}

# ---------------------------------------------------------------- actions
function Faire-Install {
  Etape 'Verification du contenu du dossier'
  foreach ($f in @($java, $initdb, $pgctl, $jar)) {
    if (-not (Test-Path $f)) { Stop-Net "Fichier manquant : $f. Le dossier n'est pas complet." }
  }
  Info 'Moteur Java, PostgreSQL et application presents.'
  Verifier-Postgres

  if (Test-Path (Join-Path $donnees 'PG_VERSION')) {
    Souci 'Une base existe deja dans ce dossier : installation deja faite.'
    Souci "Pour repartir de zero, renommez le dossier << donnees >> puis relancez."
    return
  }

  $c = Lire-Config
  if (-not $c.PASS) { $c.PASS = Mot-De-Passe }
  Ecrire-Config $c

  Etape 'Creation de la base de donnees'
  $pwFile = Join-Path $env:TEMP ("pos-" + [guid]::NewGuid().ToString('N') + '.txt')
  $logInit = Join-Path $journal 'initdb.log'
  try {
    Set-Content -Path $pwFile -Value $c.PASS -Encoding ASCII -NoNewline
    # Le serveur n'ecoute que la machine elle-meme et exige un mot de passe : aucune
    # autre machine du reseau ne peut s'y connecter, meme si le PC est en Wi-Fi.
    # Toute la sortie est conservee : filtrer les lignes << interessantes >> revenait a
    # annoncer un echec sans jamais en donner la raison.
    & $initdb -D $donnees -U $c.USER --pwfile=$pwFile -A scram-sha-256 -E UTF8 --locale=C 2>&1 |
      Tee-Object -FilePath $logInit | Out-Null
    if (-not (Test-Path (Join-Path $donnees 'PG_VERSION'))) {
      if (Test-Path $logInit) {
        Souci '--- ce que PostgreSQL a repondu ---'
        Get-Content $logInit -Tail 15 | ForEach-Object { Write-Host "  $_" }
        Souci '-----------------------------------'
      }
      Souci "Journal complet : $logInit"
      Stop-Net 'La creation du serveur de base a echoue (raison ci-dessus).'
    }
  } finally { Remove-Item $pwFile -Force -ErrorAction SilentlyContinue }
  Info "Serveur cree, compte << $($c.USER) >>."

  Pg-Demarre $c
  $env:PGPASSWORD = $c.PASS
  & $psql -h 127.0.0.1 -p $c.PG_PORT -U $c.USER -d postgres -c "CREATE DATABASE $($c.DB);" | Out-Null
  Info "Base << $($c.DB) >> creee."

  Etape 'Premier demarrage'
  App-Demarre $c
  Info 'Tables et donnees de depart installees.'
  Etape 'Installation terminee'
  Info "Ouvrez la caisse avec DEMARRER.bat. Identifiants de depart : admin / admin123."
  Souci 'Changez ce mot de passe des la premiere connexion (Back-office -> Utilisateurs).'
  Navigateur $c
}

function Faire-Start {
  if (-not (Test-Path (Join-Path $donnees 'PG_VERSION'))) { Stop-Net "Rien n'est installe : lancez d'abord INSTALLER.bat." }
  $c = Lire-Config
  Pg-Demarre $c
  App-Demarre $c
  Navigateur $c
}

function Faire-Stop {
  $c = Lire-Config
  App-Arrete $c
  Pg-Arrete $c
  Info 'Caisse et base arretees.'
}

function Faire-Backup {
  $c = Lire-Config
  Pg-Demarre $c
  $nom = Join-Path $sauve ("poscaisse-" + (Get-Date -Format 'yyyy-MM-dd_HHmm') + '.dump')
  $env:PGPASSWORD = $c.PASS
  & $pgdump -h 127.0.0.1 -p $c.PG_PORT -U $c.USER -d $c.DB -Fc -f $nom
  if ($LASTEXITCODE -ne 0) { Stop-Net 'La sauvegarde a echoue.' }
  Info "Sauvegarde ecrite : $nom"
  # Une sauvegarde qui reste sur le disque du PC ne protege pas d'une panne de ce disque.
  Souci 'Copiez ce fichier sur une cle USB : sur ce disque, il ne survivrait pas a une panne.'
}

function Faire-Restore {
  if (-not $Fichier -or -not (Test-Path $Fichier)) { Stop-Net "Indiquez le fichier de sauvegarde a restaurer." }
  $c = Lire-Config
  Write-Host ''
  Write-Host "  Cette operation REMPLACE toutes les donnees actuelles par celles de :" -ForegroundColor Yellow
  Write-Host "  $Fichier" -ForegroundColor Yellow
  if ((Read-Host '  Tapez OUI pour confirmer') -ne 'OUI') { Info 'Abandon.'; return }
  App-Arrete $c
  Pg-Demarre $c
  $env:PGPASSWORD = $c.PASS
  & $psql -h 127.0.0.1 -p $c.PG_PORT -U $c.USER -d postgres -c "DROP DATABASE IF EXISTS $($c.DB);" | Out-Null
  & $psql -h 127.0.0.1 -p $c.PG_PORT -U $c.USER -d postgres -c "CREATE DATABASE $($c.DB);" | Out-Null
  # --no-owner et --no-privileges : le dump vient souvent d'une autre installation, ou la
  # base appartient a un compte (<< postgres >>) qui n'existe pas ici. Sans cela, la
  # restauration s'acheve sur une avalanche de << role inexistant >> et des tables sans
  # proprietaire. Les objets restaures appartiennent au compte de ce poste.
  & $restore -h 127.0.0.1 -p $c.PG_PORT -U $c.USER -d $c.DB --no-owner --no-privileges $Fichier
  if ($LASTEXITCODE -ne 0) { Souci 'La restauration a signale des avertissements (voir ci-dessus).' }
  $n = & $psql -h 127.0.0.1 -p $c.PG_PORT -U $c.USER -d $c.DB -tAc 'select count(*) from product'
  Info ("Restauration terminee : " + ("$n".Trim()) + " article(s) dans la base.")
  Info 'Relancez avec DEMARRER.bat.'
}

function Faire-Status {
  $c = Lire-Config
  Info ("Base de donnees : " + $(if (Pg-Tourne $c) { "en service (port $($c.PG_PORT))" } else { 'arretee' }))
  Info ("Caisse          : " + $(if (App-Repond $c) { "en service (http://127.0.0.1:$($c.APP_PORT)/)" } else { 'arretee' }))
  Info ("Dossier         : $racine")
  if (Test-Path $sauve) {
    $d = Get-ChildItem $sauve -Filter *.dump -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    Info ("Derniere sauvegarde : " + $(if ($d) { "$($d.Name) ($($d.LastWriteTime))" } else { 'aucune' }))
  }
}

switch ($Action) {
  'install' { Faire-Install }
  'start'   { Faire-Start }
  'stop'    { Faire-Stop }
  'backup'  { Faire-Backup }
  'restore' { Faire-Restore }
  'status'  { Faire-Status }
}
