<#
    Fabrique le paquet autonome de PosCaisse, a executer sur une machine QUI A INTERNET.

    Le resultat est un dossier - et son ZIP - a copier tel quel sur le PC du client, qui
    lui n'a besoin de rien : ni Java, ni PostgreSQL, ni Node, ni droits administrateur.

    Les archives tierces (moteur Java, PostgreSQL) sont conservees dans << telechargements >>
    et reutilisees d'une fabrication a l'autre. Si un telechargement echoue - lien deplace,
    reseau filtre - le script dit exactement quel fichier deposer la, a la main.
#>
param(
  [string]$Version = (Get-Date -Format 'yyyy.MM.dd'),
  [switch]$SansTests
)

$ErrorActionPreference = 'Stop'
$ici     = Split-Path -Parent $MyInvocation.MyCommand.Path
$projet  = Split-Path -Parent $ici
$tele    = Join-Path $ici 'telechargements'
$sortie  = Join-Path $ici "dist\PosCaisse-$Version"
New-Item -ItemType Directory -Force -Path $tele | Out-Null

function Etape($m) { Write-Host ''; Write-Host "== $m" -ForegroundColor Cyan }
function Info($m)  { Write-Host "  $m" }
function Stop-Net($m) { Write-Host ''; Write-Host "ARRET : $m" -ForegroundColor Red; exit 1 }

# Versions figees : le poste client tourne exactement sur ce qui a ete teste ici.
$sources = @(
  @{ Nom = 'jre';   Fichier = 'jre-21-windows-x64.zip'
     Url = 'https://api.adoptium.net/v3/binary/latest/21/ga/windows/x64/jre/hotspot/normal/eclipse'
     Aide = 'https://adoptium.net/temurin/releases/?os=windows&arch=x64&package=jre&version=21 (archive .zip)' },
  @{ Nom = 'pgsql'; Fichier = 'postgresql-16-windows-x64-binaries.zip'
     Url = 'https://get.enterprisedb.com/postgresql/postgresql-16.8-1-windows-x64-binaries.zip'
     Aide = 'https://www.enterprisedb.com/download-postgresql-binaries (PostgreSQL 16, Windows x86-64)' }
)

Etape 'Recuperation des composants tiers'
foreach ($s in $sources) {
  $dest = Join-Path $tele $s.Fichier
  if (Test-Path $dest) { Info "$($s.Fichier) : deja present"; continue }
  Info "$($s.Fichier) : telechargement..."
  try {
    Invoke-WebRequest -Uri $s.Url -OutFile $dest -UseBasicParsing
  } catch {
    Remove-Item $dest -Force -ErrorAction SilentlyContinue
    Write-Host ''
    Write-Host "  Telechargement impossible : $($s.Fichier)" -ForegroundColor Yellow
    Write-Host "  Recuperez l'archive ici : $($s.Aide)" -ForegroundColor Yellow
    Write-Host "  puis deposez-la sous ce nom exact dans : $tele" -ForegroundColor Yellow
    Stop-Net 'Composant tiers manquant.'
  }
}

Etape 'Compilation de l''interface'
Push-Location (Join-Path $projet 'frontend')
try {
  cmd /c 'npm ci --no-audit --no-fund'; if ($LASTEXITCODE -ne 0) { Stop-Net 'npm ci a echoue.' }
  if (-not $SansTests) { cmd /c 'npm test'; if ($LASTEXITCODE -ne 0) { Stop-Net 'Les tests du panier echouent.' } }
  cmd /c 'npm run build'; if ($LASTEXITCODE -ne 0) { Stop-Net 'La compilation de l''interface a echoue.' }
} finally { Pop-Location }

Etape 'Compilation de l''application (interface incluse dans le JAR)'
Push-Location (Join-Path $projet 'backend')
try {
  $opts = if ($SansTests) { '-DskipTests' } else { '' }
  cmd /c "mvn -q -B -Pbundle package $opts"
  if ($LASTEXITCODE -ne 0) { Stop-Net 'La compilation du backend a echoue.' }
} finally { Pop-Location }

Etape 'Assemblage du paquet'
if (Test-Path $sortie) { Remove-Item $sortie -Recurse -Force }
New-Item -ItemType Directory -Force -Path $sortie | Out-Null

Copy-Item (Join-Path $projet 'backend\target\poscaisse-backend.jar') (Join-Path $sortie 'poscaisse.jar')
Copy-Item (Join-Path $ici 'bundle\*') $sortie -Recurse -Force
if (Test-Path (Join-Path $projet 'catalogs')) { Copy-Item (Join-Path $projet 'catalogs') $sortie -Recurse -Force }
# Le jumeau Linux n'a rien a faire dans un paquet Windows.
Remove-Item (Join-Path $sortie 'outils\poscaisse.sh') -Force -ErrorAction SilentlyContinue

function Extraire($zip, $vers, $strip) {
  $tmp = Join-Path $env:TEMP ('pos-' + [guid]::NewGuid().ToString('N'))
  Expand-Archive -Path $zip -DestinationPath $tmp -Force
  # Ces archives contiennent un dossier racine (<< jdk-21... >>, << pgsql >>) dont on se passe.
  $src = if ($strip) { (Get-ChildItem $tmp -Directory | Select-Object -First 1).FullName } else { $tmp }
  Move-Item $src $vers -Force
  Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
}
Info 'Moteur Java...'
Extraire (Join-Path $tele 'jre-21-windows-x64.zip') (Join-Path $sortie 'jre') $true
Info 'PostgreSQL...'
Extraire (Join-Path $tele 'postgresql-16-windows-x64-binaries.zip') (Join-Path $sortie 'pgsql') $true

foreach ($f in @('jre\bin\java.exe', 'pgsql\bin\initdb.exe', 'pgsql\bin\pg_ctl.exe', 'poscaisse.jar', 'INSTALLER.bat')) {
  if (-not (Test-Path (Join-Path $sortie $f))) { Stop-Net "Le paquet est incomplet : $f manque." }
}
Set-Content -Path (Join-Path $sortie 'VERSION.txt') -Value "PosCaisse $Version - paquet autonome Windows x64" -Encoding UTF8

Etape 'Compression'
$zip = "$sortie.zip"
if (Test-Path $zip) { Remove-Item $zip -Force }
Compress-Archive -Path $sortie -DestinationPath $zip
$taille = [math]::Round((Get-Item $zip).Length / 1MB, 1)

Etape 'Paquet pret'
Info "Dossier : $sortie"
Info "Archive : $zip ($taille Mo)"
Info 'Copiez cette archive sur le PC du client, decompressez-la, puis lancez INSTALLER.bat.'
