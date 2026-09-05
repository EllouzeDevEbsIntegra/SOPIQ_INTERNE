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
function Souci($m) { Write-Host "  $m" -ForegroundColor Yellow }
function Stop-Net($m) { Write-Host ''; Write-Host "ARRET : $m" -ForegroundColor Red; exit 1 }

<#
    Ferme les caisses encore en service. Ce n'est plus indispensable depuis que le JAR de
    la fabrication porte un nom neuf, qu'aucun programme ne peut retenir, mais cela evite
    de laisser tourner une ancienne version pendant qu'on en prepare une nouvelle.

    START_POS lance la caisse par << java -jar >> dans une fenetre REDUITE : on l'oublie
    facilement, et c'est elle qui tenait le fichier.
#>
function Arreter-Caisses {
  $procs = @(Get-CimInstance Win32_Process -Filter "Name = 'java.exe'" -ErrorAction SilentlyContinue |
             Where-Object { $_.CommandLine -like '*poscaisse*' })
  if (-not $procs) { return }
  foreach ($p in $procs) {
    Souci "Une caisse tourne encore (PID $($p.ProcessId)) : arret avant compilation."
    Stop-Process -Id $p.ProcessId -Force -ErrorAction SilentlyContinue
  }
  Start-Sleep -Seconds 3
}

# Versions figees : le poste client tourne exactement sur ce qui a ete teste ici.
$sources = @(
  @{ Nom = 'jre';   Fichier = 'jre-21-windows-x64.zip'
     Url = 'https://api.adoptium.net/v3/binary/latest/21/ga/windows/x64/jre/hotspot/normal/eclipse'
     Aide = 'https://adoptium.net/temurin/releases/?os=windows&arch=x64&package=jre&version=21 (archive .zip)' },
  @{ Nom = 'pgsql'; Fichier = 'postgresql-16-windows-x64-binaries.zip'
     Url = 'https://get.enterprisedb.com/postgresql/postgresql-16.8-1-windows-x64-binaries.zip'
     Aide = 'https://www.enterprisedb.com/download-postgresql-binaries (PostgreSQL 16, Windows x86-64)' },
  # PostgreSQL fourni en binaires exige cette bibliotheque Microsoft. Elle est presente
  # sur la plupart des Windows recents, mais pas sur tous : l'embarquer evite un
  # deplacement chez le client pour un fichier de 25 Mo qu'il ne peut pas telecharger.
  @{ Nom = 'vcredist'; Fichier = 'vc_redist.x64.exe'; Facultatif = $true
     Url = 'https://aka.ms/vs/17/release/vc_redist.x64.exe'
     Aide = 'https://aka.ms/vs/17/release/vc_redist.x64.exe' }
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
    Write-Host "  Recuperez le fichier ici : $($s.Aide)" -ForegroundColor Yellow
    Write-Host "  puis deposez-le sous ce nom exact dans : $tele" -ForegroundColor Yellow
    if ($s.Facultatif) {
      Write-Host '  (facultatif : le paquet se fabrique sans, mais le poste client devra' -ForegroundColor Yellow
      Write-Host '   deja disposer de la bibliotheque Microsoft VC++)' -ForegroundColor Yellow
    } else {
      Stop-Net 'Composant tiers manquant.'
    }
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
Arreter-Caisses
$backend = Join-Path $projet 'backend'
# Le JAR de cette fabrication porte un nom qui n'a jamais servi. C'est ce qui rend la
# compilation insensible a une caisse restee ouverte : Windows interdit de supprimer ou de
# renommer un fichier ouvert, mais rien n'empeche d'en ecrire un autre a cote.
$nomJar = 'poscaisse-bundle-' + (Get-Date -Format 'yyyyMMdd-HHmmss')
Push-Location $backend
try {
  # Pas de << clean >> : il buterait sur ce meme fichier ouvert. On vide seulement
  # l'interface deja copiee lors d'une fabrication precedente, pour ne pas laisser
  # d'anciens ecrans dans le nouveau JAR.
  $statique = Join-Path $backend 'target\classes\static'
  if (Test-Path $statique) { Remove-Item $statique -Recurse -Force -ErrorAction SilentlyContinue }

  $opts = if ($SansTests) { '-DskipTests' } else { '' }
  cmd /c "mvn -q -B -Pbundle package $opts `"-Dposcaisse.finalName=$nomJar`""
  if ($LASTEXITCODE -ne 0) {
    Souci ''
    Souci 'Si le message parle d''un fichier utilise par un autre processus, ouvrez le'
    Souci 'Moniteur de ressources (touche Windows, tapez << resmon >>), onglet Processeur,'
    Souci 'section << Handles associes >>, et cherchez le nom du fichier : Windows nomme'
    Souci 'alors le programme qui le retient.'
    Stop-Net 'La compilation du backend a echoue.'
  }
} finally { Pop-Location }
$jarProduit = Join-Path $backend "target\$nomJar.jar"
if (-not (Test-Path $jarProduit)) { Stop-Net "Le JAR attendu n'a pas ete produit : $jarProduit" }

Etape 'Assemblage du paquet'
if (Test-Path $sortie) { Remove-Item $sortie -Recurse -Force }
New-Item -ItemType Directory -Force -Path $sortie | Out-Null

Copy-Item $jarProduit (Join-Path $sortie 'poscaisse.jar')
# Le JAR horodate a joue son role : le garder encombrerait target de 60 Mo par fabrication.
Remove-Item $jarProduit, "$jarProduit.original" -Force -ErrorAction SilentlyContinue
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
$vc = Join-Path $tele 'vc_redist.x64.exe'
if (Test-Path $vc) {
  Copy-Item $vc (Join-Path $sortie 'outils\vc_redist.x64.exe') -Force
  Info 'Bibliotheque Microsoft VC++ incluse.'
} else {
  Write-Host '  Bibliotheque Microsoft VC++ absente du paquet : le poste client devra deja' -ForegroundColor Yellow
  Write-Host '  en disposer, sinon PostgreSQL ne demarrera pas.' -ForegroundColor Yellow
}

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
