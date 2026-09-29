// Trois tuiles masquees dans la partie "Activites" du Role Center vendeur pieces de
// rechange : "Pret a expedier", "Partiellement expedie" et "Retarde".
//
// Elles comptent des commandes en filtrant sur "Completely Shipped", "Shipped" et
// "Late Order Shipping", qui sont des FlowFields de l'en-tete vente calcules depuis les
// lignes. Un filtre sur un FlowField ne peut etre servi par aucun index : SQL doit
// recalculer la valeur pour chaque en-tete avant de pouvoir compter. Mesure du 29/09/2026
// a l'ouverture du Role Center : quatre requetes, plus de huit cent mille pages lues, et
// cela pour chaque vendeur a chaque ouverture de sa page d'accueil.
//
// Le metier a confirme le 29/09/2026 que ces trois tuiles ne servent a personne. Les
// masquer suffit donc : Business Central ne calcule pas une tuile invisible.
//
// Les quatre autres tuiles de la partie sont conservees, elles comptent sur des champs
// ordinaires et ne coutent rien.
//
// Pour les rendre a nouveau visibles, il suffit de retirer cette extension de page. Si
// elles redevenaient utiles un jour, il faudrait les calculer dans le traitement KPI et
// les afficher depuis le cache, comme les tuiles articles du tableau de bord.
pageextension 80751 "SP Salesperson Activities SI" extends "SP Salesperson Activities"
{
    layout
    {
        modify(ReadytoShip)
        {
            Visible = false;
        }
        modify(PartiallyShipped)
        {
            Visible = false;
        }
        modify(Delayed)
        {
            Visible = false;
        }
    }
}
