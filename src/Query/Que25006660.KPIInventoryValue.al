// Valeur et quantite de stock, pour le tableau de bord Direction.
//
// Source : "Value Entry", filtre sur les ecritures inventoriables. Meme raison que pour
// les ventes : les montants de valeur de stock sont des FlowFields sur l'ecriture article,
// non sommables dans une query, alors que Value Entry les porte en champs reels.
//
// Grain : une ligne par magasin et par groupe compta. stock.
//
// Regles de calcul cote consommateur :
//   Valeur   = CostAmountActual + CostAmountExpected
//   Quantite = itemLedgerEntryQuantity
//
// PostingDate est un filter() et non une colonne : sans filtre on obtient le stock
// actuel (cumul de toutes les ecritures), et avec "postingDate le <date>" le stock
// arrete a cette date. En faire une colonne aurait impose de regrouper par jour et de
// refaire le cumul cote consommateur.
query 25006660 "KPI Inventory Value"
{
    Caption = 'KPI valeur de stock';
    Permissions = tabledata "Value Entry" = R;
    QueryType = API;
    APIPublisher = 'sopiq';
    APIGroup = 'interne';
    APIVersion = 'v1.0';
    EntityName = 'kpiInventoryValue';
    EntitySetName = 'kpiInventoryValue';

    elements
    {
        dataitem(Value_Entry; "Value Entry")
        {
            DataItemTableFilter = Inventoriable = const(true);

            // regroupement
            column(locationCode; "Location Code")
            {
            }
            column(inventoryPostingGroup; "Inventory Posting Group")
            {
            }

            // agregats
            column(costAmountActual; "Cost Amount (Actual)")
            {
                Method = Sum;
            }
            column(costAmountExpected; "Cost Amount (Expected)")
            {
                Method = Sum;
            }
            column(itemLedgerEntryQuantity; "Item Ledger Entry Quantity")
            {
                Method = Sum;
            }
            column(entryCount)
            {
                Method = Count;
            }

            // filtrables en OData, non restitues, non regroupants
            filter(postingDate; "Posting Date")
            {
            }
            filter(itemNo; "Item No.")
            {
            }
            filter(itemLedgerEntryType; "Item Ledger Entry Type")
            {
            }
        }
    }
}
