<#
    Range les quatre familles de sandwichs dans le MEME ordre, celui du menu.

    Classic, Fromage, Mozarilla et Mozarilla 3arbi portent les memes 19 garnitures. En
    caisse, elles ne sont pas rangees pareil : Classic commence par les garnitures
    seules, les trois autres par les omelettes. Sur les tableaux des televiseurs, les
    deux moities d'un meme ecran affichent donc les memes plats dans deux ordres
    differents - et le caissier, lui, ne retrouve pas au meme endroit l'article qu'il
    cherche selon la rubrique ouverte.

    Ce script impose a toutes l'ordre de la rubrique de reference (Classic par defaut).
    Il ne renomme rien, ne change aucun prix, ne touche a aucune photo : il ne pose que
    le rang d'affichage.

    CE QU'IL VERIFIE AVANT D'ECRIRE
    Chaque famille doit porter exactement les memes garnitures que la reference. Si
    l'une en a une de plus ou de moins, le script s'arrete en la nommant plutot que de
    ranger a moitie - un article oublie au fond d'une liste ne se voit pas.

        .\ordonner-carte.ps1 -Simulation     pour voir sans rien changer
        .\ordonner-carte.ps1                 pour appliquer
#>
[CmdletBinding()]
param(
  [string] $Url = 'http://127.0.0.1:8080',
  [string] $Utilisateur = 'admin',
  [string] $MotDePasse = '',
  [string] $Reference = 'Classic',
  [string[]] $Familles = @('Classic', 'Fromage', 'Mozarilla', 'Mozarilla 3arbi'),
  [switch] $Simulation
)

$ErrorActionPreference = 'Stop'

function Etape($t) { Write-Host ''; Write-Host "== $t" -ForegroundColor Cyan }
function Info($t)  { Write-Host "  $t" -ForegroundColor Green }
function Souci($t) { Write-Host "  $t" -ForegroundColor Yellow }
function Stop-Net($t) { Write-Host ''; Write-Host "ARRET : $t" -ForegroundColor Red; exit 1 }

# La reponse est relue octet par octet puis decodee en UTF-8 a la main : Windows
# PowerShell 5.1 decode le JSON en ISO-8859-1 quand l'en-tete ne porte pas de jeu de
# caracteres, et << Escalope Grille >> ressortirait mutile - donc introuvable.
function Appel($methode, $route, $corps) {
  $entetes = @{}
  if ($script:jeton) { $entetes['Authorization'] = 'Bearer ' + $script:jeton }
  $p = @{ Uri = $Url + $route; Method = $methode; Headers = $entetes; UseBasicParsing = $true }
  if ($null -ne $corps) {
    $p['Body'] = [Text.Encoding]::UTF8.GetBytes(($corps | ConvertTo-Json -Depth 10 -Compress))
    $p['ContentType'] = 'application/json; charset=utf-8'
  }
  $r = Invoke-WebRequest @p
  $o = $r.RawContentStream.ToArray()
  if (-not $o.Length) { return $null }
  return ([Text.Encoding]::UTF8.GetString($o) | ConvertFrom-Json)
}

# Le nom d'un article prive de sa famille : << Omlette Mozarilla 3arbi Kwika >>
# redevient << Omlette Kwika >>. C'est par la que les quatre listes se comparent.
function Garniture($nom, $famille) {
  return ($nom -replace [regex]::Escape($famille + ' '), '' -replace [regex]::Escape(' ' + $famille), '').Trim()
}

Etape 'Connexion a la caisse'
if (-not $MotDePasse) {
  $s = Read-Host "  Mot de passe de << $Utilisateur >>" -AsSecureString
  $MotDePasse = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
                  [Runtime.InteropServices.Marshal]::SecureStringToBSTR($s))
}
try {
  $script:jeton = (Appel 'POST' '/api/auth/login' @{ username = $Utilisateur; password = $MotDePasse }).token
} catch {
  Stop-Net "Connexion refusee. La caisse est-elle demarree sur $Url ?"
}
Info "Connecte a $Url"

Etape 'Lecture de la carte'
$carte = Appel 'GET' '/api/pos/catalog' $null
$cats = @($carte.categories)
$arts = @($carte.products)
Info ("{0} categories actives, {1} articles actifs" -f $cats.Count, $arts.Count)

