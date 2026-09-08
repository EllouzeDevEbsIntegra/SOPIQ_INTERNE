<#
    Prepare la base PosCaisse : localise psql, attend PostgreSQL, cree la base
    si elle n'existe pas. Utilisable seul ou importe par restart.ps1.
        powershell -File init-db.ps1
    Compatible Windows PowerShell 5.1 (aucune syntaxe PowerShell 7).
#>
function Get-PsqlPath {
    $cmd = Get-Command psql.exe -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    foreach ($v in 18, 17, 16, 15, 14, 13, 12) {
        $p = "C:\Program Files\PostgreSQL\$v\bin\psql.exe"
        if (Test-Path $p) { return $p }
    }
    return $null
}

function Start-PostgresService {
    if (Get-Command docker -ErrorAction SilentlyContinue) {
        docker info 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0 -and (Test-Path "docker-compose.yml")) {
            docker compose up -d postgres 2>&1 | Out-Null
            Write-Host "    PostgreSQL demarre via Docker."
            return
        }
    }
    Get-Service -Name "postgresql*" -ErrorAction SilentlyContinue |
        Where-Object { $_.Status -ne 'Running' } |
        ForEach-Object { try { Start-Service $_.Name -ErrorAction Stop } catch {} }
}

function Ensure-Database {
    $dbHost = if ($env:POSCAISSE_DB_HOST) { $env:POSCAISSE_DB_HOST } else { "localhost" }
    $dbPort = if ($env:POSCAISSE_DB_PORT) { $env:POSCAISSE_DB_PORT } else { "5432" }
    $dbName = if ($env:POSCAISSE_DB_NAME) { $env:POSCAISSE_DB_NAME } else { "poscaisse" }
    $dbUser = if ($env:POSCAISSE_DB_USER) { $env:POSCAISSE_DB_USER } else { "postgres" }
    $env:PGPASSWORD = if ($env:POSCAISSE_DB_PASSWORD) { $env:POSCAISSE_DB_PASSWORD } else { "postgres" }
    $env:PGCLIENTENCODING = "UTF8"

    $psql = Get-PsqlPath
    if (-not $psql) {
        Write-Host "    psql introuvable : verification automatique impossible." -ForegroundColor Yellow
        Write-Host "    Si le backend signale que la base n'existe pas, creez-la avec pgAdmin ou :"
        Write-Host "       psql -U $dbUser -c ""CREATE DATABASE $dbName;"""
        return $false
    }

    $ready = $false
    for ($i = 0; $i -lt 20; $i++) {
        & $psql -h $dbHost -p $dbPort -U $dbUser -d postgres -tAc "SELECT 1" 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) { $ready = $true; break }
        Start-Sleep -Seconds 2
    }
    if (-not $ready) {
        Write-Host "    PostgreSQL ne repond pas (service arrete, port different ou mot de passe incorrect)." -ForegroundColor Red
        return $false
    }

    $found = & $psql -h $dbHost -p $dbPort -U $dbUser -d postgres -tAc "SELECT 1 FROM pg_database WHERE datname='$dbName'" 2>$null
    if ("$found".Trim() -eq "1") { Write-Host "    Base '$dbName' prete."; return $true }

    Write-Host "    Base absente : creation de '$dbName'..."
    & $psql -h $dbHost -p $dbPort -U $dbUser -d postgres -c "CREATE DATABASE $dbName;" 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) { Write-Host "    Base creee. Flyway construira le schema au demarrage."; return $true }
    Write-Host "    Creation impossible (droits insuffisants ?). Creez-la manuellement." -ForegroundColor Red
    return $false
}

# Execution directe (et non simple import par restart.ps1)
if ($MyInvocation.InvocationName -ne '.') {
    Set-Location -Path $PSScriptRoot
    Start-PostgresService
    if (Ensure-Database) { exit 0 } else { exit 1 }
}
