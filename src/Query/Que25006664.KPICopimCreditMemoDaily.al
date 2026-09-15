// COPIM : lignes d'avoir vente agregees par jour, pour le tableau de bord Direction.
//
// Regle de CA COPIM reprise du Power BI "COPIM Dashboard V3" (query 25006658) :
//   CA = kpiCopimBsArchiveDaily + kpiCopimInvoiceDaily - kpiCopimCreditMemoDaily - kpiCopimReturnDaily
// Les montants sortent en positif, c'est le consommateur qui les soustrait.
//
// Montant retenu : "Line Amount".
//
// Filtre structurel : "No." <> '' seulement. Le filtre article <> 'ACR' ne s'applique
// pas aux avoirs dans le Power BI. Aucune exclusion de client dans le Power BI pour les
// avoirs, sellToCustomerNo reste expose en filter() par homogeneite.
//
// Pas de cout ni de marge en V1 : sur une vente, l'ecriture article porte le n
// d'expedition et non le n de facture, une jointure ferait tomber des lignes de CA.
// La marge COPIM sera traitee apres la V1 a partir des ecritures valeur.
query 25006664 "KPI Copim Credit Memo Daily"
{
    Caption = 'KPI COPIM avoirs par jour';
    Permissions = tabledata "Sales Cr.Memo Line" = R;
    QueryType = API;
    APIPublisher = 'sopiq';
    APIGroup = 'interne';
    APIVersion = 'v1.0';
    EntityName = 'kpiCopimCreditMemoDaily';
    EntitySetName = 'kpiCopimCreditMemoDaily';

    elements
    {
        dataitem(Sales_Cr_Memo_Line; "Sales Cr.Memo Line")
        {
            DataItemTableFilter = "No." = filter(<> '');

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
