<#
    Copie les photos vers site\img\ en les renommant comme la page les attend.

    La page cherche site\img\<article-en-minuscules-avec-des-tirets>.png : << Omlette
    Mozarilla Thon >> devient << omlette-mozarilla-thon.png >>.

    VOS FICHIERS NE PORTENT PAS CES NOMS, et c'est tres bien ainsi : ils s'appellent
    << oml thon Moz.png >>, << Chaw Form.png >>, << corBleu.png >>. Le script les lit
    donc comme une LISTE D'INGREDIENTS, pas comme un nom :

        oml thon Moz  ->  Omlette + Thon + Mozarilla  ->  Omlette Mozarilla Thon

    L'ordre n'a aucune importance - c'est l'ensemble des ingredients qui designe
    l'article, pas la suite des mots. << omlt thon Moz >> et << oml Moz thon >>
    tombent sur le meme article.

    Ce qui ne correspond a rien est NOMME a la fin, et chaque rapprochement est
    affiche : une photo posee sur le mauvais article se verrait en caisse, des
    semaines plus tard, et personne ne saurait d'ou elle vient.

    Exemple :
        .\outils\copier-photos.ps1 -Source 'C:\Users\administrateur\Downloads\image POS\reduit'
#>
[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)] [string] $Source,
  [string] $Destination = '',
  [string] $FichierCarte = ''
)

$ErrorActionPreference = 'Stop'
$site = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
if (-not $Destination)   { $Destination = Join-Path $site 'img' }
if (-not $FichierCarte)  { $FichierCarte = Join-Path (Split-Path -Parent $site) 'catalogs\number-one-2026.json' }

function Info($t)  { Write-Host "  $t" -ForegroundColor Green }
function Souci($t) { Write-Host "  $t" -ForegroundColor Yellow }
function Stop-Net($t) { Write-Host ''; Write-Host "ARRET : $t" -ForegroundColor Red; exit 1 }

if (-not (Test-Path $Source))       { Stop-Net "Dossier introuvable : $Source" }
if (-not (Test-Path $FichierCarte)) { Stop-Net "Carte introuvable : $FichierCarte" }
New-Item -ItemType Directory -Force -Path $Destination | Out-Null

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
# Nom de fichier attendu par la page.
function Ardoise([string] $s) {
  return (((Nu $s) -replace '[^a-z0-9]+', '-') -replace '-+', '-').Trim('-')
}
# Cle de comparaison : ni espaces, ni ponctuation.
function Cle([string] $s) { return (Nu $s) -replace '[^a-z0-9]', '' }

<#
    Les abreviations que vous employez dans les noms de fichiers. Les formes de DEUX
    mots viennent en premier : << moz 3arbi >> doit etre reconnu avant << moz >>, sans
    quoi la mozarilla ordinaire prendrait la place de la 3arbi.
#>
$doubles = [ordered]@{
  'moz 3arbi' = 'Mozarilla 3arbi'; 'moz3arbi' = 'Mozarilla 3arbi'; 'mozarilla 3arbi' = 'Mozarilla 3arbi'
  'esc g' = 'Escalope Grille';     'escg' = 'Escalope Grille';     'esc grille' = 'Escalope Grille'
  'esc p' = 'Escalope Pane';       'escp' = 'Escalope Pane';       'esc pane' = 'Escalope Pane'
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

$menu = Get-Content $FichierCarte -Raw -Encoding UTF8 | ConvertFrom-Json
$publies = @($menu.products | Where-Object { [double] $_.price -gt 0 })
if (-not $publies.Count) { Stop-Net "Aucun article a prix dans $FichierCarte." }

# Deux facons de retrouver un article : par son nom, ou par l'ensemble de ses ingredients.
$parNom = @{}; $parIngredients = @{}
foreach ($p in $publies) {
  foreach ($n in @($p.name, $p.shortName, ($p.name -replace '^Extra\s+', ''))) {
    if ($n) { $k = Cle $n; if (-not $parNom.ContainsKey($k)) { $parNom[$k] = $p.name } }
  }
  if ($p.ingredients -and $p.ingredients.Count) {
    $k = (($p.ingredients | ForEach-Object { Cle $_ } | Sort-Object) -join '|')
    if (-not $parIngredients.ContainsKey($k)) { $parIngredients[$k] = $p.name }
  }
}

function ArticleDeFichier([string] $base) {
  # 1. Le nom entier, tel quel : Cheese, Spicy, Number One, Thon...
  $k = Cle ($base -replace '\+', ' plus ')
  if ($parNom.ContainsKey($k)) { return $parNom[$k] }
  # 2. Sinon, on lit le fichier comme une liste d'ingredients.
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
  if ($parNom.ContainsKey(($k -replace '\|', ''))) { return $parNom[($k -replace '\|', '')] }
  return $null
}

$copiees = 0; $orphelins = @(); $prises = @{}
foreach ($f in Get-ChildItem -Path $Source -File | Sort-Object Name) {
  if ($f.Extension.ToLower() -notin @('.png', '.jpg', '.jpeg', '.webp')) { continue }
  $article = ArticleDeFichier $f.BaseName
  if (-not $article) { $orphelins += $f.Name; continue }
  Copy-Item $f.FullName (Join-Path $Destination ((Ardoise $article) + '.png')) -Force
  $copiees++
  $deja = $prises[$article]
  $prises[$article] = $f.Name
  Write-Host ("  {0,-26} -> {1}" -f $f.BaseName, $article) -ForegroundColor DarkGray
  if ($deja) { Souci "    (remplace la photo posee par $deja)" }
}

Write-Host ''
Info "$copiees fichier(s) copie(s) dans $Destination"
Info ("{0} article(s) publie(s) sur {1} ont leur photo." -f $prises.Count, $publies.Count)
if ($orphelins.Count) {
  Souci "$($orphelins.Count) fichier(s) que je n'ai pas su rapprocher :"
  foreach ($o in $orphelins) { Souci "    $o" }
}
$manque = @($publies | Where-Object { -not $prises.ContainsKey($_.name) } | ForEach-Object { $_.name })
if ($manque.Count) {
  Souci "$($manque.Count) article(s) sans photo (l'initiale s'affichera a la place) :"
  foreach ($m in $manque) { Souci "    $m" }
}
Write-Host ''
Info 'Termine. Ouvrez site\index.html : les photos sont la, sans rien regenerer.'
