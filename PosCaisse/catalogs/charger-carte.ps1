<#
    Charge une carte complete dans une caisse : articles, ingredients, variante Pate,
    prix par version, et les photos des tuiles.

    Pourquoi un script et non la fiche article : 117 lignes, 86 d'entre elles declinees
    en trois pates, soit 258 prix. A la main, ce n'est pas long : c'est faux. Une
    coquille sur un prix ne se voit qu'au moment ou un client la paie.

    CE QUE LE SCRIPT PRESERVE, ET C'EST TOUT L'ENJEU
    L'import en mode remplacement desactive ce qui ne figure pas dans le fichier. Les
    groupes d'options du poste (supplements, formats) n'y figurent pas : ils sont donc
    RELUS depuis la caisse et re-injectes dans l'envoi, tels quels. Sans cela, un import
    effacerait les supplements que le client utilise tous les jours.

    Seuls les groupes de PAIN sont volontairement laisses de cote : la pate est desormais
    une variante. Les garder demanderait la pate deux fois, et la ferait payer deux fois.
#>
[CmdletBinding()]
param(
  [string] $Url = 'http://127.0.0.1:8080',
  [string] $Utilisateur = 'admin',
  [string] $MotDePasse = '',
  [string] $Fichier = '',
  [string] $Images = '',
  [string] $Supplements = '',
  [switch] $SansRemplacement
)

$ErrorActionPreference = 'Stop'
$ici = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $Fichier) { $Fichier = Join-Path $ici 'number-one-2026.json' }

function Etape($t) { Write-Host ''; Write-Host "== $t" -ForegroundColor Cyan }
function Info($t)  { Write-Host "  $t" -ForegroundColor Green }
function Souci($t) { Write-Host "  $t" -ForegroundColor Yellow }
function Stop-Net($t) { Write-Host ''; Write-Host "ARRET : $t" -ForegroundColor Red; exit 1 }

# PowerShell 5.1 envoie du texte en ISO-8859-1 : << Cereale >> partirait mutile. On envoie
# donc des octets UTF-8, jamais une chaine.
function Appel($methode, $route, $corps) {
  $entetes = @{}
  if ($script:jeton) { $entetes['Authorization'] = 'Bearer ' + $script:jeton }
  $p = @{ Uri = $Url + $route; Method = $methode; Headers = $entetes; UseBasicParsing = $true }
  if ($null -ne $corps) {
    $json = if ($corps -is [string]) { $corps } else { $corps | ConvertTo-Json -Depth 20 -Compress }
    $p['Body'] = [System.Text.Encoding]::UTF8.GetBytes($json)
    $p['ContentType'] = 'application/json; charset=utf-8'
  }
  return Invoke-RestMethod @p
}

if (-not (Test-Path $Fichier)) { Stop-Net "Fichier de carte introuvable : $Fichier" }

Etape 'Connexion a la caisse'
if (-not $MotDePasse) {
  $s = Read-Host "  Mot de passe de << $Utilisateur >>" -AsSecureString
  $MotDePasse = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
                  [Runtime.InteropServices.Marshal]::SecureStringToBSTR($s))
}
try {
  $script:jeton = (Appel 'POST' '/api/auth/login' @{ username = $Utilisateur; password = $MotDePasse }).token
} catch {
  Stop-Net "Connexion refusee. La caisse repond-elle sur $Url, et le mot de passe est-il le bon ?"
}
Info "Connecte en tant que $Utilisateur."

Etape 'Lecture de la carte'
$carte = Get-Content $Fichier -Raw -Encoding UTF8 | ConvertFrom-Json
Info ("{0} : {1} categories, {2} articles, {3} ingredients." -f $carte.label,
      $carte.categories.Count, $carte.products.Count, $carte.ingredients.Count)

Etape 'Options existantes du poste'
$groupes = Appel 'GET' '/api/modifiers' $null
$garder = @()
foreach ($g in $groupes) {
  if ($g.name -match '^\s*Pain') { Souci ("Laisse de cote (la pate est une variante) : " + $g.name); continue }
  $garder += [pscustomobject]@{
    name = $g.name; required = $g.required; multiple = $g.multiple
    minSelect = $g.minSelect; maxSelect = $g.maxSelect
    modifiers = @($g.modifiers | ForEach-Object { [pscustomobject]@{ name = $_.name; priceDelta = $_.priceDelta } })
  }
}
Info ("{0} groupe(s) conserve(s) tel(s) quel(s)." -f $garder.Count)
$carte | Add-Member -NotePropertyName modifierGroups -NotePropertyValue $garder -Force

