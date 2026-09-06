<#
    Pose le prix des pates DOUBLES sur tous les articles qui portent l'axe << Pate >>.

    Le gerant a ajoute les valeurs a l'ecran ; il reste a leur donner un prix sur
    chacun des 86 articles declines, soit 258 saisies. A la main ce n'est pas long :
    c'est faux, et une erreur de prix ne se voit qu'au moment ou un client la paie.

    LA REGLE, telle qu'elle a ete donnee :
        Double Normale = Normale + 1,000
        Double Cereale = Cereale + 1,000
        Double Chia    = Chia    + 1,500

    Le prix de la pate simple sert de base. Un article dont la pate simple n'a pas de
    prix est LAISSE DE COTE et nomme a la fin : deviner un prix a partir de rien
    donnerait un tarif faux qui aurait l'air juste.

    Exemple :
        .\catalogs\prix-double-pate.ps1
#>
[CmdletBinding()]
param(
  [string] $Url = 'http://127.0.0.1:8080',
  [string] $Utilisateur = 'admin',
  [string] $MotDePasse = '',
  [decimal] $SupplementNormale = 1.0,
  [decimal] $SupplementCereale = 1.0,
  [decimal] $SupplementChia = 1.5,
  [switch] $Simulation
)

$ErrorActionPreference = 'Stop'
function Etape($t) { Write-Host ''; Write-Host "== $t" -ForegroundColor Cyan }
function Info($t)  { Write-Host "  $t" -ForegroundColor Green }
function Souci($t) { Write-Host "  $t" -ForegroundColor Yellow }
function Stop-Net($t) { Write-Host ''; Write-Host "ARRET : $t" -ForegroundColor Red; exit 1 }

<#
    Les reponses sont relues octet par octet puis decodees en UTF-8 : sous Windows
    PowerShell 5.1, Invoke-RestMethod decode le JSON en ISO-8859-1 quand l'en-tete ne
    porte pas le jeu de caracteres. << Pate >> et << Cereale >> reviendraient mutiles,
    et ce script les compare par leur nom.
#>
function Appel($methode, $route, $corps) {
  $entetes = @{}
  if ($script:jeton) { $entetes['Authorization'] = 'Bearer ' + $script:jeton }
  $p = @{ Uri = $Url + $route; Method = $methode; Headers = $entetes; UseBasicParsing = $true }
  if ($null -ne $corps) {
    $p['Body'] = [Text.Encoding]::UTF8.GetBytes(($corps | ConvertTo-Json -Depth 20 -Compress))
    $p['ContentType'] = 'application/json; charset=utf-8'
  }
  $r = Invoke-WebRequest @p
  $octets = $r.RawContentStream.ToArray()
  if (-not $octets.Length) { return $null }
  return ([Text.Encoding]::UTF8.GetString($octets) | ConvertFrom-Json)
}

# Sans accents ni espaces : les noms sont compares par leur forme nue.
$accents = -join (@(224,225,226,227,228,229,231,232,233,234,235,236,237,238,239,241,
                    242,243,244,245,246,249,250,251,252,253,255) | ForEach-Object { [char] $_ })
$nus     = 'aaaaaaceeeeiiiinooooouuuuyy'
function Nu([string] $s) {
  $b = New-Object Text.StringBuilder
  foreach ($c in ([string] $s).ToLower().ToCharArray()) {
    $i = $accents.IndexOf($c)
    [void] $b.Append($(if ($i -ge 0) { $nus[$i] } else { $c }))
  }
  return $b.ToString()
}
function Mot([string] $s) { return (Nu $s) -replace '[^a-z0-9]', '' }

Etape 'Connexion a la caisse'
if (-not $MotDePasse) {
  $s = Read-Host "  Mot de passe de << $Utilisateur >>" -AsSecureString
  $MotDePasse = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
                  [Runtime.InteropServices.Marshal]::SecureStringToBSTR($s))
}
try { $script:jeton = (Appel 'POST' '/api/auth/login' @{ username = $Utilisateur; password = $MotDePasse }).token }
catch { Stop-Net "Connexion refusee. La caisse repond-elle sur $Url, et le mot de passe est-il le bon ?" }
Info "Connecte en tant que $Utilisateur."

Etape 'Valeurs de l axe'
$axe = Appel 'GET' '/api/variants' $null | Where-Object { (Nu $_.name) -like 'pate*' } | Select-Object -First 1
if (-not $axe) { Stop-Net "Aucun axe de variante nomme << Pate >>." }

<#
    Rapprocher une pate double de sa pate simple par le NOM, sans exiger que le gerant
    ait ecrit exactement ce que le script attend.

    Le nom est reduit a son mot utile : on retire << double >> et << pate >>, les
    accents, les espaces, puis on ramene les formes voisines a une seule -
    Normal / Normale, Cereale / Cereales - parce que celui qui saisit ecrit ce qui lui
    vient, et qu'il a raison : c'est au script de s'adapter.
#>
function Canon([string] $nom) {
  $x = (Nu $nom) -replace 'double', '' -replace 'pates', '' -replace 'pate', ''
  $x = $x -replace '[^a-z0-9]', ''
  if ($x -like 'normal*')  { return 'normale' }
  if ($x -like 'cereal*')  { return 'cereale' }
  if ($x -like '*chia*')   { return 'chia' }
  return $x
}
$supplements = @{ 'normale' = $SupplementNormale; 'cereale' = $SupplementCereale; 'chia' = $SupplementChia }

