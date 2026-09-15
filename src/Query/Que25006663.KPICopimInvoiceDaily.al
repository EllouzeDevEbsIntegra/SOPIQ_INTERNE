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
// Pas de cout ni de marge en V1 : sur une vente, l'ecriture article porte le n
// d'expedition et non le n de facture, une jointure ferait tomber des lignes de CA.
// La marge COPIM sera traitee apres la V1 a partir des ecritures valeur.
query 25006663 "KPI Copim Invoice Daily"
{
    Caption = 'KPI COPIM factures par jour';
    Permissions = tabledata "Sales Invoice Line" = R;
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
        }
    }
}