# Les articles de chaque rubrique, dans l'ordre ou la caisse les rend aujourd'hui.
$parCat = @{}
foreach ($c in $cats) { $parCat[$c.name] = @($arts | Where-Object { $_.categoryId -eq $c.id }) }

foreach ($f in $Familles) {
  if (-not $parCat.ContainsKey($f)) { Stop-Net "La rubrique << $f >> n'existe pas dans la caisse." }
}
if ($Familles -notcontains $Reference) { Stop-Net "La reference << $Reference >> ne figure pas dans les familles." }

Etape "Ordre de reference : $Reference"
$ordre = @($parCat[$Reference] | ForEach-Object { Garniture $_.name $Reference })
for ($i = 0; $i -lt $ordre.Count; $i++) { Write-Host ("    {0,2}. {1}" -f ($i + 1), $ordre[$i]) }

Etape 'Controle des quatre familles'
$souci = $false
foreach ($f in $Familles) {
  $g = @($parCat[$f] | ForEach-Object { Garniture $_.name $f })
  $enTrop = @($g | Where-Object { $ordre -notcontains $_ })
  $manque = @($ordre | Where-Object { $g -notcontains $_ })
  if ($enTrop.Count -or $manque.Count) {
    $souci = $true
    Souci ("{0} : {1} garnitures" -f $f, $g.Count)
    if ($manque.Count) { Souci ("    absentes : " + ($manque -join ', ')) }
    if ($enTrop.Count) { Souci ("    en trop  : " + ($enTrop -join ', ')) }
  } else {
    $bouge = 0
    for ($i = 0; $i -lt $ordre.Count; $i++) { if ($g[$i] -ne $ordre[$i]) { $bouge++ } }
    Info ("{0} : {1} garnitures, {2}" -f $f, $g.Count,
          $(if ($bouge) { "$bouge lignes changent de place" } else { 'deja dans l''ordre' }))
  }
}
if ($souci) {
  Stop-Net 'Une famille ne porte pas les memes garnitures que la reference. Rien n''a ete ecrit.'
}

Etape 'Nouvel ordre'
<#
    On renvoie la carte ENTIERE, rubriques dans leur ordre d'affichage. Ne renvoyer que
    les quatre familles laisserait les autres avec leurs anciens rangs, qui se
    melangeraient aux nouveaux ; en numerotant tout d'un coup, de 1 a N, aucun article
    ne peut se retrouver a egalite avec un autre.
#>
$ids = New-Object System.Collections.ArrayList
foreach ($c in $cats) {
  $liste = $parCat[$c.name]
  if ($Familles -contains $c.name) {
    $parGarniture = @{}
    foreach ($a in $liste) { $parGarniture[(Garniture $a.name $c.name)] = $a }
    $liste = @($ordre | ForEach-Object { $parGarniture[$_] })
  }
  foreach ($a in $liste) { [void]$ids.Add($a.id) }
}
Info ("{0} articles numerotes de 1 a {0}" -f $ids.Count)

if ($Simulation) {
  Etape 'Simulation'
  Info 'Rien n''a ete ecrit. Relancez sans -Simulation pour appliquer.'
  exit 0
}

Etape 'Ecriture'
Appel 'POST' '/api/products/reorder' @{ ids = $ids.ToArray() } | Out-Null
Info 'Ordre pose.'

Etape 'Relecture'
$apres = Appel 'GET' '/api/pos/catalog' $null
$ok = $true
foreach ($f in $Familles) {
  $c = @($apres.categories | Where-Object { $_.name -eq $f })[0]
  $g = @($apres.products | Where-Object { $_.categoryId -eq $c.id } | ForEach-Object { Garniture $_.name $f })
  $meme = $true
  for ($i = 0; $i -lt $ordre.Count; $i++) { if ($g[$i] -ne $ordre[$i]) { $meme = $false } }
  if ($meme) { Info ("{0} : conforme" -f $f) } else { $ok = $false; Souci ("{0} : NON conforme" -f $f) }
}
if (-not $ok) { Stop-Net 'La caisse ne rend pas l''ordre demande. Regardez la liste ci-dessus.' }

Etape 'Termine'
Info 'Les quatre familles sont rangees dans le meme ordre.'
Info 'Pensez a re-exporter la carte pour le site et les televiseurs :'
Info '    EXPORTER_CARTE_SITE.bat'
