<#
    Remet chaque article a la couleur de sa rubrique.

    La tuile d'un article se colore ainsi : sa propre couleur si elle est renseignee,
    celle de sa rubrique sinon. Une couleur VIDE ne veut donc pas dire << gris >>, elle
    veut dire << celle de ma rubrique >> - et l'article suit sa rubrique partout, y
    compris le jour ou on le deplace ailleurs.

    Ce script vide la couleur des articles. Ils prennent aussitot celle de leur rubrique,
    et la garderont a jour toute seule.

    POURQUOI C'EST UTILE ICI
    L'import de la carte avait pose une couleur EN DUR sur chaque article - deux teintes
    par rubrique, dont une empruntee a une autre rubrique. Sur l'ecran de vente, la
    couleur ne disait donc plus rien, et un article deplace serait reste peint aux
    couleurs de son ancienne rubrique.

    IL NE TOUCHE A RIEN D'AUTRE : ni nom, ni prix, ni photo, ni options, ni variante -
    chaque article est renvoye tel quel, sa seule couleur changee. Et il relit la carte
    apres coup pour verifier.

        .\couleur-heritee.ps1 -Simulation     pour voir sans rien changer
        .\couleur-heritee.ps1                 pour appliquer
#>
[CmdletBinding()]
param(
  [string] $Url = 'http://127.0.0.1:8080',
  [string] $Utilisateur = 'admin',
  [string] $MotDePasse = '',
  [string[]] $Rubriques = @(),          # vide = toutes
  [switch] $Simulation
)

$ErrorActionPreference = 'Stop'

function Etape($t) { Write-Host ''; Write-Host "== $t" -ForegroundColor Cyan }
function Info($t)  { Write-Host "  $t" -ForegroundColor Green }
function Souci($t) { Write-Host "  $t" -ForegroundColor Yellow }
function Stop-Net($t) { Write-Host ''; Write-Host "ARRET : $t" -ForegroundColor Red; exit 1 }