# Le groupe des supplements, pose sur tout ce qui se mange dans une pate : c'est lui qui
# permet d'ajouter << Mozarilla 3arbi >> a la caisse au lieu de creer un article de plus.
$nomSupp = $Supplements
if (-not $nomSupp) { $nomSupp = ($garder | Where-Object { $_.name -match 'suppl' } | Select-Object -First 1).name }
if ($nomSupp) {
  $horsPate = @('Extras', 'Boissons', 'Lablebi')
  $n = 0
  foreach ($p in $carte.products) {
    if ($horsPate -contains $p.category) { continue }
    $p | Add-Member -NotePropertyName modifierGroups -NotePropertyValue @($nomSupp) -Force
    $n++
  }
  Info ("Groupe << $nomSupp >> pose sur $n article(s).")
} else {
  Souci 'Aucun groupe de supplements trouve : les articles partent sans options.'
  Souci 'Relancez avec -Supplements "<nom exact du groupe>" si le votre porte un autre nom.'
}

Etape 'Envoi de la carte'
$remplacer = if ($SansRemplacement) { 'false' } else { 'true' }
if (-not $SansRemplacement) {
  Write-Host ''
  Write-Host '  Mode REMPLACEMENT : les articles absents de ce fichier seront desactives' -ForegroundColor Yellow
  Write-Host '  (supprimes s ils n ont jamais ete vendus). Les ventes passees sont intactes.' -ForegroundColor Yellow
  if ((Read-Host '  Tapez OUI pour continuer') -ne 'OUI') { Stop-Net 'Abandon : rien n a ete modifie.' }
}
$r = Appel 'POST' ("/api/catalog/import?replace=" + $remplacer) $carte
Info ("Categories : {0} creees, {1} mises a jour." -f $r.categoriesCreated, $r.categoriesUpdated)
Info ("Articles   : {0} crees, {1} mis a jour, {2} desactives." -f $r.productsCreated, $r.productsUpdated, $r.productsDeactivated)
Info ("Ingredients crees : {0}   Variantes creees : {1}" -f $r.ingredientsCreated, $r.variantsCreated)
Info ("Prix a verifier   : {0}  (filtre << Prix a verifier >> dans Back-office > Produits)" -f $r.pricesToCheck)
foreach ($w in $r.warnings) { Souci $w }

if (-not $Images) { Write-Host ''; Info 'Termine. Relancez avec -Images "<dossier>" pour poser les photos.'; exit 0 }

<#
    LES PHOTOS

    Le nom du fichier est le seul lien avec l'article : << Omlette Mozarilla Thon.png >>.
    La comparaison ignore les accents, la casse, les tirets et les espaces multiples, ce
    qui pardonne les ecarts de frappe sans jamais rapprocher deux articles differents.

    Ce qui ne correspond a rien est NOMME, pas ignore en silence : un fichier oublie se
    verrait sinon a la caisse, des mois plus tard, sur la seule tuile restee vide.
#>
Etape 'Photos des tuiles'
if (-not (Test-Path $Images)) { Stop-Net "Dossier d images introuvable : $Images" }
function Cle($s) {
  $t = [Text.NormalizationForm]::FormD
  $n = ($s.Normalize($t).ToCharArray() | Where-Object {
          [Globalization.CharUnicodeInfo]::GetUnicodeCategory($_) -ne 'NonSpacingMark' }) -join ''
  return ($n.ToLower() -replace '[^a-z0-9]', '')
}
$articles = Appel 'GET' '/api/products' $null
$parCle = @{}
foreach ($a in $articles) {
  $k = Cle $a.name
  if (-not $parCle.ContainsKey($k)) { $parCle[$k] = $a }
}
$types = @{ '.png' = 'image/png'; '.jpg' = 'image/jpeg'; '.jpeg' = 'image/jpeg'; '.webp' = 'image/webp'; '.gif' = 'image/gif' }
$poses = 0; $orphelins = @(); $octets = 0
foreach ($f in Get-ChildItem -Path $Images -File) {
  $mime = $types[$f.Extension.ToLower()]
  if (-not $mime) { continue }
  $a = $parCle[(Cle $f.BaseName)]
  if (-not $a) { $orphelins += $f.Name; continue }
  $data = 'data:' + $mime + ';base64,' + [Convert]::ToBase64String([IO.File]::ReadAllBytes($f.FullName))
  Appel 'PUT' ("/api/products/" + $a.id + "/image") @{ imageUrl = $data } | Out-Null
  $poses++; $octets += $f.Length
  Write-Host ("  " + $a.name) -ForegroundColor DarkGray
}
Info ("{0} photo(s) posee(s), {1} Ko au total." -f $poses, [math]::Round($octets / 1KB))
if ($orphelins.Count) {
  Souci ("{0} fichier(s) sans article correspondant :" -f $orphelins.Count)
  foreach ($o in $orphelins) { Souci "    $o" }
}
$sans = @($articles | Where-Object { -not $_.imageUrl }).Count
if ($sans -gt 0) { Souci "$sans article(s) restent sans photo." }
Write-Host ''
Info 'Termine.'
