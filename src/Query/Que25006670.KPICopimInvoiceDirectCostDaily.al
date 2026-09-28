// COPIM : cout des lignes de facture directe (sans expedition), agrege par jour de la
// ligne de facture.
//
// Pendant partiel de la query de CA 25006663 (kpiCopimInvoiceDaily) : lignes avec
// "Shipment No." vide. Les factures issues d'une expedition sont dans 25006669. CA et
// cout separes pour ne pas sommer plusieurs fois le montant de vente, cette query n'en
// porte aucun.
//
// Cle : Value Entry."Document No." + "Document Line No." = n et ligne de la facture.
// Valable uniquement sans expedition separee : l'ecriture article et ses ecritures
// valeur portent alors le n de la facture.
//
// Cout negatif pour une vente. Marge cote consommateur : CA net + somme des couts des
// cinq queries, signes natifs.
//
// Jointure externe (SqlJoinType = LeftOuterJoin) : une ligne sans ecriture valeur reste
// presente avec un cout nul. entryCount compte les lignes jointes (ecritures valeur).
//
// Memes filtres structurels que la query de CA ("No." <> '' et <> 'ACR'), plus
// "Shipment No." vide. Les exclusions de clients passent par sellToCustomerNo en $filter.
query 25006670 "KPI Copim Inv Direct Cost Dly"
{
    Caption = 'KPI COPIM cout factures directes par jour';
    Permissions = tabledata "Sales Invoice Line" = R, tabledata "Value Entry" = R;
    QueryType = API;
    APIPublisher = 'sopiq';
    APIGroup = 'interne';
    APIVersion = 'v1.0';
    EntityName = 'kpiCopimInvoiceDirectCostDaily';
    EntitySetName = 'kpiCopimInvoiceDirectCostDaily';

    elements
    {
        dataitem(Sales_Invoice_Line; "Sales Invoice Line")
        {
            DataItemTableFilter = "No." = filter(<> '' & <> 'ACR'), "Shipment No." = filter('');

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

            dataitem(Value_Entry; "Value Entry")
            {
                DataItemLink = "Document No." = Sales_Invoice_Line."Document No.", "Document Line No." = Sales_Invoice_Line."Line No.";
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
