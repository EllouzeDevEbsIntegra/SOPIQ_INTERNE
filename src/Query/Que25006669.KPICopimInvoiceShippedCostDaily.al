// COPIM : cout des lignes de facture issues d'une expedition, agrege par jour de la
// ligne de facture.
//
// Pendant partiel de la query de CA 25006663 (kpiCopimInvoiceDaily) : lignes avec
// "Shipment No." renseigne. Les factures directes sont dans 25006670. CA et cout separes
// pour ne pas sommer plusieurs fois le montant de vente, cette query n'en porte aucun.
//
// Cle : ligne de facture -> ligne de BL ("Shipment No." + "Shipment Line No.") ->
// Value Entry."Item Ledger Entry No." = "Item Shpt. Entry No." de la ligne de BL.
// Ne pas utiliser le n de facture ici : BC repartit le cout entre l'expedition (cout
// attendu) et la facture (cout reel et annulation du cout attendu), les seules ecritures
// valeur de la facture donneraient un cout proche de zero.
//
// Cout negatif pour une vente. Marge cote consommateur : CA net + somme des couts des
// cinq queries, signes natifs.
//
// Jointures externes (SqlJoinType = LeftOuterJoin) : une ligne sans ligne de BL ou sans
// ecriture valeur reste presente avec un cout nul. entryCount compte les lignes jointes.
//
// Memes filtres structurels que la query de CA ("No." <> '' et <> 'ACR'), plus
// "Shipment No." <> ''. Les exclusions de clients passent par sellToCustomerNo en $filter.
query 25006669 "KPI Copim Inv Shipped Cost Dly"
{
    Caption = 'KPI COPIM cout factures expediees par jour';
    Permissions = tabledata "Sales Invoice Line" = R, tabledata "Sales Shipment Line" = R, tabledata "Value Entry" = R;
    QueryType = API;
    APIPublisher = 'sopiq';
    APIGroup = 'interne';
    APIVersion = 'v1.0';
    EntityName = 'kpiCopimInvoiceShippedCostDaily';
    EntitySetName = 'kpiCopimInvoiceShippedCostDaily';

    elements
    {
        dataitem(Sales_Invoice_Line; "Sales Invoice Line")
        {
            DataItemTableFilter = "No." = filter(<> '' & <> 'ACR'), "Shipment No." = filter(<> '');

            // seul regroupement : date de la ligne de facture
            column(postingDate; "Posting Date")
            {
            }
            column(entryCount)
            {
                Method = Count;
            }

            // filtrables en OData, non restitues, non regroupants
            filter(sellToCustomerNo; "Sell-to Customer No.")
            {
            }
            filter(locationCode; "Location Code")
            {
            }

            dataitem(Sales_Shipment_Line; "Sales Shipment Line")
            {
                DataItemLink = "Document No." = Sales_Invoice_Line."Shipment No.", "Line No." = Sales_Invoice_Line."Shipment Line No.";
                SqlJoinType = LeftOuterJoin;

                dataitem(Value_Entry; "Value Entry")
                {
                    DataItemLink = "Item Ledger Entry No." = Sales_Shipment_Line."Item Shpt. Entry No.";
                    DataItemTableFilter = "Item Ledger Entry No." = filter(<> 0);
                    SqlJoinType = LeftOuterJoin;

                    column(costAmountActual; "Cost Amount (Actual)")
                    {
                        Method = Sum;
                    }
                    column(costAmountExpected; "Cost Amount (Expected)")
                    {
                        Method = Sum;
                    }
                }
            }
        }
    }
}
