<#
    Import d'une carte dans PosCaisse.
        powershell -File import-menu.ps1 [-File catalogs\number-one.json] [-Ajouter]
    Par defaut : remplacement complet du catalogue.
#>
param(
  [string]$File = "catalogs\number-one.json",
  [string]$Url  = $(if ($env:POSCAISSE_PORT) { "http://localhost:$($env:POSCAISSE_PORT)" } else { "http://localhost:8080" }),
  [string]$Pin  = $(if ($env:POSCAISSE_ADMIN_PIN) { $env:POSCAISSE_ADMIN_PIN } else { "9999" }),
  [switch]$Ajouter
)
$ErrorActionPreference = "Stop"
Set-Location -Path $PSScriptRoot
$replace = if ($Ajouter) { "false" } else { "true" }

if (-not (Test-Path $File)) { Write-Host "Fichier introuvable : $File" -ForegroundColor Red; exit 1 }
try { $null = Invoke-RestMethod -Uri "$Url/actuator/health" -TimeoutSec 5 } catch {
  Write-Host "PosCaisse ne repond pas sur $Url - lancez RESTART_POS.bat d'abord." -ForegroundColor Red; exit 1
}

$auth = Invoke-RestMethod -Uri "$Url/api/auth/pin" -Method Post -ContentType 'application/json' `
        -Body (@{ pin = $Pin } | ConvertTo-Json)
if (-not $auth.token) { Write-Host "Connexion administrateur refusee (PIN $Pin)." -ForegroundColor Red; exit 1 }

Write-Host "Import de $File (remplacement : $replace)..."
$bytes = [System.IO.File]::ReadAllBytes((Resolve-Path $File))
$res = Invoke-RestMethod -Uri "$Url/api/catalog/import?replace=$replace" -Method Post `
       -ContentType 'application/json; charset=utf-8' `
       -Headers @{ Authorization = "Bearer $($auth.token)" } -Body $bytes

Write-Host ("  Categories : {0} creees, {1} mises a jour, {2} desactivees" -f $res.categoriesCreated, $res.categoriesUpdated, $res.categoriesDeactivated)
Write-Host ("  Options    : {0} creees, {1} mises a jour" -f $res.groupsCreated, $res.groupsUpdated)
Write-Host ("  Produits   : {0} crees, {1} mis a jour, {2} desactives" -f $res.productsCreated, $res.productsUpdated, $res.productsDeactivated)
foreach ($w in $res.warnings) { Write-Host "  - $w" -ForegroundColor Yellow }
Write-Host "  Carte importee. Rechargez le POS (F5) pour la voir." -ForegroundColor Green
