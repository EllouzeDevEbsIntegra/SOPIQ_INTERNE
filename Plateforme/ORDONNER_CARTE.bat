@echo off
rem Range les quatre familles de sandwichs dans le meme ordre, celui du menu.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0catalogs\ordonner-carte.ps1" %*
pause
