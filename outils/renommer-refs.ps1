# Renommage des references fabricants dans les quatre societes, en un seul lancement.
#
# A executer SUR LE SERVEUR Business Central, dans une console PowerShell ouverte en
# administrateur. Utilise Invoke-NAVCodeunit, qui lance la codeunit 50032 dans la
# societe demandee sans ouvrir de client.
#
# Par defaut : SIMULATION, rien n'est modifie. Ajouter -Reel pour renommer vraiment.
#
#   .\renommer-refs.ps1                          # simulation sur les 4 societes
#   .\renommer-refs.ps1 -Reel                    # renommage reel
#   .\renommer-refs.ps1 -Societes 'STE COPIM'    # une seule societe
#
# Le detail est ecrit dans la table 50024 "Log Renommage Refs" de chaque societe.
# Le recapitulatif se lit ensuite avec docs\sql\recap-renommage-refs.sql.

param(
    [string]$ServerInstance = 'BC160',
    [string[]]$Societes = @('3S AGENCE', 'SOPIQ PROD', 'STE COPIM', 'STE MPAA PROD'),
    [switch]$Reel,
    [string]$NavAdminTool = 'C:\Program Files\Microsoft Dynamics 365 Business Central\160\Service\NavAdminTool.ps1'
)

$ErrorActionPreference = 'Stop'

if (-not (Get-Command Invoke-NAVCodeunit -ErrorAction SilentlyContinue)) {
    if (-not (Test-Path $NavAdminTool)) {
        throw "NavAdminTool.ps1 introuvable : $NavAdminTool. Indiquer le bon chemin avec -NavAdminTool."
    }
    . $NavAdminTool
}

$methode = if ($Reel) { 'Renommer' } else { 'Simuler' }

if ($Reel) {
    Write-Host 'MODE REEL : les articles vont etre renommes.' -ForegroundColor Yellow
    Write-Host 'Verifier que la sauvegarde de la base est faite et qu aucun utilisateur ne travaille.' -ForegroundColor Yellow
    $reponse = Read-Host 'Taper OUI pour continuer'
    if ($reponse -ne 'OUI') { Write-Host 'Annule.'; return }
} else {
    Write-Host 'MODE SIMULATION : aucune modification, seul le journal est alimente.' -ForegroundColor Cyan
}

$resultats = foreach ($societe in $Societes) {
    Write-Host "-> $societe ($methode)"
    $chrono = [Diagnostics.Stopwatch]::StartNew()
    $erreur = ''
    try {
        Invoke-NAVCodeunit -ServerInstance $ServerInstance -CompanyName $societe -CodeunitId 50032 -MethodName $methode
    } catch {
        $erreur = $_.Exception.Message
        Write-Host "   ECHEC : $erreur" -ForegroundColor Red
    }
    $chrono.Stop()
    [pscustomobject]@{
        Societe = $societe
        Methode = $methode
        Duree   = $chrono.Elapsed.ToString('hh\:mm\:ss')
        Etat    = $(if ($erreur) { 'Echec' } else { 'OK' })
        Erreur  = $erreur
    }
}

$resultats | Format-Table -AutoSize
Write-Host 'Recapitulatif detaille : lancer docs\sql\recap-renommage-refs.sql dans SSMS.'
