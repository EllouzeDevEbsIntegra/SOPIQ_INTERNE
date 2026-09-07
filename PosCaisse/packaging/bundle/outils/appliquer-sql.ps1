<#
    Applique un fichier .sql sur la base de CE poste.

        APPLIQUER_SQL.bat            (choisit parmi les .sql du dossier)
        powershell -File outils\appliquer-sql.ps1 -Fichier maintenance.sql

    Le paquet embarque son propre PostgreSQL, sur un port et avec un mot de passe
    qui n'appartiennent qu'a lui : psql n'est pas dans le PATH et les reglages ne
    sont pas ceux d'un poste de developpement. Ce script lit donc config\poscaisse.conf
    et se sert de pgsql\bin\psql.exe.

    UNE SAUVEGARDE est prise avant, systematiquement. Un .sql de maintenance touche
    des donnees reelles : le filet coute dix secondes, et il n'y a pas d'autre retour
    en arriere.

    Compatible Windows PowerShell 5.1.
#>
param([string] $Fichier = "", [switch] $SansConfirmation)

$ErrorActionPreference = 'Stop'
$racine = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$pg     = Join-Path $racine 'pgsql'
$psql   = Join-Path $pg 'bin\psql.exe'
$pgdump = Join-Path $pg 'bin\pg_dump.exe'
$config = Join-Path $racine 'config\poscaisse.conf'
$sauve  = Join-Path $racine 'sauvegardes'

function Info($m)  { Write-Host "  $m" }
function Souci($m) { Write-Host "  $m" -ForegroundColor Yellow }
function Stop-Net($m) { Write-Host ''; Write-Host "ARRET : $m" -ForegroundColor Red; exit 1 }

if (-not (Test-Path $psql)) { Stop-Net "PostgreSQL du paquet introuvable ($psql)." }
if (-not (Test-Path $config)) { Stop-Net "Ce poste n'est pas installe : config\poscaisse.conf manque." }

$c = @{ PG_PORT = '5433'; DB = 'poscaisse'; USER = 'poscaisse'; PASS = '' }
foreach ($l in Get-Content $config) { if ($l -match '^\s*([A-Z_]+)\s*=\s*(.*?)\s*$') { $c[$Matches[1]] = $Matches[2] } }
$env:PGPASSWORD = $c.PASS
$env:PGCLIENTENCODING = 'UTF8'

# Le fichier : celui passe en parametre, sinon on montre ce qu'il y a sous la main.
if (-not $Fichier) {
    $sqls = @(Get-ChildItem -Path $racine -Filter *.sql -ErrorAction SilentlyContinue | Sort-Object Name)
    if (-not $sqls) { Stop-Net "Aucun fichier .sql dans $racine. Copiez-y celui a appliquer." }
    Write-Host ''
    Write-Host '  Fichiers .sql disponibles :'
    for ($i = 0; $i -lt $sqls.Count; $i++) { Write-Host ("    [{0}] {1}" -f ($i + 1), $sqls[$i].Name) }
    Write-Host ''
    $n = Read-Host '  Numero du fichier a appliquer'
    if (-not ($n -match '^\d+$') -or [int]$n -lt 1 -or [int]$n -gt $sqls.Count) { Stop-Net 'Numero invalide.' }
    $Fichier = $sqls[[int]$n - 1].FullName
}
if (-not (Test-Path $Fichier)) { Stop-Net "Fichier introuvable : $Fichier" }

Write-Host ''
Write-Host "  Fichier : $Fichier"
Write-Host "  Base    : $($c.DB) sur le port $($c.PG_PORT) de ce poste"
Write-Host ''
if (-not $SansConfirmation) {
    $rep = Read-Host '  Tapez OUI pour appliquer'
    if ($rep -ne 'OUI') { Write-Host '  Annule.'; exit 0 }
}

# La base doit tourner : le paquet l'arrete avec la caisse.
& $psql -h 127.0.0.1 -p $c.PG_PORT -U $c.USER -d $c.DB -tAc 'SELECT 1' 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) { Stop-Net "La base ne repond pas. Lancez DEMARRER.bat, puis relancez ce script." }

New-Item -ItemType Directory -Force -Path $sauve | Out-Null
$filet = Join-Path $sauve ("poscaisse-" + (Get-Date -Format 'yyyyMMdd-HHmm') + "-avant-sql.dump")
Write-Host '  [1/2] Sauvegarde...'
& $pgdump -h 127.0.0.1 -p $c.PG_PORT -U $c.USER -d $c.DB -Fc -f $filet
if ($LASTEXITCODE -ne 0) { Stop-Net "La sauvegarde a echoue : on n'applique rien sans filet." }
Info "$filet"

Write-Host ''
Write-Host '  [2/2] Application...'
& $psql -h 127.0.0.1 -p $c.PG_PORT -U $c.USER -d $c.DB -v ON_ERROR_STOP=1 -f $Fichier
if ($LASTEXITCODE -ne 0) {
    Write-Host ''
    Souci "Le script s'est arrete. Ce qui etait dans une transaction n'a pas ete applique."
    Souci "Retour en arriere complet, si besoin : outils\poscaisse.ps1 restore -Fichier `"$filet`""
    exit 1
}
Write-Host ''
Write-Host '  Termine.' -ForegroundColor Green
Write-Host "  Sauvegarde d'avant : $filet"
Write-Host '  Rechargez la page de la caisse (Ctrl+F5) pour voir les changements.'
Write-Host ''
