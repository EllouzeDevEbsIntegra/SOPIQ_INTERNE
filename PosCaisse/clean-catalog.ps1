<#
    Nettoyage definitif du catalogue PosCaisse.
        powershell -File clean-catalog.ps1 [-ResetVentes] [-Force]

    Sans -ResetVentes : supprime les produits inactifs qui n'ont jamais ete
    vendus, ainsi que les categories vides et les groupes d'options orphelins.
    L'historique des tickets n'est pas touche.

    Avec -ResetVentes : efface d'abord TOUTES les donnees de vente (tickets,
    lignes, paiements, remboursements, mouvements, journal, sessions, clotures,
    numerotation), ce qui libere les produits inactifs encore references, puis
    supprime le catalogue inactif. Irreversible : c'est la remise a zero
    d'avant mise en production.

    Une caisse encore ouverte fait echouer -ResetVentes : supprimer sa session
    sous les pieds d'un caissier en train d'encaisser n'a pas de sens. -Force
    passe outre ; en mode interactif la question est posee sur le moment, en
    nommant la caisse et le caissier concernes.
#>
param(
  [string]$Url = $(if ($env:POSCAISSE_PORT) { "http://localhost:$($env:POSCAISSE_PORT)" } else { "http://localhost:8080" }),
  [string]$Pin = $(if ($env:POSCAISSE_ADMIN_PIN) { $env:POSCAISSE_ADMIN_PIN } else { "9999" }),
  [switch]$ResetVentes,
  # Supprime aussi les sessions de caisse ouvertes. En mode interactif, la
  # question est posee au moment ou le serveur refuse, en nommant la caisse.
  [switch]$Force,
  # Pose la question a l'ecran au lieu de lire -ResetVentes (appel depuis
  # CLEAN_CATALOG.bat, qui ne contient volontairement aucune logique).
  [switch]$Interactif,
  [switch]$Pause
)
$ErrorActionPreference = "Stop"
Set-Location -Path $PSScriptRoot

function Quit([int]$code) {
  if ($Pause) { Write-Host ''; Write-Host '  Appuyez sur Entree pour fermer cette fenetre.'; [void](Read-Host) }
  exit $code
}

if ($Interactif) {
  Write-Host '=========================================================='
  Write-Host '  Nettoyage du catalogue PosCaisse'
  Write-Host '=========================================================='
  Write-Host ''
  Write-Host '  Les articles et categories inactifs seront SUPPRIMES, avec'
  Write-Host '  toutes leurs relations (options, composants de menu).'
  Write-Host ''
  Write-Host '  Un article deja vendu ne peut pas etre supprime tant que ses'
  Write-Host "  tickets existent. Repondez V pour effacer aussi TOUT l'historique"
  Write-Host '  des ventes (tickets, paiements, sessions, clotures, numerotation) :'
  Write-Host "  c'est la remise a zero d'avant mise en production. IRREVERSIBLE."
  Write-Host ''
  Write-Host '  Si une caisse est ouverte, le script vous le dira et vous demandera'
  Write-Host '  quoi faire : rien ne sera supprime sans votre accord.'
  Write-Host ''
  $rep = ''
  while ($rep -notmatch '^[CVN]$') {
    $rep = (Read-Host '  [C]atalogue seulement, [V] catalogue + ventes, [N]on').Trim().ToUpper()
  }
  if ($rep -eq 'N') { Write-Host '  Annule.'; Quit 0 }
  $ResetVentes = ($rep -eq 'V')
  Write-Host ''
}

try { $null = Invoke-RestMethod -Uri "$Url/actuator/health" -TimeoutSec 5 } catch {
  Write-Host "PosCaisse ne repond pas sur $Url - lancez RESTART_POS.bat d'abord." -ForegroundColor Red; Quit 1
}

$auth = Invoke-RestMethod -Uri "$Url/api/auth/pin" -Method Post -ContentType 'application/json' `
        -Body (@{ pin = $Pin } | ConvertTo-Json)
if (-not $auth.token) { Write-Host "Connexion administrateur refusee (PIN $Pin)." -ForegroundColor Red; Quit 1 }

$reset = if ($ResetVentes) { "true" } else { "false" }
Write-Host "Nettoyage du catalogue (remise a zero des ventes : $reset)..."

function Invoke-Purge([string]$reset, [string]$force) {
  Invoke-RestMethod -Uri "$Url/api/catalog/purge?resetSales=$reset&force=$force" -Method Post `
                    -Headers @{ Authorization = "Bearer $($auth.token)" }
}

$res = $null
try {
  $res = Invoke-Purge $reset $(if ($Force) { "true" } else { "false" })
} catch {
  # Le backend renvoie un message metier lisible (caisse encore ouverte, par ex.).
  # PowerShell 7 le place dans ErrorDetails ; PowerShell 5.1 laisse le corps
  # dans le flux de reponse. On lit les deux.
  $body = $null
  if ($_.ErrorDetails -and $_.ErrorDetails.Message) { $body = $_.ErrorDetails.Message }
  if (-not $body) {
    try {
      $stream = $_.Exception.Response.GetResponseStream()
      $body = (New-Object System.IO.StreamReader($stream)).ReadToEnd()
    } catch { }
  }
  $msg = $_.Exception.Message
  if ($body) { try { $msg = ($body | ConvertFrom-Json).message } catch { $msg = $body } }

  # Seul refus rattrapable : une caisse ouverte. On montre laquelle et on
  # demande, plutot que de laisser l'utilisateur bloque sans issue.
  if ($Interactif -and $msg -match 'Caisse encore ouverte') {
    Write-Host ''
    Write-Host "  $msg" -ForegroundColor Yellow
    Write-Host ''
    Write-Host '  Cette session sera supprimee avec le reste de l historique.'
    Write-Host '  Ne repondez oui que si personne n encaisse en ce moment.'
    $rep = ''
    while ($rep -notmatch '^[ON]$') { $rep = (Read-Host '  Supprimer aussi la session ouverte ? [O]ui / [N]on').Trim().ToUpper() }
    if ($rep -eq 'N') { Write-Host '  Annule.'; Quit 0 }
    Write-Host ''
    try { $res = Invoke-Purge $reset "true" } catch {
      $b = $null
      if ($_.ErrorDetails -and $_.ErrorDetails.Message) { $b = $_.ErrorDetails.Message }
      $m = $_.Exception.Message
      if ($b) { try { $m = ($b | ConvertFrom-Json).message } catch { $m = $b } }
      Write-Host "  Nettoyage refuse : $m" -ForegroundColor Red
      Quit 1
    }
  } else {
    Write-Host "  Nettoyage refuse : $msg" -ForegroundColor Red
    Quit 1
  }
}

if ($res.salesReset) { Write-Host ("  Ventes     : {0} ligne(s) effacee(s), numerotation des tickets remise a zero" -f $res.salesRowsDeleted) }
Write-Host ("  Produits   : {0} supprime(s), {1} restant(s)" -f $res.productsDeleted, $res.productsLeft)
Write-Host ("  Categories : {0} supprimee(s), {1} restante(s)" -f $res.categoriesDeleted, $res.categoriesLeft)
Write-Host ("  Options    : {0} groupe(s) orphelin(s) supprime(s)" -f $res.groupsDeleted)
foreach ($w in $res.warnings) { Write-Host "  - $w" -ForegroundColor Yellow }
Write-Host "  Base nettoyee. Rechargez le POS (F5)." -ForegroundColor Green
Quit 0
