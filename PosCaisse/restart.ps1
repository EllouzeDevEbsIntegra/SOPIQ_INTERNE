# =====================================================================
#  PosCaisse - tout en un : arret, mise a jour, base, build, demarrage.
#  Lance par RESTART_POS.bat (double-clic). Rien d'autre a faire.
#
#  La logique vit ici et non dans le .bat : cmd.exe casse silencieusement
#  sur les etiquettes et les blocs parentheses des que le script grossit.
# =====================================================================
param(
  # 'restart' : arrete ce qui tourne puis relance.  'start' : ne tue rien ;
  # si PosCaisse repond deja, ouvre simplement le navigateur.
  [ValidateSet('restart', 'start')] [string] $Mode = 'restart',
  # Conserve pour compatibilite : la pause est desormais faite par le .bat,
  # afin qu'une erreur de PowerShell lui-meme reste lisible a l'ecran.
  [switch] $Pause
)
$ErrorActionPreference = 'Continue'

$root = $PSScriptRoot
Set-Location -Path $root

function Get-Setting([string]$name, [string]$fallback) {
  $v = [Environment]::GetEnvironmentVariable($name)
  if ([string]::IsNullOrWhiteSpace($v)) { return $fallback }
  return $v
}

$port   = Get-Setting 'POSCAISSE_PORT' '8080'
$dbName = Get-Setting 'POSCAISSE_DB_NAME' 'poscaisse'

# Journal : si quelque chose se passe mal, logs\restart.log garde la trace.
$logDir = Join-Path $root 'logs'
if (-not (Test-Path -LiteralPath $logDir)) { New-Item -ItemType Directory -Path $logDir | Out-Null }
try { Start-Transcript -Path (Join-Path $logDir 'restart.log') -Force | Out-Null } catch { }

function Quit([int]$code) {
  try { Stop-Transcript | Out-Null } catch { }
  if ($Pause) {
    Write-Host ''
    Write-Host '  Appuyez sur Entree pour fermer cette fenetre.'
    [void](Read-Host)
  }
  exit $code
}

Write-Host '=========================================================='
if ($Mode -eq 'start') { Write-Host '  PosCaisse - lancement' }
else                   { Write-Host '  PosCaisse - redemarrage complet' }
Write-Host '=========================================================='

# ------------------------------------------------------------ 1. arret
Write-Host ''
Write-Host "[1/6] Arret des instances en cours..."

function Stop-Port([int]$p) {
  $pids = @()
  try {
    $pids = Get-NetTCPConnection -LocalPort $p -State Listen -ErrorAction Stop |
            Select-Object -ExpandProperty OwningProcess -Unique
  } catch {
    # Windows 7 / PowerShell sans module NetTCPIP : repli sur netstat.
    $pids = netstat -ano | Select-String ":$p\s" | Select-String 'LISTENING' | ForEach-Object {
      ($_ -split '\s+' | Where-Object { $_ -ne '' })[-1]
    } | Sort-Object -Unique
  }
  foreach ($procId in $pids) {
    if ($procId -and $procId -ne '0') {
      Stop-Process -Id $procId -Force -ErrorAction SilentlyContinue
    }
  }
}

# Actuator repond en application/vnd.spring-boot.actuator.v3+json : un type que
# PowerShell ne reconnait pas comme texte, donc .Content est un tableau d'octets
# et non une chaine. Comparer directement avec -match ne matcherait jamais.
function Get-HealthText([int]$p) {
  try {
    $r = Invoke-WebRequest -Uri "http://localhost:$p/actuator/health" -UseBasicParsing -TimeoutSec 4
    if ($r.Content -is [byte[]]) { return [System.Text.Encoding]::UTF8.GetString($r.Content) }
    return [string]$r.Content
  } catch { return '' }
}

function Test-PosRunning([int]$p) { return ((Get-HealthText $p) -match '"status"\s*:\s*"UP"') }

# Un navigateur par defaut absent ou mal enregistre ne doit pas faire echouer
# le demarrage : l'adresse est de toute facon affichee a l'ecran.
# Chrome ou Edge : les seuls a savoir imprimer sans dialogue (--kiosk-printing).
function Get-KioskBrowser {
  $candidats = @(
    "$env:ProgramFiles\Google\Chrome\Application\chrome.exe",
    "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe",
    "$env:LOCALAPPDATA\Google\Chrome\Application\chrome.exe",
    "$env:ProgramFiles\Microsoft\Edge\Application\msedge.exe",
    "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe"
  )
  foreach ($c in $candidats) { if ($c -and (Test-Path -LiteralPath $c)) { return $c } }
  return $null
}

