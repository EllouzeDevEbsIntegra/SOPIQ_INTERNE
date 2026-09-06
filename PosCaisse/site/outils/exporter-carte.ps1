<#
    Exporte la carte TELLE QU'ELLE EST DANS LA CAISSE, pour construire le site.

    Le site ne doit pas etre bati sur le fichier d'import : depuis ce chargement, des
    articles ont ete ajoutes a la main, des noms corriges, des prix rectifies, des photos
    posees, et les categories reordonnees. Le fichier d'import ne sait rien de tout cela.
    La caisse, si.

    Le script demande donc son catalogue a la caisse et l'ecrit tel quel dans
    site\carte-live.json : categories dans leur ordre d'affichage, articles avec leur nom,
    leur prix, leur photo et leurs trois prix de pate, plus les axes de variante et les
    ingredients. Seul l'ACTIF sort - c'est deja ce que la caisse montre au client.

    La reponse est ecrite OCTET POUR OCTET, sans jamais repasser par une chaine
    PowerShell : Windows PowerShell 5.1 decode le JSON en ISO-8859-1 quand l'en-tete ne
    porte pas de jeu de caracteres, et << Escalope Grille >> ressortirait mutile.
#>
[CmdletBinding()]
param(
  [string] $Url = 'http://127.0.0.1:8080',
  [string] $Utilisateur = 'admin',
  [string] $MotDePasse = '',
  [string] $Sortie = ''
)

$ErrorActionPreference = 'Stop'
$ici = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $Sortie) { $Sortie = Join-Path (Split-Path -Parent $ici) 'carte-live.json' }

function Etape($t) { Write-Host ''; Write-Host "== $t" -ForegroundColor Cyan }
function Info($t)  { Write-Host "  $t" -ForegroundColor Green }
function Souci($t) { Write-Host "  $t" -ForegroundColor Yellow }
function Stop-Net($t) { Write-Host ''; Write-Host "ARRET : $t" -ForegroundColor Red; exit 1 }

function Octets($methode, $route, $corps) {
  $entetes = @{}
  if ($script:jeton) { $entetes['Authorization'] = 'Bearer ' + $script:jeton }
  $p = @{ Uri = $Url + $route; Method = $methode; Headers = $entetes; UseBasicParsing = $true }
  if ($null -ne $corps) {
    $p['Body'] = [Text.Encoding]::UTF8.GetBytes(($corps | ConvertTo-Json -Depth 20 -Compress))
    $p['ContentType'] = 'application/json; charset=utf-8'
  }
  return (Invoke-WebRequest @p).RawContentStream.ToArray()
}

Etape 'Connexion a la caisse'
if (-not $MotDePasse) {
  $s = Read-Host "  Mot de passe de << $Utilisateur >>" -AsSecureString
  $MotDePasse = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
                  [Runtime.InteropServices.Marshal]::SecureStringToBSTR($s))
}
try {
  $o = Octets 'POST' '/api/auth/login' @{ username = $Utilisateur; password = $MotDePasse }
  $script:jeton = ([Text.Encoding]::UTF8.GetString($o) | ConvertFrom-Json).token
} catch {
  Stop-Net "Connexion refusee. La caisse est-elle demarree sur $Url ? Mot de passe correct ?"
}
Info "Connecte a $Url"

Etape 'Lecture du catalogue'
$octets = Octets 'GET' '/api/pos/catalog' $null
if (-not $octets.Length) { Stop-Net 'La caisse a repondu vide.' }

# Ecriture BRUTE : ni BOM ni reencodage. Le fichier est exactement ce que la caisse a dit.
[IO.File]::WriteAllBytes($Sortie, $octets)
$carte = [Text.Encoding]::UTF8.GetString($octets) | ConvertFrom-Json
$ko = [math]::Round((Get-Item $Sortie).Length / 1KB)
Info "Ecrit : $Sortie ($ko Ko)"

Etape 'Ce que la caisse contient'
$cats = @($carte.categories)
$arts = @($carte.products)
Info ("{0} categories actives, {1} articles actifs" -f $cats.Count, $arts.Count)
Write-Host ''
foreach ($c in $cats) {
  $n = @($arts | Where-Object { $_.categoryId -eq $c.id }).Count
  Write-Host ("    {0,-28} {1,3} article(s)" -f $c.name, $n)
}

$sansPhoto = @($arts | Where-Object { -not $_.imageUrl })
$prixZero  = @($arts | Where-Object { [double]$_.price -eq 0 })
$aVerifier = @($arts | Where-Object { $_.priceToCheck })
$declines  = @($arts | Where-Object { $_.variantId })

Write-Host ''
Info ("{0} articles declines (variante), {1} avec photo" -f $declines.Count, ($arts.Count - $sansPhoto.Count))
if ($sansPhoto.Count) {
  Souci ("{0} articles SANS photo :" -f $sansPhoto.Count)
  foreach ($a in $sansPhoto) { Write-Host ("      - " + $a.name) }
}
if ($prixZero.Count) {
  Souci ("{0} articles a 0,000 - a tarifer avant le site :" -f $prixZero.Count)
  foreach ($a in $prixZero) { Write-Host ("      - " + $a.name) }
}
if ($aVerifier.Count) { Souci ("{0} articles portent encore le drapeau << prix a verifier >>." -f $aVerifier.Count) }

Etape 'Etape suivante'
Info 'Envoyez ce fichier en le poussant sur le depot :'
Info ''
Info '    git add PosCaisse/site/carte-live.json'
Info '    git commit -m "Carte du poste, pour le site"'
Info '    git push'
