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
  [switch] $SansRemplacement,
  [switch] $PhotosSeulement,
  [int] $TaillePhoto = 240,
  [int] $QualitePhoto = 78
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
  <#
      La reponse est relue OCTET PAR OCTET, puis decodee en UTF-8 a la main.

      Invoke-RestMethod, sous Windows PowerShell 5.1, decode le JSON en ISO-8859-1
      quand l'en-tete ne porte pas explicitement le jeu de caracteres. Les noms
      revenaient donc mutiles - << Escalope Grille >> devenait << Escalope GrillA(c) >> -
      et se comparaient a la carte, elle correctement lue depuis le fichier. Les deux
      ne se rejoignaient jamais : c'est ce qui laissait orphelines les dix photos
      d'escalope, les seuls articles accentues.

      Le defaut est INVISIBLE : rien n'echoue, les noms sont simplement faux.
  #>
  $r = Invoke-WebRequest @p
  $octets = $r.RawContentStream.ToArray()
  if (-not $octets.Length) { return $null }
  return ([Text.Encoding]::UTF8.GetString($octets) | ConvertFrom-Json)
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

if ($PhotosSeulement) {
  Info 'Carte laissee telle quelle : on ne pose que les photos.'
  if (-not $Images) { Stop-Net 'Indiquez -Images "<dossier>" avec -PhotosSeulement.' }
} else {

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
}

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

<#
    Sans accents, en minuscules.

    La voie savante - normaliser en FormD puis jeter les marques - a echoue en clair
    sur ce poste : << Escalope Grille >> et << Escalope Grille >> ne se rejoignaient
    pas, et les dix photos d'escalope finissaient orphelines. Le caractere accentue
    survivait a la normalisation, puis << [^a-z0-9] >> le SUPPRIMAIT au lieu de le
    remplacer : il manquait une lettre au mot, et plus rien ne correspondait.

    Une table explicite ne depend d'aucun comportement de plateforme. Elle est plus
    longue, elle est sure.
#>
# Les caracteres accentues sont donnes par leur code : ce fichier doit rester en ASCII
# pur, PowerShell 5.1 lisant tout octet au-dela comme de l'ANSI.
$accents = -join (@(224,225,226,227,228,229,231,232,233,234,235,236,237,238,239,241,
                    242,243,244,245,246,249,250,251,252,253,255) | ForEach-Object { [char] $_ })
$nus     = 'aaaaaaceeeeiiiinooooouuuuyy'
function Nu([string] $s) {
  $b = New-Object Text.StringBuilder
  foreach ($c in $s.ToLower().ToCharArray()) {
    $i = $accents.IndexOf($c)
    [void] $b.Append($(if ($i -ge 0) { $nus[$i] } else { $c }))
  }
  return $b.ToString()
}
function Cle([string] $s) { return (Nu $s) -replace '[^a-z0-9]', '' }

<#
    Les abreviations employees dans les noms de fichiers. Les formes de DEUX mots
    viennent en premier : << moz 3arbi >> doit etre reconnu avant << moz >>, sans quoi
    la mozarilla ordinaire prendrait la place de la 3arbi.
#>
<#
    Les valeurs de cette table sont les noms EXACTS des ingredients de la carte,
    accents compris - et c'est tout l'enjeu.

    Ecrire ici << Escalope Grille >> sans accent obligeait a esperer que le
    rapprochement retire l'accent des DEUX cotes de la meme facon. Il ne le faisait
    pas : les dix photos d'escalope, les seuls ingredients accentues de la carte,
    restaient orphelines. En ecrivant le nom tel qu'il est dans la carte, les deux
    cotes sont identiques caractere pour caractere, et plus rien ne depend de la
    facon dont la plateforme traite les accents.

    L'accent est donne par son code : ce fichier doit rester en ASCII pur.
