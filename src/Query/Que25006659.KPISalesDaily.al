// Ventes agregees par jour, pour le tableau de bord Direction.
//
// Source : "Value Entry" et non "Item Ledger Entry". Les montants Sales Amount (Actual),
// Cost Amount (Actual) etc. de l'ecriture article sont des FlowFields calcules depuis
// Value Entry (une sous-requete par ligne), donc non sommables dans une query. Value Entry
// porte ces memes montants en champs reels, sommables en SQL.
//
// Grain : une seule ligne par date de validation. Aucune autre colonne de regroupement,
// pour que le volume reste faible et l'appel rapide.
//
// Regles de calcul cote consommateur :
//   CA      = SalesAmountActual + SalesAmountExpected
//   Cout    = CostAmountActual  + CostAmountExpected    (negatif pour une vente)
//   Marge   = CA + Cout
//   Marge % = Marge / CA
//
// Les elements filter() ne sont pas restitues et ne regroupent pas : ils servent
// uniquement aux exclusions par societe dans $filter (articles et clients a ecarter).
query 25006659 "KPI Sales Daily"
{
    Caption = 'KPI ventes par jour';
    Permissions = tabledata "Value Entry" = R;
    QueryType = API;
    APIPublisher = 'sopiq';
    APIGroup = 'interne';
    APIVersion = 'v1.0';
    EntityName = 'kpiSalesDaily';
    EntitySetName = 'kpiSalesDaily';

    elements
    {
        dataitem(Value_Entry; "Value Entry")
        {
            DataItemTableFilter = "Item Ledger Entry Type" = const(Sale);

            // seul regroupement
            column(postingDate; "Posting Date")
            {
            }

            // agregats
            column(salesAmountActual; "Sales Amount (Actual)")
            {
                Method = Sum;
            }
            column(salesAmountExpected; "Sales Amount (Expected)")
            {
                Method = Sum;
            }
            column(costAmountActual; "Cost Amount (Actual)")
            {
                Method = Sum;
            }
            column(costAmountExpected; "Cost Amount (Expected)")
            {
                Method = Sum;
            }
            column(costAmountNonInvtbl; "Cost Amount (Non-Invtbl.)")
            {
                Method = Sum;
            }
            column(invoicedQuantity; "Invoiced Quantity")
            {
                Method = Sum;
            }
            column(entryCount)
            {
                Method = Count;
            }

            // filtrables en OData, non restitues, non regroupants
            filter(itemNo; "Item No.")
            {
            }
            filter(sourceNo; "Source No.")
            {
            }
            filter(sourceCode; "Source Code")
            {
            }
            filter(locationCode; "Location Code")
            {
            }
            filter(documentType; "Document Type")
            {
            }
            filter(inventoryPostingGroup; "Inventory Posting Group")
            {
            }
        }
    }
}
