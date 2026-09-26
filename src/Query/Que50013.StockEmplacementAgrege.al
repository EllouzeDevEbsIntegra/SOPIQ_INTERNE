// Stock disponible par emplacement, agrege en une seule requete SQL.
//
// Pourquoi cette requete : la quantite d'un contenu d'emplacement ("Bin Content") est un
// champ calcule, somme des mouvements de stock. Un filtre du type
// BinContent.SetFilter(Quantity, '>0') ne peut donc pas descendre dans SQL : le serveur BC
// lit chaque ligne de contenu d'emplacement, puis lance une requete de somme par ligne.
// Mesure du 26/09/2026 sur le tableau de bord du responsable depot : 27 304 requetes pour
// deux ouvertures de page, soit 5,7 secondes rien que pour deux tuiles.
//
// Ici, le regroupement est fait par SQL (GROUP BY sur les colonnes non agregees), ce qui
// donne le meme resultat en une requete. Les colonnes de regroupement reprennent exactement
// celles de la formule de calcul du champ Quantity de "Bin Content", pour que les nombres
// soient identiques.
query 50013 "Stock Emplacement Agrege"
{
    Caption = 'Stock par emplacement, agrege';
    QueryType = Normal;

    elements
    {
        dataitem(MouvementStock; "Warehouse Entry")
        {
            column(CodeMagasin; "Location Code")
            {
            }
            column(CodeEmplacement; "Bin Code")
            {
            }
            column(NoArticle; "Item No.")
            {
            }
            column(CodeVariante; "Variant Code")
            {
            }
            column(CodeUnite; "Unit of Measure Code")
            {
            }
            column(Quantite; Quantity)
            {
                Method = Sum;
            }
        }
    }
}