#>
$e = [char] 233   # e accent aigu
$doubles = [ordered]@{
  'moz 3arbi' = 'Mozarilla 3arbi'; 'moz3arbi' = 'Mozarilla 3arbi'; 'mozarilla 3arbi' = 'Mozarilla 3arbi'
  'esc g' = ('Escalope Grill' + $e); 'escg' = ('Escalope Grill' + $e); 'esc grille' = ('Escalope Grill' + $e)
  'esc p' = ('Escalope Pan' + $e);   'escp' = ('Escalope Pan' + $e);   'esc pane' = ('Escalope Pan' + $e)
  'cord b' = 'Cordon Bleu';        'corbleu' = 'Cordon Bleu';      'cord bleu' = 'Cordon Bleu'
  'cordon bleu' = 'Cordon Bleu';   'form slice' = 'Fromage Slice'; 'fromage slice' = 'Fromage Slice'
}
$simples = @{
  'oml' = 'Omlette'; 'omlt' = 'Omlette'; 'omlette' = 'Omlette'; 'omelette' = 'Omlette'
  'thon' = 'Thon'
  'moz' = 'Mozarilla'; 'mozarilla' = 'Mozarilla'; 'mozzarella' = 'Mozarilla'
  'form' = 'Fromage'; 'from' = 'Fromage'; 'fromage' = 'Fromage'; 'frm' = 'Fromage'
  'chaw' = 'Chawarma'; 'chawarma' = 'Chawarma'
  'kab' = 'Kabeb'; 'kabeb' = 'Kabeb'
  'jamb' = 'Jombon'; 'jam' = 'Jombon'; 'jambon' = 'Jombon'; 'jombon' = 'Jombon'
  'kwik' = 'Kwika'; 'kwika' = 'Kwika'
  'sal' = 'Salami'; 'salami' = 'Salami'
  'slice' = 'Fromage Slice'
}

<#
    Deux facons de retrouver l'article d'un fichier :

      1. son NOM entier - Cheese, Spicy, Number One, Thon ;
      2. a defaut, la LISTE DE SES INGREDIENTS, lue dans le nom du fichier :
         << oml thon Moz >> donne Omlette + Thon + Mozarilla, donc
         << Omlette Mozarilla Thon >>. L'ordre des mots n'a aucune importance :
         c'est l'ensemble qui designe l'article.

    Les ingredients viennent du fichier de carte, pas de la caisse : c'est lui qui les
    porte par leur nom.
#>
$articles = Appel 'GET' '/api/products' $null
$parId = @{}
foreach ($a in $articles) { $k = Cle $a.name; if (-not $parId.ContainsKey($k)) { $parId[$k] = $a } }

$parNom = @{}; $parIngredients = @{}
foreach ($p in $carte.products) {
  if ([double] $p.price -le 0) { continue }
  foreach ($n in @($p.name, $p.shortName, ($p.name -replace '^Extra\s+', ''))) {
    if ($n) { $k = Cle $n; if (-not $parNom.ContainsKey($k)) { $parNom[$k] = $p.name } }
  }
  if ($p.ingredients -and $p.ingredients.Count) {
    $k = (($p.ingredients | ForEach-Object { Cle $_ } | Sort-Object) -join '|')
    if (-not $parIngredients.ContainsKey($k)) { $parIngredients[$k] = $p.name }
  }
}

function ArticleDeFichier([string] $base) {
  $k = Cle ($base -replace '\+', ' plus ')
  if ($parNom.ContainsKey($k)) { return $parNom[$k] }
  $texte = ' ' + ((Nu $base) -replace '[^a-z0-9]+', ' ').Trim() + ' '
  $trouves = @()
  foreach ($d in $doubles.Keys) {
    if ($texte -like ('* ' + $d + ' *')) { $trouves += $doubles[$d]; $texte = $texte -replace [regex]::Escape(' ' + $d + ' '), ' ' }
  }
  foreach ($mot in ($texte.Trim() -split '\s+')) {
    if ($mot -and $simples.ContainsKey($mot)) { $trouves += $simples[$mot] }
  }
  if (-not $trouves.Count) { return $null }
  $k = (($trouves | ForEach-Object { Cle $_ } | Sort-Object -Unique) -join '|')
  if ($parIngredients.ContainsKey($k)) { return $parIngredients[$k] }
  return $parNom[($k -replace '\|', '')]
}

