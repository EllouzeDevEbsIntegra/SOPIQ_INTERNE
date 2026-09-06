@echo off
rem  Fins de ligne CRLF imposees par .gitattributes (exigence de cmd.exe).
setlocal
title PosCaisse - Chargement de la carte 2026
cd /d "%~dp0"
echo ==========================================================
echo   Carte NUMBER ONE 2026 : articles, variante Pate, photos
echo ==========================================================
echo.
echo   Fichier : catalogs\number-one-2026.json
echo.
echo   Les groupes d'options du poste sont RELUS et conserves.
echo   Seuls les groupes de PAIN sont ecartes : la pate est
echo   desormais une variante, la demander deux fois la ferait
echo   payer deux fois.
echo.
echo   Les articles absents du fichier seront desactivies ;
echo   ceux jamais vendus, supprimes. Les ventes restent intactes.
echo.
set "dossier="
set /p dossier=  Dossier des photos (Entree pour ne pas en poser) : 
echo.
if defined dossier (
  powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0catalogs\charger-carte.ps1" -Images "%dossier%"
) else (
  powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0catalogs\charger-carte.ps1"
)
echo.
echo   Code de sortie : %errorlevel%
pause
