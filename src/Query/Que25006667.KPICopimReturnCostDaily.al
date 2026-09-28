// COPIM : cout des lignes de retour BS, agrege par jour de la ligne de retour.
//
// Pendant de la query de CA 25006665 (kpiCopimReturnDaily). CA et cout separes pour ne
// pas sommer plusieurs fois le montant de vente, cette query n'en porte aucun.
//
// Cle : Value Entry."Item Ledger Entry No." = "Item Rcpt. Entry No." de la ligne de
// retour. Couverture mesuree sur janvier 2026 : 100 %.
//
// Cout positif pour un retour (le stock revient). Marge cote consommateur : CA net
// (BS + factures - avoirs - retours) + somme des couts des cinq queries, signes natifs.
//
// Jointure externe (SqlJoinType = LeftOuterJoin) : une ligne sans ecriture valeur reste
// presente avec un cout nul. entryCount compte les lignes jointes (ecritures valeur).
//
// Meme filtre structurel que la query de CA ("No." <> ''). Les exclusions de clients
// passent par sellToCustomerNo en $filter.
query 25006667 "KPI Copim Return Cost Daily"
{
    Caption = 'KPI COPIM cout retours BS par jour';
    Permissions = tabledata "Return Receipt Line" = R, tabledata "Value Entry" = R;
    QueryType = API;
    APIPublisher = 'sopiq';
    APIGroup = 'interne';
    APIVersion = 'v1.0';
    EntityName = 'kpiCopimReturnCostDaily';
    EntitySetName = 'kpiCopimReturnCostDaily';

    elements
    {
        dataitem(Return_Receipt_Line; "Return Receipt Line")
        {
            DataItemTableFilter = "No." = filter(<> '');

            // seul regroupement : date de la ligne de retour
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
                DataItemLink = "Item Ledger Entry No." = Return_Receipt_Line."Item Rcpt. Entry No.";
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
