// COPIM : cout des lignes d'avoir vente, agrege par jour de la ligne d'avoir.
//
// Pendant de la query de CA 25006664 (kpiCopimCreditMemoDaily). CA et cout separes pour
// ne pas sommer plusieurs fois le montant de vente, cette query n'en porte aucun.
//
// Cle : Value Entry."Document No." + "Document Line No." = n et ligne de l'avoir.
// Les avoirs COPIM sont des avoirs directs ("Return Receipt No." jamais renseigne) : il
// n'y a pas de reception retour separee, toutes les ecritures valeur portent le n de
// l'avoir. Couverture mesuree sur janvier 2026 : 100 %.
//
// Cout positif pour un avoir. Marge cote consommateur : CA net + somme des couts des
// cinq queries, signes natifs.
//
// Jointure externe (SqlJoinType = LeftOuterJoin) : une ligne sans ecriture valeur reste
// presente avec un cout nul. entryCount compte les lignes jointes (ecritures valeur).
//
// Meme filtre structurel que la query de CA ("No." <> '').
query 25006668 "KPI Copim Cr Memo Cost Daily"
{
    Caption = 'KPI COPIM cout avoirs par jour';
    Permissions = tabledata "Sales Cr.Memo Line" = R, tabledata "Value Entry" = R;
    QueryType = API;
    APIPublisher = 'sopiq';
    APIGroup = 'interne';
    APIVersion = 'v1.0';
    EntityName = 'kpiCopimCreditMemoCostDaily';
    EntitySetName = 'kpiCopimCreditMemoCostDaily';

    elements
    {
        dataitem(Sales_Cr_Memo_Line; "Sales Cr.Memo Line")
        {
            DataItemTableFilter = "No." = filter(<> '');

            // seul regroupement : date de la ligne d'avoir
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
                DataItemLink = "Document No." = Sales_Cr_Memo_Line."Document No.", "Document Line No." = Sales_Cr_Memo_Line."Line No.";
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
