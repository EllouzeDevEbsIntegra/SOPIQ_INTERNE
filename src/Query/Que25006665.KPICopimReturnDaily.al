// COPIM : lignes de retour BS agregees par jour, pour le tableau de bord Direction.
//
// Regle de CA COPIM reprise du Power BI "COPIM Dashboard V3" (query 25006656) :
//   CA = kpiCopimBsArchiveDaily + kpiCopimInvoiceDaily - kpiCopimCreditMemoDaily - kpiCopimReturnDaily
// Les montants sortent en positif, c'est le consommateur qui les soustrait.
//
// Montant retenu : Amount (HT, expose sous le nom Line_Amount_HT dans la query 25006656).
// "Amount Including VAT" est ecarte, comme dans le Power BI.
//
// Filtre structurel : "No." <> '' seulement. Le filtre article <> 'ACR' ne s'applique
// pas aux retours dans le Power BI. Les exclusions de clients (41000980, 41000900,
// 41000901, 41000981, 41000982, 41000242) ne sont pas figees ici : sellToCustomerNo est
// expose en filter() pour que le consommateur les applique depuis sa configuration.
//
// Cout : dataitem imbrique "Item Ledger Entry" lie sur "Document No." et "Line No.",
// comme la query 25006650. A valider au test : la jointure par defaut ecarte les lignes
// sans ecriture article, le CA doit rester identique a celui sans jointure.
query 25006665 "KPI Copim Return Daily"
{
    Caption = 'KPI COPIM retours BS par jour';
    Permissions = tabledata "Return Receipt Line" = R, tabledata "Item Ledger Entry" = R, tabledata "Value Entry" = R;
    QueryType = API;
    APIPublisher = 'sopiq';
    APIGroup = 'interne';
    APIVersion = 'v1.0';
    EntityName = 'kpiCopimReturnDaily';
    EntitySetName = 'kpiCopimReturnDaily';

    elements
    {
        dataitem(Return_Receipt_Line; "Return Receipt Line")
        {
            DataItemTableFilter = "No." = filter(<> '');

            // seul regroupement
            column(postingDate; "Posting Date")
            {
            }

            // agregats
            column(amountHT; Amount)
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
                DataItemLink = "Document No." = Return_Receipt_Line."Document No.", "Document Line No." = Return_Receipt_Line."Line No.";

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
