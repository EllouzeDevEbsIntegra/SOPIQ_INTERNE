# Renommage des references fabricants dans les quatre societes, en un seul lancement.
#
# Utilise Invoke-NAVCodeunit, qui lance la codeunit 50032 dans la societe demandee sans
# ouvrir de client. Cette commande fait partie des outils d'administration Business
# Central, installes sur le SERVEUR BC et pas sur un poste de travail.
#
# Deux facons de lancer :
#   - sur le serveur BC, en PowerShell administrateur :
#       .\renommer-refs.ps1
#   - depuis un poste, en passant par le serveur (WinRM doit etre actif) :
#       .\renommer-refs.ps1 -Serveur 192.168.1.4
#
# Par defaut : SIMULATION, rien n'est modifie. Ajouter -Reel pour renommer vraiment.
#
#   .\renommer-refs.ps1 -Reel                    # renommage reel, confirmation demandee
#   .\renommer-refs.ps1 -Societes 'STE COPIM'    # une seule societe
#   .\renommer-refs.ps1 -Vitesco -Reel           # essai sur Vitesco seul, 36 references
#
# Si les outils d'administration ne sont accessibles nulle part, le report 25006155
# fait la meme chose depuis le client BC, une societe a la fois.
#
# Le detail est ecrit dans la table 50024 "Log Renommage Refs" de chaque societe.
# Le recapitulatif se lit ensuite avec docs\sql\recap-renommage-refs.sql.

param(
    [string]$ServerInstance = 'BC160',
    [string[]]$Societes = @('3S AGENCE', 'SOPIQ PROD', 'STE COPIM', 'STE MPAA PROD'),
    [switch]$Reel,
    [switch]$Vitesco,
    [string]$Serveur = '',
    [string]$NavAdminTool = ''
)

$ErrorActionPreference = 'Stop'

$methode = if ($Reel) { 'Renommer' } else { 'Simuler' }
if ($Vitesco) { $methode += 'Vitesco' }

if ($Reel) {
    Write-Host 'MODE REEL : les articles vont etre renommes.' -ForegroundColor Yellow
    Write-Host 'Verifier que la sauvegarde de la base est faite et qu aucun utilisateur ne travaille.' -ForegroundColor Yellow
    $reponse = Read-Host 'Taper OUI pour continuer'
    if ($reponse -ne 'OUI') { Write-Host 'Annule.'; return }
} else {
    Write-Host 'MODE SIMULATION : aucune modification, seul le journal est alimente.' -ForegroundColor Cyan
}

# Ce bloc s'execute la ou sont installes les outils BC : ici, ou sur le serveur distant.
$travail = {
    param($ServerInstance, $Societes, $Methode, $NavAdminTool)

    if (-not (Get-Command Invoke-NAVCodeunit -ErrorAction SilentlyContinue)) {
        if (-not $NavAdminTool) {
            $NavAdminTool = Get-ChildItem 'C:\Program Files\Microsoft Dynamics 365 Business Central' `
                                -Filter 'NavAdminTool.ps1' -Recurse -ErrorAction SilentlyContinue |
                            Select-Object -First 1 -ExpandProperty FullName
        }
        if (-not $NavAdminTool -or -not (Test-Path $NavAdminTool)) {
            throw 'Outils d administration BC introuvables sur cette machine. Lancer le script sur le serveur BC, utiliser -Serveur 192.168.1.4, ou lancer le report 25006155 dans chaque societe.'
        }
        . $NavAdminTool
    }

    # Sans cela, une erreur du serveur BC (verrou, par exemple) n'est pas attrapee par
    # try/catch et interrompt tout le script au lieu de passer a la societe suivante.
    $ErrorActionPreference = 'Stop'

    foreach ($societe in $Societes) {
        $chrono = [Diagnostics.Stopwatch]::StartNew()
        $erreur = ''
        try {
            Invoke-NAVCodeunit -ServerInstance $ServerInstance -CompanyName $societe `
                -CodeunitId 50032 -MethodName $Methode -ErrorAction Stop -WarningAction SilentlyContinue
        } catch {
            $erreur = $_.Exception.Message
        }
        $chrono.Stop()
        [pscustomobject]@{
            Societe = $societe
            Methode = $Methode
            Duree   = $chrono.Elapsed.ToString('hh\:mm\:ss')
            Etat    = $(if ($erreur) { 'Echec' } else { 'OK' })
            Erreur  = $erreur
        }
    }
}

if ($Serveur) {
    Write-Host "Execution sur $Serveur ..."
    $resultats = Invoke-Command -ComputerName $Serveur -ScriptBlock $travail `
                     -ArgumentList $ServerInstance, $Societes, $methode, $NavAdminTool
} else {
    $resultats = & $travail $ServerInstance $Societes $methode $NavAdminTool
}

$resultats | Format-Table Societe, Methode, Duree, Etat, Erreur -AutoSize
Write-Host 'Recapitulatif detaille : lancer docs\sql\recap-renommage-refs.sql dans SSMS.'