$types = @{ '.png' = 'image/png'; '.jpg' = 'image/jpeg'; '.jpeg' = 'image/jpeg'; '.webp' = 'image/webp'; '.gif' = 'image/gif' }

<#
    LA PHOTO EST REDUITE AVANT D'ETRE POSEE, et ce n'est pas un detail.

    Elle est rangee DANS la base, donc dans la sauvegarde, et surtout dans le catalogue
    que la caisse telecharge a chaque ouverture. Les images d'origine pesent environ
    200 Ko piece : cent photos feraient vingt megaoctets a charger avant d'afficher la
    premiere tuile, sur un poste tactile qui doit repondre tout de suite.

    La tuile fait 111 pixels. Une image de 240, en JPEG, est deja plus fine que ce que
    l'ecran montre - et pese vingt fois moins.

    Si System.Drawing manque, on envoie l'image telle quelle : une caisse lente vaut
    mieux qu'une caisse sans photos.
#>
$reduction = $true
try { Add-Type -AssemblyName System.Drawing -ErrorAction Stop } catch { $reduction = $false }
$encodeurJpeg = $null
if ($reduction) {
  $encodeurJpeg = [Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq 'image/jpeg' }
  if (-not $encodeurJpeg) { $reduction = $false }
}
if (-not $reduction) { Souci 'Reduction des images indisponible : elles partent en pleine taille.' }

function Reduire([string] $chemin) {
  if (-not $reduction) { return $null }
  try {
    $img = [Drawing.Image]::FromFile($chemin)
    $bmp = New-Object Drawing.Bitmap $TaillePhoto, $TaillePhoto
    $g = [Drawing.Graphics]::FromImage($bmp)
    $g.InterpolationMode = 'HighQualityBicubic'
    $g.SmoothingMode = 'HighQuality'
    $g.PixelOffsetMode = 'HighQuality'
    $g.DrawImage($img, 0, 0, $TaillePhoto, $TaillePhoto)
    $par = New-Object Drawing.Imaging.EncoderParameters 1
    $par.Param[0] = New-Object Drawing.Imaging.EncoderParameter ([Drawing.Imaging.Encoder]::Quality, [long] $QualitePhoto)
    $flux = New-Object IO.MemoryStream
    $bmp.Save($flux, $encodeurJpeg, $par)
    $octets = $flux.ToArray()
    $flux.Dispose(); $par.Dispose(); $g.Dispose(); $bmp.Dispose(); $img.Dispose()
    return $octets
  } catch { return $null }
}
$poses = 0; $orphelins = @(); $octets = 0; $prises = @{}
foreach ($f in Get-ChildItem -Path $Images -File) {
  $mime = $types[$f.Extension.ToLower()]
  if (-not $mime) { continue }
  $nom = ArticleDeFichier $f.BaseName
  $a = if ($nom) { $parId[(Cle $nom)] } else { $null }
  if (-not $a) { $orphelins += $f.Name; continue }
  $petite = Reduire $f.FullName
  if ($petite) { $mime = 'image/jpeg' } else { $petite = [IO.File]::ReadAllBytes($f.FullName) }
  $data = 'data:' + $mime + ';base64,' + [Convert]::ToBase64String($petite)
  Appel 'PUT' ("/api/products/" + $a.id + "/image") @{ imageUrl = $data } | Out-Null
  $poses++; $octets += $petite.Length
  $prises[$a.name] = $true
  Write-Host ("  {0,-26} -> {1}" -f $f.BaseName, $a.name) -ForegroundColor DarkGray
}
Info ("{0} photo(s) posee(s), {1} Ko au total ({2} px, qualite {3})." -f $poses,
      [math]::Round($octets / 1KB), $TaillePhoto, $QualitePhoto)
if ($orphelins.Count) {
  Souci ("{0} fichier(s) sans article correspondant :" -f $orphelins.Count)
  foreach ($o in $orphelins) { Souci "    $o" }
}
Info ("{0} article(s) sur {1} ont desormais une photo." -f $prises.Count, $articles.Count)
Write-Host ''
Info 'Termine.'
