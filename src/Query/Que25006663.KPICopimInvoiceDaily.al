// COPIM : lignes de facture vente agregees par jour, pour le tableau de bord Direction.
//
// Regle de CA COPIM reprise du Power BI "COPIM Dashboard V3" (query 25006655) :
//   CA = kpiCopimBsArchiveDaily + kpiCopimInvoiceDaily - kpiCopimCreditMemoDaily - kpiCopimReturnDaily
// Les montants sortent en positif dans les quatre queries, la soustraction est faite
// cote consommateur.
//
// Montant retenu : "Line Amount".
//
// Filtres structurels : "No." <> '' et "No." <> 'ACR'. L'exclusion du client 41000901
// n'est pas figee ici : sellToCustomerNo est expose en filter() pour que le consommateur
// l'applique depuis sa configuration.
//
// Cout : dataitem imbrique "Item Ledger Entry" lie sur "Document No." et "Line No.",
// comme la query 25006650. A valider au test : la jointure par defaut ecarte les lignes
// sans ecriture article, le CA doit rester identique a celui sans jointure.
query 25006663 "KPI Copim Invoice Daily"
{
    Caption = 'KPI COPIM factures par jour';
    Permissions = tabledata "Sales Invoice Line" = R, tabledata "Item Ledger Entry" = R, tabledata "Value Entry" = R;
    QueryType = API;
    APIPublisher = 'sopiq';
    APIGroup = 'interne';
    APIVersion = 'v1.0';
    EntityName = 'kpiCopimInvoiceDaily';
    EntitySetName = 'kpiCopimInvoiceDaily';

    elements
    {
        dataitem(Sales_Invoice_Line; "Sales Invoice Line")
        {
            DataItemTableFilter = "No." = filter(<> '' & <> 'ACR');

            // seul regroupement
            column(postingDate; "Posting Date")
            {
            }

            // agregats
            column(amountHT; "Line Amount")
            {
                Method = Sum;
            }
            column(quantity; Quantity)
            {
                Method = Sum;
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

            dataitem(Item_Ledger_Entry; "Item Ledger Entry")
            {
                DataItemLink = "Document No." = Sales_Invoice_Line."Document No.", "Document Line No." = Sales_Invoice_Line."Line No.";

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