function Open-Browser([string]$url) {
  # --kiosk-printing : le ticket part sur l'imprimante par defaut de Windows,
  # sans dialogue. POSCAISSE_KIOSK=0 revient au navigateur habituel.
  if ((Get-Setting 'POSCAISSE_KIOSK' '1') -eq '1') {
    $exe = Get-KioskBrowser
    if ($exe) {
      # --user-data-dir est indispensable : sans profil dedie, si une fenetre du
      # navigateur est deja ouverte, la commande n'ouvre qu'un onglet dans
      # l'instance existante et le drapeau est purement ignore.
      $profil = Join-Path $env:LOCALAPPDATA 'PosCaisse\navigateur'
      try {
        Start-Process -FilePath $exe -ArgumentList @(
          '--kiosk-printing', "--user-data-dir=$profil",
          '--no-first-run', '--no-default-browser-check', $url) | Out-Null
        Write-Host '    Navigateur ouvert en impression silencieuse.'
        return
      } catch { }
    } else {
      Write-Host '    Chrome ou Edge introuvable : le dialogue d impression restera affiche.'
    }
  }
  try { Start-Process $url | Out-Null } catch { Write-Host "    Ouvrez $url dans votre navigateur." }
}

if ($Mode -eq 'start') {
  if (Test-PosRunning ([int]$port)) {
    Write-Host "    PosCaisse tourne deja sur le port $port : ouverture du navigateur."
    Open-Browser "http://localhost:$port"
    Write-Host ''
    Write-Host '    Pour repartir de zero, utilisez RESTART_POS.bat.'
    Quit 0
  }
  # Port occupe par autre chose (ancienne instance figee) : on libere quand meme.
  Stop-Port ([int]$port)
  Write-Host '    Rien a arreter.'
} else {
  Stop-Port ([int]$port)
  Stop-Port 5173
  # Get-Process n'expose pas CommandLine en PowerShell 5.1 : passer par CIM.
  Get-CimInstance Win32_Process -Filter "Name = 'java.exe'" -ErrorAction SilentlyContinue |
    Where-Object { $_.CommandLine -like '*poscaisse-backend*' } |
    ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
  Write-Host "    Ports $port et 5173 liberes."
}

# ------------------------------------------------------- 2. mise a jour
Write-Host ''
Write-Host '[2/6] Mise a jour du code...'
$rebuild = $false
$git = Get-Command git -ErrorAction SilentlyContinue
if ($Mode -eq 'start') {
  # START_POS lance ce qui est deja sur le disque : pas de git pull, pour que
  # le demarrage du matin reste previsible et rapide.
  Write-Host '    Mode lancement : mise a jour ignoree (utilisez RESTART_POS.bat).'
} elseif ($git) {
  git rev-parse --is-inside-work-tree 2>$null | Out-Null
  if ($LASTEXITCODE -eq 0) {
    $before = (git rev-parse HEAD 2>$null)
    git pull --ff-only
    if ($LASTEXITCODE -ne 0) {
      Write-Host '    git pull a echoue (modifications locales ou reseau) : on continue avec le code present.'
    }
    $after = (git rev-parse HEAD 2>$null)
    if ($before -eq $after) { Write-Host '    Deja a jour.' }
    else { Write-Host '    Nouvelle version recuperee.'; $rebuild = $true }
  } else {
    Write-Host '    Dossier hors depot git : etape ignoree.'
  }
} else {
  Write-Host '    git absent : etape ignoree.'
}

# ------------------------------------------------------- 3. PostgreSQL
Write-Host ''
Write-Host '[3/6] PostgreSQL et base de donnees...'
. (Join-Path $root 'init-db.ps1')
Start-PostgresService
# Select-Object -Last 1 : une sortie parasite de la fonction transformerait
# le booleen attendu en tableau.
$dbReady = [bool](Ensure-Database | Select-Object -Last 1)

# ------------------------------------------------------- 4. compilation
# La comparaison des dates source/binaire est la seule fiable : comparer le
# commit avant/apres le pull rate le cas d'une mise a jour faite a la main.
Write-Host ''

