// COPIM : cout des lignes de BS archives, agrege par jour de la ligne de BS.
//
// Pendant de la query de CA 25006662 (kpiCopimBsArchiveDaily). Le CA et le cout sont
// volontairement dans deux queries separees : une ligne de BS a plusieurs ecritures
// valeur, la jointure repete la ligne et sommerait son montant de vente plusieurs fois.
// Cette query ne porte donc aucun montant de vente.
//
// Cle : Value Entry."Item Ledger Entry No." = "Item Shpt. Entry No." de la ligne archivee.
// Elle resiste a la transformation BS vers BL (report 50003 TransfertBStoBL), qui renomme
// la ligne d'expedition et change le n de document de l'ecriture article et d'une seule
// ecriture valeur. Couverture mesuree sur janvier 2026 : 100 % des lignes, transformees
// ou non.
//
// Cout = somme des ecritures valeur de l'ecriture article (expedition et facturation
// eventuelle), negatif pour une vente. Marge cote consommateur : CA + cout.
//
// Jointure externe (SqlJoinType = LeftOuterJoin, equivalent AL de "Use Default Values if
// No Match") : une ligne sans ecriture valeur reste presente avec un cout nul.
// entryCount compte les lignes jointes (ecritures valeur), pas les lignes de BS.
//
// Memes filtres structurels que la query de CA (Quantity <> 0, "No." <> 'ACR'). Les
// exclusions de clients passent par sellToCustomerNo en $filter.
query 25006666 "KPI Copim Bs Archive Cost Dly"
{
    Caption = 'KPI COPIM cout BS archives par jour';
    Permissions = tabledata "Ligne archive BS" = R, tabledata "Value Entry" = R;
    QueryType = API;
    APIPublisher = 'sopiq';
    APIGroup = 'interne';
    APIVersion = 'v1.0';
    EntityName = 'kpiCopimBsArchiveCostDaily';
    EntitySetName = 'kpiCopimBsArchiveCostDaily';

    elements
    {
        dataitem(Ligne_archive_BS; "Ligne archive BS")
        {
            DataItemTableFilter = Quantity = filter(<> 0), "No." = filter(<> 'ACR');

            // seul regroupement : date de la ligne de BS
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
                DataItemLink = "Item Ledger Entry No." = Ligne_archive_BS."Item Shpt. Entry No.";
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
