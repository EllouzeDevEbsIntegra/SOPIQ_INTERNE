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
// Pas de cout ni de marge en V1 : sur une vente, l'ecriture article porte le n
// d'expedition et non le n de facture, une jointure ferait tomber des lignes de CA.
// La marge COPIM sera traitee apres la V1 a partir des ecritures valeur.
query 25006665 "KPI Copim Return Daily"
{
    Caption = 'KPI COPIM retours BS par jour';
    Permissions = tabledata "Return Receipt Line" = R;
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
        }
    }
}