function Test-Stale([string]$artifact, [string[]]$sources) {
  $a = Get-Item -LiteralPath (Join-Path $root $artifact) -ErrorAction SilentlyContinue
  if (-not $a) { return $true }
  foreach ($s in $sources) {
    $full = Join-Path $root $s
    if (-not (Test-Path -LiteralPath $full)) { continue }
    $newer = Get-ChildItem -LiteralPath $full -Recurse -File -ErrorAction SilentlyContinue |
             Where-Object { $_.LastWriteTime -gt $a.LastWriteTime } |
             Select-Object -First 1
    if ($newer) { return $true }
  }
  return $false
}

if (Test-Stale 'frontend\dist\index.html' @('frontend\src', 'frontend\package.json', 'frontend\vite.config.js', 'frontend\index.html')) { $rebuild = $true }
if (Test-Stale 'backend\target\poscaisse-backend.jar' @('backend\src', 'backend\pom.xml')) { $rebuild = $true }

if (-not $rebuild) {
  Write-Host '[4/6] Aucun changement : compilation inutile.'
} else {
  Write-Host '[4/6] Compilation (cela peut prendre 1 a 2 minutes)...'

  if (Get-Command npm -ErrorAction SilentlyContinue) {
    Push-Location (Join-Path $root 'frontend')
    if (-not (Test-Path 'node_modules')) {
      Write-Host '    Installation des dependances npm...'
      cmd /c 'npm install --no-audit --no-fund'
    }
    Write-Host "    Construction de l'interface..."
    cmd /c 'npm run build'
    if ($LASTEXITCODE -ne 0) { Write-Host "    ECHEC de la construction de l'interface." }
    Pop-Location
  } else {
    Write-Host "    npm introuvable : l'interface ne peut pas etre compilee."
    Write-Host '    Installez Node.js depuis https://nodejs.org puis relancez ce script.'
  }

  if (-not (Get-Command mvn -ErrorAction SilentlyContinue)) {
    Write-Host '    Maven introuvable : impossible de construire le backend.'
    Write-Host '    Installez Maven puis relancez ce script.'
    Quit 1
  }
  Push-Location (Join-Path $root 'backend')
  Write-Host '    Construction du backend...'
  cmd /c 'mvn -q -B package -DskipTests'
  $mvnCode = $LASTEXITCODE
  Pop-Location
  if ($mvnCode -ne 0) {
    Write-Host '    ECHEC de la construction du backend.'
    Write-Host '    Redemarrage interrompu.'
    Quit 1
  }
}

if (-not $dbReady) {
  Write-Host ''
  Write-Host '    ATTENTION : la base de donnees n a pas pu etre verifiee.'
  Write-Host '    Le backend est lance quand meme ; s il refuse de demarrer,'
  Write-Host '    creez la base puis relancez ce script.'
}

# --------------------------------------------------------- 5. demarrage
Write-Host ''
Write-Host "[5/6] Demarrage du backend sur le port $port..."
$backendDir = Join-Path $root 'backend'
$jar = Join-Path $backendDir 'target\poscaisse-backend.jar'
if (Test-Path -LiteralPath $jar) {
  Start-Process -FilePath 'cmd.exe' `
    -ArgumentList '/k', "cd /d `"$backendDir`" && java -jar target\poscaisse-backend.jar" `
    -WindowStyle Minimized | Out-Null
} else {
  Start-Process -FilePath 'cmd.exe' `
    -ArgumentList '/k', "cd /d `"$backendDir`" && mvn -q spring-boot:run" `
    -WindowStyle Minimized | Out-Null
}

# ----------------------------------------------------------- 6. attente
Write-Host ''
Write-Host '[6/6] Attente du demarrage...'
$ready = $false
for ($i = 0; $i -lt 60; $i++) {
  Start-Sleep -Seconds 3
  if (Test-PosRunning ([int]$port)) { $ready = $true; break }
}

if (-not $ready) {
  Write-Host ''
  Write-Host '    Le backend ne repond pas. Ouvrez la fenetre du backend'
  Write-Host '    (barre des taches) et lisez la ligne "Caused by".'
  Quit 1
}

Write-Host '    Backend pret.'
Open-Browser "http://localhost:$port"
Write-Host ''
Write-Host '=========================================================='
Write-Host "  PosCaisse est lance : http://localhost:$port"
Write-Host '=========================================================='
Write-Host ''
Write-Host '  Admin    admin / admin123      PIN 9999'
Write-Host '  Manager  manager / manager123  PIN 2222'
Write-Host '  Caissier Ahmed 1234 - Sami 5678 - Mariem 4321'
Write-Host ''
Write-Host '  Cette fenetre peut etre fermee. Pour arreter : STOP_POS.bat'
Quit 0