# Reponse relue octet par octet puis decodee en UTF-8 : PowerShell 5.1 decode le JSON en
# ISO-8859-1 quand l'en-tete ne porte pas de jeu de caracteres, et les noms accentues
# ressortiraient mutiles - donc reecrits mutiles.
function Appel($methode, $route, $corps) {
  $entetes = @{}
  if ($script:jeton) { $entetes['Authorization'] = 'Bearer ' + $script:jeton }
  $p = @{ Uri = $Url + $route; Method = $methode; Headers = $entetes; UseBasicParsing = $true }
  if ($null -ne $corps) {
    $p['Body'] = [Text.Encoding]::UTF8.GetBytes(($corps | ConvertTo-Json -Depth 20 -Compress))
    $p['ContentType'] = 'application/json; charset=utf-8'
  }
  $r = Invoke-WebRequest @p
  $o = $r.RawContentStream.ToArray()
  if (-not $o.Length) { return $null }
  return ([Text.Encoding]::UTF8.GetString($o) | ConvertFrom-Json)
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
$cats = @{}
foreach ($c in $carte.categories) { $cats[[string] $c.id] = $c }
$arts = @($carte.products)
if ($Rubriques.Count) {
  $ids = @($carte.categories | Where-Object { $Rubriques -contains $_.name } | ForEach-Object { $_.id })
  if (-not $ids.Count) { Stop-Net "Aucune des rubriques demandees n'existe : $($Rubriques -join ', ')" }
  $arts = @($arts | Where-Object { $ids -contains $_.categoryId })
}
Info ("{0} articles concernes" -f $arts.Count)

Etape 'Ce qui va changer'
$aFaire = @($arts | Where-Object { $_.color })
$deja = $arts.Count - $aFaire.Count
foreach ($c in $carte.categories) {
  $n = @($aFaire | Where-Object { $_.categoryId -eq $c.id }).Count
  if ($n) { Info ("{0,-18} {1,3} article(s) reprennent {2}" -f $c.name, $n, $c.color) }
}
if ($deja) { Info "$deja article(s) heritaient deja de leur rubrique." }
if (-not $aFaire.Count) { Etape 'Rien a faire'; Info 'Tous les articles heritent deja.'; exit 0 }

if ($Simulation) {
  Etape 'Simulation'
  Info "$($aFaire.Count) article(s) SERAIENT remis a l'heritage. Rien n'a ete ecrit."
  Info 'Relancez sans -Simulation pour appliquer.'
  exit 0
}

Etape 'Ecriture'
<#
    Chaque article est renvoye ENTIER : la caisse remplace la fiche, elle ne la corrige
    pas. Omettre un champ l'effacerait - les options, les ingredients, les prix de
    variante. On repart donc de ce que la caisse vient de rendre, et on ne change que la
    couleur.
#>
$faits = 0
foreach ($a in $aFaire) {
  $requete = @{
    code = $a.code; reference = $a.reference; name = $a.name; shortName = $a.shortName
    description = $a.description; categoryId = $a.categoryId; productType = $a.productType
    price = $a.price; taxRate = $a.taxRate; imageUrl = $a.imageUrl
    color = ''                                   # vide = celle de la rubrique
    sortOrder = $a.sortOrder; active = $a.active; available = $a.available
    favorite = $a.favorite; favoriteOrder = $a.favoriteOrder; priceToCheck = $a.priceToCheck
    printDestinationIds = @($a.printDestinationIds)
    modifierGroupIds = @($a.modifierGroups | ForEach-Object { $_.id })
    menuComponents = @($a.menuComponents | ForEach-Object {
        @{ name = $_.name; quantity = $_.quantity; sortOrder = $_.sortOrder
           options = @($_.options | ForEach-Object { @{ productId = $_.productId; priceDelta = $_.priceDelta } }) } })
    ingredientIds = @($a.ingredientIds)
    variantId = $a.variantId; defaultVariantValueId = $a.defaultVariantValueId
    askVariant = $a.askVariant
    variantPrices = @($a.variantPrices | ForEach-Object { @{ variantValueId = $_.variantValueId; price = $_.price } })
  }
  Appel 'PUT' ("/api/products/" + $a.id) $requete | Out-Null
  $faits++
}
Info "$faits article(s) remis a l'heritage."

Etape 'Relecture'
$apres = Appel 'GET' '/api/pos/catalog' $null
$avant = @{}
foreach ($a in $arts) { $avant[[string] $a.id] = $a }
$restent = 0; $perdus = @()
foreach ($a in $apres.products) {
  $v = $avant[[string] $a.id]
  if ($null -eq $v) { continue }
  if ($a.color) { $restent++ }
  # Ce qui ne devait pas bouger, et qu'une fiche renvoyee incomplete aurait efface.
  if ($a.price -ne $v.price -or $a.imageUrl -ne $v.imageUrl -or
      @($a.modifierGroups).Count -ne @($v.modifierGroups).Count -or
      @($a.variantPrices).Count -ne @($v.variantPrices).Count -or
      @($a.ingredientIds).Count -ne @($v.ingredientIds).Count) { $perdus += $a.name }
}
if ($restent) { Souci "$restent article(s) portent encore une couleur propre." }
else          { Info 'Tous les articles concernes heritent de leur rubrique.' }
if ($perdus.Count) {
  Souci "$($perdus.Count) article(s) ont perdu autre chose que leur couleur :"
  foreach ($n in $perdus) { Souci "    $n" }
  Stop-Net 'Verifiez ces articles dans le back-office.'
}
Info 'Prix, photos, options, ingredients et prix de variante inchanges.'

Etape 'Termine'
Info 'La couleur d''une tuile suit desormais sa rubrique.'
Info 'Pour peindre un article a part : sa fiche, << Couleur de la tuile >>.'
Info 'Pour revenir a l''heritage : la pastille << Categorie >>.'
