# Renommage des versions de modele Mercedes de 3S AGENCE : 204002 devient 204.002.
#
# Lance la codeunit 50034 avec Invoke-NAVCodeunit, sans ouvrir de client. Cette commande
# fait partie des outils d'administration Business Central, installes sur le SERVEUR BC et
# pas sur un poste de travail.
#
# Deux facons de lancer :
#   - sur le serveur BC, en PowerShell administrateur :
#       .\renommer-vehicules.ps1
#   - depuis un poste, en passant par le serveur (WinRM doit etre actif) :
#       .\renommer-vehicules.ps1 -Serveur 192.168.1.5
#
# Par defaut : SIMULATION, rien n'est modifie, seul le journal est alimente.
# Ajouter -Reel pour renommer vraiment.
#
#   .\renommer-vehicules.ps1 -Serveur 192.168.1.5              # simulation sur DEV
#   .\renommer-vehicules.ps1 -Serveur 192.168.1.5 -Reel        # renommage sur DEV
#
# Le detail est ecrit dans la table 50024 "Log Renommage Refs" de la societe.
# La lecture se fait ensuite avec docs\sql\controle-renommage-vehicules.sql.
#
# La codeunit refuse de tourner ailleurs qu'en 3S AGENCE : une erreur claire est renvoyee.

param(
    [string]$ServerInstance = 'BC160',
    [string]$Societe = '3S AGENCE',
    [switch]$Reel,
    [string]$Serveur = '',
    [string]$NavAdminTool = '',
    # Un echec sur verrou ne coute que quelques secondes : on retente plus tard.
    [int]$Essais = 20,
    [int]$PauseSecondes = 120
)

$ErrorActionPreference = 'Stop'

$methode = if ($Reel) { 'Renommer' } else { 'Simuler' }

if ($Reel) {
    Write-Host 'MODE REEL : les fiches vont etre renommees.' -ForegroundColor Yellow
    Write-Host 'Verifier que la sauvegarde de la base est faite.' -ForegroundColor Yellow
    $reponse = Read-Host 'Taper OUI pour continuer'
    if ($reponse -ne 'OUI') { Write-Host 'Annule.'; return }
} else {
    Write-Host 'MODE SIMULATION : aucune modification, seul le journal est alimente.' -ForegroundColor Cyan
}

# Ce bloc s'execute la ou sont installes les outils BC : ici, ou sur le serveur distant.
$travail = {
    param($ServerInstance, $Societe, $Methode, $NavAdminTool, $Essais, $PauseSecondes)

    if (-not (Get-Command Invoke-NAVCodeunit -ErrorAction SilentlyContinue)) {
        if (-not $NavAdminTool) {
            $NavAdminTool = Get-ChildItem 'C:\Program Files\Microsoft Dynamics 365 Business Central' `
                                -Filter 'NavAdminTool.ps1' -Recurse -ErrorAction SilentlyContinue |
                            Select-Object -First 1 -ExpandProperty FullName
        }
        if (-not $NavAdminTool -or -not (Test-Path $NavAdminTool)) {
            throw 'Outils d administration BC introuvables sur cette machine. Lancer le script sur le serveur BC, ou utiliser -Serveur.'
        }
        . $NavAdminTool
    }

    # Sans cela, une erreur du serveur BC n'est pas attrapee par try/catch.
    $ErrorActionPreference = 'Stop'

    $chrono = [Diagnostics.Stopwatch]::StartNew()
    $erreur = ''
    $essai = 0

    while ($essai -lt $Essais) {
        $essai++
        $erreur = ''
        try {
            Invoke-NAVCodeunit -ServerInstance $ServerInstance -CompanyName $Societe `
                -CodeunitId 50034 -MethodName $Methode -ErrorAction Stop -WarningAction SilentlyContinue
            break
        } catch {
            $erreur = $_.Exception.Message
            Write-Host "   essai $essai sur $Essais en echec, nouvelle tentative dans $PauseSecondes s"
            if ($essai -lt $Essais) { Start-Sleep -Seconds $PauseSecondes }
        }
    }
    $chrono.Stop()

    [pscustomobject]@{
        Societe = $Societe
        Methode = $Methode
        Essais  = $essai
        Duree   = $chrono.Elapsed.ToString('hh\:mm\:ss')
        Etat    = $(if ($erreur) { 'Echec' } else { 'OK' })
        Erreur  = $erreur
    }
}

if ($Serveur) {
    Write-Host "Execution sur $Serveur ..."
    $resultat = Invoke-Command -ComputerName $Serveur -ScriptBlock $travail `
                    -ArgumentList $ServerInstance, $Societe, $methode, $NavAdminTool, $Essais, $PauseSecondes
} else {
    $resultat = & $travail $ServerInstance $Societe $methode $NavAdminTool $Essais $PauseSecondes
}

$resultat | Format-Table Societe, Methode, Essais, Duree, Etat, Erreur -AutoSize
Write-Host 'Lecture du journal : docs\sql\controle-renommage-vehicules.sql dans SSMS.'
