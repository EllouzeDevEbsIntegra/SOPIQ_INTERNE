// COPIM : lignes de BS archives agregees par jour, pour le tableau de bord Direction.
//
// Regle de CA COPIM reprise du Power BI "COPIM Dashboard V3" (query 25006654) :
//   CA = kpiCopimBsArchiveDaily + kpiCopimInvoiceDaily - kpiCopimCreditMemoDaily - kpiCopimReturnDaily
// Les montants sortent en positif dans les quatre queries, la soustraction est faite
// cote consommateur.
//
// Montant retenu : "Line Amount HT". "Line Amount" (TTC) et "Montant ligne TTC BS" sont
// ecartes, comme dans le Power BI.
//
// Filtres structurels : Quantity <> 0 et "No." <> 'ACR'. L'exclusion du client 41000900
// n'est pas figee ici : sellToCustomerNo est expose en filter() pour que le consommateur
// l'applique depuis sa configuration.
//
// Cout : dataitem imbrique "Item Ledger Entry" lie sur "Document No." et "Line No.",
// comme la query 25006650. A valider au test : la jointure par defaut ecarte les lignes
// sans ecriture article, le CA doit rester identique a celui sans jointure.
query 25006662 "KPI Copim Bs Archive Daily"
{
    Caption = 'KPI COPIM BS archives par jour';
    Permissions = tabledata "Ligne archive BS" = R, tabledata "Item Ledger Entry" = R, tabledata "Value Entry" = R;
    QueryType = API;
    APIPublisher = 'sopiq';
    APIGroup = 'interne';
    APIVersion = 'v1.0';
    EntityName = 'kpiCopimBsArchiveDaily';
    EntitySetName = 'kpiCopimBsArchiveDaily';

    elements
    {
        dataitem(Ligne_archive_BS; "Ligne archive BS")
        {
            DataItemTableFilter = Quantity = filter(<> 0), "No." = filter(<> 'ACR');

            // seul regroupement
            column(postingDate; "Posting Date")
            {
            }

            // agregats
            column(amountHT; "Line Amount HT")
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
                DataItemLink = "Document No." = Ligne_archive_BS."Document No.", "Document Line No." = Ligne_archive_BS."Line No.";

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
