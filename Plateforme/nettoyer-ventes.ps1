<#
    Remise a zero des ventes, avant la mise en service chez le client.

        powershell -File nettoyer-ventes.ps1

    Ce qui part : tickets, lignes, paiements, remboursements, mouvements de
    caisse, journal, sessions, clotures, reglements de compte (donc les soldes
    clients), compteurs de tickets, stock des pates et son historique, audit.

    Ce qui reste : TOUT le parametrage. Entreprise, points de vente, caisses,
    utilisateurs, categories, articles et menus, options, ingredients,
    variantes et leurs prix, remarques cuisine, moyens de paiement,
    imprimantes, modeles de ticket, clients, livreurs, reglages.

    UNE SAUVEGARDE DE SECURITE est prise avant de toucher a quoi que ce soit.
    Ce n'est pas le fichier a transferer : celui-la se fabrique APRES, une fois la
    base verifiee a l'ecran, avec EXPORTER_DONNEES.bat. Celle-ci n'existe que pour
    revenir en arriere si le nettoyage n'etait pas ce qu'on croyait.

    Compatible Windows PowerShell 5.1.
#>
param([switch] $SansConfirmation)

Set-Location -Path $PSScriptRoot
. "$PSScriptRoot\init-db.ps1"

$dbHost = if ($env:POSCAISSE_DB_HOST) { $env:POSCAISSE_DB_HOST } else { "localhost" }
$dbPort = if ($env:POSCAISSE_DB_PORT) { $env:POSCAISSE_DB_PORT } else { "5432" }
$dbName = if ($env:POSCAISSE_DB_NAME) { $env:POSCAISSE_DB_NAME } else { "poscaisse" }
$dbUser = if ($env:POSCAISSE_DB_USER) { $env:POSCAISSE_DB_USER } else { "postgres" }
$env:PGPASSWORD = if ($env:POSCAISSE_DB_PASSWORD) { $env:POSCAISSE_DB_PASSWORD } else { "postgres" }
$env:PGCLIENTENCODING = "UTF8"

$psql = Get-PsqlPath
if (-not $psql) {
    Write-Host "psql introuvable. Installez les outils clients PostgreSQL, ou lancez ce script" -ForegroundColor Red
    Write-Host "depuis un poste ou psql.exe est dans le PATH." -ForegroundColor Red
    exit 1
}
$pgDump = Join-Path (Split-Path $psql) "pg_dump.exe"

Write-Host ""
Write-Host "  Remise a zero des ventes - base '$dbName' sur $dbHost`:$dbPort"
Write-Host "  --------------------------------------------------------------"

# Le backend tient la base ouverte, et une caisse ouverte disparaitrait sous les
# pieds du caissier. On previent : le nettoyage lui-meme n'en depend pas.
try {
    $reponse = Invoke-WebRequest -Uri "http://localhost:8080/actuator/health" -TimeoutSec 2 -UseBasicParsing -ErrorAction Stop
    if ($reponse) {
        Write-Host "  PosCaisse tourne encore. Arretez-le d'abord (STOP_POS.bat) :" -ForegroundColor Yellow
        Write-Host "  une caisse ouverte a l'ecran disparaitrait pendant que le caissier s'en sert." -ForegroundColor Yellow
        Write-Host ""
    }
} catch { }

if (-not $SansConfirmation) {
    Write-Host "  Les ventes, tickets, paiements, sessions, soldes clients et le stock"
    Write-Host "  seront EFFACES. Le parametrage et la carte sont conserves."
    Write-Host ""
    $reponse = Read-Host "  Tapez OUI pour continuer"
    if ($reponse -ne "OUI") { Write-Host "  Annule."; exit 0 }
}

# ---- sauvegarde de securite -------------------------------------------------
$dossier = Join-Path $PSScriptRoot "sauvegardes"
if (-not (Test-Path $dossier)) { New-Item -ItemType Directory -Path $dossier | Out-Null }
$horodatage = Get-Date -Format "yyyyMMdd-HHmm"
$filet = Join-Path $dossier "$dbName-$horodatage-avant-nettoyage.dump"

if (Test-Path $pgDump) {
    Write-Host ""
    Write-Host "  [1/2] Sauvegarde de securite..."
    # Format archive (-Fc), comme EXPORTER_DONNEES et comme la sauvegarde du paquet
    # client : un seul format dans tout le projet, un seul outil pour le relire.
    & $pgDump -h $dbHost -p $dbPort -U $dbUser -d $dbName -Fc -f $filet
    if ($LASTEXITCODE -ne 0) {
        Write-Host "  La sauvegarde a echoue : on s'arrete AVANT de nettoyer." -ForegroundColor Red
        Write-Host "  Sans filet, un nettoyage ne se rattrape pas." -ForegroundColor Red
        exit 1
    }
    $ko = [math]::Round((Get-Item $filet).Length / 1KB)
    Write-Host "        $filet ($ko Ko)"
} else {
    Write-Host "  pg_dump introuvable : impossible de prendre le filet de securite." -ForegroundColor Red
    Write-Host "  On s'arrete la - un nettoyage sans sauvegarde ne se rattrape pas." -ForegroundColor Red
    exit 1
}

# ---- nettoyage --------------------------------------------------------------
Write-Host ""
Write-Host "  [2/2] Nettoyage..."
& $psql -h $dbHost -p $dbPort -U $dbUser -d $dbName -v ON_ERROR_STOP=1 -f "$PSScriptRoot\nettoyer-ventes.sql"
if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "  ECHEC : la base n'a pas ete modifiee (tout est dans une transaction)." -ForegroundColor Red
    Write-Host "  Le filet de securite reste la : $filet" -ForegroundColor Yellow
    exit 1
}

Write-Host ""
Write-Host "  Termine." -ForegroundColor Green
Write-Host "  Filet de securite : $filet"
Write-Host ""
Write-Host "  ETAPE SUIVANTE : relancez PosCaisse (START_POS.bat), verifiez a l'ecran que la"
Write-Host "  carte, les variantes et les reglages sont bien la, puis fabriquez le fichier a"
Write-Host "  emporter avec EXPORTER_DONNEES.bat (repondre N a la question sur les ventes)."
Write-Host ""
