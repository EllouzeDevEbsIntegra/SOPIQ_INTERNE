<#
    Copie les photos generees vers site\img\ en les renommant comme la page les attend.

    La page cherche site\img\<article-en-minuscules-avec-des-tirets>.png : << Omlette
    Mozarilla Thon >> devient << omlette-mozarilla-thon.png >>. Renommer 110 fichiers a la
    main, c'est en manquer trois, et trois vignettes vides qu'on ne remarquera que des
    mois plus tard.

    Le rapprochement se fait sur le NOM de l'article, accents, casse et ponctuation
    ignores. Un fichier qui ne correspond a rien est NOMME a la fin : mieux vaut une
    liste a relire qu'une photo avalee en silence.

    Exemple :
        .\outils\copier-photos.ps1 -Source 'C:\Users\administrateur\Downloads\image POS\reduit'
#>
[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)] [string] $Source,
  [string] $Destination = '',
  [string] $Carte = ''
)

$ErrorActionPreference = 'Stop'
$site = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
if (-not $Destination) { $Destination = Join-Path $site 'img' }
if (-not $Carte) { $Carte = Join-Path (Split-Path -Parent $site) 'catalogs\number-one-2026.json' }

function Info($t)  { Write-Host "  $t" -ForegroundColor Green }
function Souci($t) { Write-Host "  $t" -ForegroundColor Yellow }
function Stop-Net($t) { Write-Host ''; Write-Host "ARRET : $t" -ForegroundColor Red; exit 1 }

if (-not (Test-Path $Source)) { Stop-Net "Dossier introuvable : $Source" }
if (-not (Test-Path $Carte))  { Stop-Net "Carte introuvable : $Carte" }
New-Item -ItemType Directory -Force -Path $Destination | Out-Null

# Meme regle que le generateur de la page : sans accents, en minuscules, tirets.
function Ardoise([string] $s) {
  $d = $s.Normalize([Text.NormalizationForm]::FormD).ToCharArray() | Where-Object {
         [Globalization.CharUnicodeInfo]::GetUnicodeCategory($_) -ne 'NonSpacingMark' }
  $t = (-join $d).ToLower()
  return (($t -replace '[^a-z0-9]+', '-') -replace '-+', '-').Trim('-')
}

$carte = Get-Content $Carte -Raw -Encoding UTF8 | ConvertFrom-Json
$parCle = @{}
foreach ($p in $carte.products) {
  if ([double] $p.price -le 0) { continue }
  $cible = Ardoise $p.name
  foreach ($nom in @($p.name, $p.shortName)) {
    if (-not $nom) { continue }
    $k = Ardoise $nom
    if (-not $parCle.ContainsKey($k)) { $parCle[$k] = $cible }
  }
}

$copiees = 0; $orphelins = @()
foreach ($f in Get-ChildItem -Path $Source -File) {
  if ($f.Extension.ToLower() -notin @('.png', '.jpg', '.jpeg', '.webp')) { continue }
  $cible = $parCle[(Ardoise $f.BaseName)]
  if (-not $cible) { $orphelins += $f.Name; continue }
  Copy-Item $f.FullName (Join-Path $Destination ($cible + '.png')) -Force
  $copiees++
}

$attendues = ($carte.products | Where-Object { [double] $_.price -gt 0 }).Count
$posees = (Get-ChildItem $Destination -Filter *.png -File | Where-Object { $_.Name -ne 'logo-number-one.png' }).Count
Write-Host ''
Info "$copiees fichier(s) copie(s) dans $Destination"
Info "$posees photo(s) en place sur $attendues articles publies."
if ($orphelins.Count) {
  Souci "$($orphelins.Count) fichier(s) sans article correspondant :"
  foreach ($o in $orphelins) { Souci "    $o" }
}
$manque = @()
foreach ($p in $carte.products) {
  if ([double] $p.price -le 0) { continue }
  if (-not (Test-Path (Join-Path $Destination ((Ardoise $p.name) + '.png')))) { $manque += $p.name }
}
if ($manque.Count) {
  Souci "$($manque.Count) article(s) sans photo (l'initiale s'affichera a la place) :"
  foreach ($m in $manque) { Souci "    $m" }
}
Write-Host ''
Info 'Termine. Ouvrez site\index.html : les photos sont la, sans rien regenerer.'