$simples = @{}; $doubles = @{}
Write-Host ''
Write-Host '  Valeurs de l axe, telles qu elles sont enregistrees :' -ForegroundColor DarkGray
foreach ($v in $axe.values) {
  $cle = Canon $v.name
  $estDouble = (Nu $v.name) -match 'double'
  $etat = if ($v.active) { '' } else { '  (eteinte)' }
  Write-Host ("      {0,-26} {1,-8} -> {2}{3}" -f $v.name, $(if ($estDouble) { 'double' } else { 'simple' }), $cle, $etat) -ForegroundColor DarkGray
  if (-not $v.active) { continue }
  if ($estDouble) { $doubles[$cle] = $v } elseif (-not $simples.ContainsKey($cle)) { $simples[$cle] = $v }
}

$paires = @()
foreach ($k in $doubles.Keys) {
  if (-not $simples.ContainsKey($k)) { Souci "<< $($doubles[$k].name) >> : aucune pate simple ne se ramene a << $k >>."; continue }
  if (-not $supplements.ContainsKey($k)) { Souci "<< $($doubles[$k].name) >> : aucun supplement connu pour << $k >>."; continue }
  $paires += [pscustomobject]@{ Simple = $simples[$k]; Double = $doubles[$k]; Supplement = $supplements[$k] }
}
if (-not $paires.Count) { Stop-Net "Aucune paire << pate simple / pate double >> trouvee. La liste ci-dessus dit ce que le script a lu." }
Write-Host ''
foreach ($p in $paires) { Info ("{0,-22} + {1,-5} -> {2}" -f $p.Simple.name, $p.Supplement, $p.Double.name) }

Etape 'Articles'
$produits = Appel 'GET' '/api/products' $null
$faits = 0; $sansPrix = @()
foreach ($a in $produits) {
  if ($a.variantId -ne $axe.id) { continue }

  # On repart de la grille existante en ignorant les valeurs eteintes - non pour les
  # effacer (la caisse recree une ligne a zero pour CHAQUE valeur de l'axe, c'est ainsi
  # qu'une valeur ajoutee apres coup apparait grisee), mais pour ne jamais s'appuyer sur
  # le prix d'une pate qui n'est plus vendue.
  $vivantes = @{}
  foreach ($v in $axe.values) { if ($v.active) { $vivantes[[string] $v.id] = $true } }
  $grille = @{}
  foreach ($x in $a.variantPrices) { if ($vivantes.ContainsKey([string] $x.variantValueId)) { $grille[[string] $x.variantValueId] = [decimal] $x.price } }

  $change = $false
  foreach ($p in $paires) {
    $base = $grille[[string] $p.Simple.id]
    if ($null -eq $base -or $base -le 0) { continue }
    $grille[[string] $p.Double.id] = $base + $p.Supplement
    $change = $true
  }
  if (-not $change) { $sansPrix += $a.name; continue }

  $prix = @()
  foreach ($k in $grille.Keys) { $prix += @{ variantValueId = [long] $k; price = $grille[$k] } }

  if ($Simulation) { $faits++; continue }
  $requete = @{
    code = $a.code; reference = $a.reference; name = $a.name; shortName = $a.shortName
    description = $a.description; categoryId = $a.categoryId; productType = $a.productType
    price = $a.price; taxRate = $a.taxRate; imageUrl = $a.imageUrl; color = $a.color
    sortOrder = $a.sortOrder; active = $a.active; available = $a.available
    favorite = $a.favorite; favoriteOrder = $a.favoriteOrder; priceToCheck = $a.priceToCheck
    printDestinationIds = @($a.printDestinationIds)
    modifierGroupIds = @($a.modifierGroups | ForEach-Object { $_.id })
    menuComponents = @($a.menuComponents | ForEach-Object {
        @{ name = $_.name; quantity = $_.quantity; sortOrder = $_.sortOrder
           options = @($_.options | ForEach-Object { @{ productId = $_.productId; priceDelta = $_.priceDelta } }) } })
    ingredientIds = @($a.ingredientIds)
    variantId = $a.variantId; defaultVariantValueId = $a.defaultVariantValueId
    askVariant = $a.askVariant; variantPrices = $prix
  }
  Appel 'PUT' ("/api/products/" + $a.id) $requete | Out-Null
  $faits++
}

Write-Host ''
if ($Simulation) { Info "$faits article(s) SERAIENT tarifes (simulation : rien n a ete ecrit)." }
else             { Info "$faits article(s) tarifes." }
if ($sansPrix.Count) {
  Souci "$($sansPrix.Count) article(s) laisse(s) de cote, faute de prix sur la pate simple :"
  foreach ($n in $sansPrix) { Souci "    $n" }
}

Etape 'Verification'
$noms = @{}; foreach ($v in $axe.values) { $noms[[string] $v.id] = $v.name }
foreach ($code in @('G-01', 'OMZ-03')) {
  $a = (Appel 'GET' '/api/products' $null) | Where-Object { $_.code -eq $code } | Select-Object -First 1
  if (-not $a) { continue }
  Write-Host ''
  Write-Host ("  " + $a.code + "  " + $a.name) -ForegroundColor White
  foreach ($x in ($a.variantPrices | Sort-Object price)) {
    Write-Host ("      {0,-22} {1,8:0.000}" -f $noms[[string] $x.variantValueId], $x.price) -ForegroundColor DarkGray
  }
}
Write-Host ''
Info 'Termine.'
