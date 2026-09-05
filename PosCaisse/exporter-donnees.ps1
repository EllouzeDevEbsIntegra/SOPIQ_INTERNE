<#
    Exporte les donnees de VOTRE poste de developpement vers un fichier, pour les
    transferer sur un poste autonome (celui du client).

    Le paquet autonome s'installe avec un jeu de demonstration : enseigne fictive,
    articles d'exemple. Ce script prend la place de cette demonstration par ce que vous
    avez reellement prepare : votre carte, votre entreprise, vos utilisateurs, vos
    reglages de ticket.

    Deux facons de proceder, la question est posee au lancement :
      - AVEC les ventes    : copie conforme, tests compris. Utile pour reproduire un
                             probleme sur un autre poste.
      - SANS les ventes    : la carte et les reglages seulement. C'est ce qu'il faut pour
                             une mise en service : le client demarre avec un journal vierge
                             et une numerotation de tickets qui repart a 1.
#>
param(
  [switch]$AvecLesVentes,
  [switch]$SansQuestion
)

$ErrorActionPreference = 'Stop'
$racine = Split-Path -Parent $MyInvocation.MyCommand.Path
$sortie = Join-Path $racine 'exports'
New-Item -ItemType Directory -Force -Path $sortie | Out-Null

function Etape($m) { Write-Host ''; Write-Host "== $m" -ForegroundColor Cyan }
function Info($m)  { Write-Host "  $m" }
function Souci($m) { Write-Host "  $m" -ForegroundColor Yellow }
function Stop-Net($m) { Write-Host ''; Write-Host "ARRET : $m" -ForegroundColor Red; exit 1 }

# Donnees transactionnelles : ce qu'une mise en service ne doit pas emporter. Meme liste
# que la remise a zero des ventes du back-office, document_sequence compris pour que la
# numerotation des tickets reparte a 1 chez le client.
$tablesDeVentes = @(
  'print_job', 'refund', 'payment', 'order_line_modifier', 'order_line', 'sale_order',
  'cash_movement', 'register_journal', 'daily_closure', 'account_payment',
  'register_session', 'document_sequence', 'audit_log'
)

function Trouver-Outil([string]$nom) {
  $cmd = Get-Command $nom -ErrorAction SilentlyContinue
  if ($cmd) { return $cmd.Source }
  foreach ($v in @('17', '16', '15', '14')) {
    $p = "C:\Program Files\PostgreSQL\$v\bin\$nom"
    if (Test-Path $p) { return $p }
  }
  # A defaut, celui du paquet autonome, s'il a deja ete fabrique.
  $p = Join-Path $racine "packaging\telechargements\pgsql\bin\$nom"
  if (Test-Path $p) { return $p }
  return $null
}

$pgdump = Trouver-Outil 'pg_dump.exe'
if (-not $pgdump) {
  Stop-Net "pg_dump.exe est introuvable. Installez les outils PostgreSQL ou ajoutez-les au PATH."
}

$dbHost = if ($env:POSCAISSE_DB_HOST) { $env:POSCAISSE_DB_HOST } else { 'localhost' }
$dbPort = if ($env:POSCAISSE_DB_PORT) { $env:POSCAISSE_DB_PORT } else { '5432' }
$dbName = if ($env:POSCAISSE_DB_NAME) { $env:POSCAISSE_DB_NAME } else { 'poscaisse' }
$dbUser = if ($env:POSCAISSE_DB_USER) { $env:POSCAISSE_DB_USER } else { 'postgres' }
$env:PGPASSWORD = if ($env:POSCAISSE_DB_PASSWORD) { $env:POSCAISSE_DB_PASSWORD } else { 'postgres' }

Etape 'Base a exporter'
Info "$dbUser@${dbHost}:$dbPort/$dbName"
Info "Outil : $pgdump"

$ventes = $AvecLesVentes.IsPresent
if (-not $SansQuestion -and -not $AvecLesVentes) {
  Write-Host ''
  Write-Host '  Faut-il emporter les ventes deja enregistrees ?' -ForegroundColor Yellow
  Write-Host '    N (defaut) : carte, entreprise, utilisateurs et reglages seulement.'
  Write-Host '                 Le client demarre avec un journal vierge, tickets a partir de 1.'
  Write-Host '    O          : copie conforme, vos tickets de test compris.'
  $rep = Read-Host '  Emporter les ventes ? [o/N]'
  $ventes = ($rep -match '^[oOyY]')
}

$suffixe = if ($ventes) { 'complet' } else { 'sans-ventes' }
$fichier = Join-Path $sortie ("poscaisse-" + (Get-Date -Format 'yyyy-MM-dd_HHmm') + "-$suffixe.dump")

$args = @('-h', $dbHost, '-p', $dbPort, '-U', $dbUser, '-d', $dbName, '-Fc', '-f', $fichier)
if (-not $ventes) {
  # --exclude-table-data garde la table et sa structure, mais laisse les lignes de cote :
  # les contraintes de cles etrangeres restent donc satisfaites a la restauration.
  foreach ($t in $tablesDeVentes) { $args += @('--exclude-table-data', "public.$t") }
}

Etape 'Export en cours'
& $pgdump @args
if ($LASTEXITCODE -ne 0 -or -not (Test-Path $fichier)) { Stop-Net "L'export a echoue." }
# pg_dump cree le fichier avant d'ecrire : un echec en cours de route laisse une coquille
# vide, qu'on decouvrirait seulement au moment de restaurer, chez le client.
$octets = (Get-Item $fichier).Length
if ($octets -lt 1024) {
  Remove-Item $fichier -Force -ErrorAction SilentlyContinue
  Stop-Net "L'export n'a rien produit ($octets octets). Verifiez que PostgreSQL tourne et que la base $dbName existe."
}
$taille = [math]::Round($octets / 1KB, 0)

# Ce qu'on vient d'emporter, lu dans la base source : c'est ici qu'on voit si on exporte
# bien la bonne installation, pas apres avoir traverse la ville avec une cle USB.
$psqlExe = Trouver-Outil 'psql.exe'
if ($psqlExe) {
  $r = & $psqlExe -h $dbHost -p $dbPort -U $dbUser -d $dbName -tAc `
    "select coalesce((select coalesce(trade_name, name) from company limit 1), '(aucune)') || '|' || (select count(*) from product) || '|' || (select count(*) from category)"
  $p = ("$r".Trim() -split '\|')
  if ($p.Count -ge 3) {
    Info ""
    Info ("Enseigne exportee : " + $p[0])
    Info ("Articles          : " + $p[1])
    Info ("Categories        : " + $p[2])
    if ($p[0] -match 'FAST FOOD DEMO') {
      Souci ''
      Souci "Cette base contient l'enseigne du jeu de DEMONSTRATION."
      Souci "Verifiez que vous exportez bien l'installation ou vous avez saisi votre carte"
      Souci "(variables POSCAISSE_DB_NAME / POSCAISSE_DB_PORT si vous en utilisez plusieurs)."
    }
  }
}

Etape 'Export termine'
Info "Fichier : $fichier ($taille Ko)"
Info ("Contenu : carte, entreprise, utilisateurs, reglages" + $(if ($ventes) { ", ET les ventes" } else { " (sans les ventes)" }))
Write-Host ''
Info 'Sur le poste du client :'
Info '  1. copiez ce fichier sur la cle USB, a cote du paquet ;'
Info '  2. ARRETER.bat ;'
Info '  3. RESTAURER.bat, et indiquez le chemin du fichier ;'
Info '  4. DEMARRER.bat.'
Souci 'La restauration REMPLACE tout ce que contient la base du poste client.'
