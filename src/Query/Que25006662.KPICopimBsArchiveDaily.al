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
// Pas de cout ni de marge en V1 : sur une vente, l'ecriture article porte le n
// d'expedition et non le n de facture, une jointure ferait tomber des lignes de CA.
// La marge COPIM sera traitee apres la V1 a partir des ecritures valeur.
query 25006662 "KPI Copim Bs Archive Daily"
{
    Caption = 'KPI COPIM BS archives par jour';
    Permissions = tabledata "Ligne archive BS" = R;
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
        }
    }
}
