// Main d'oeuvre et services externes de l'atelier, agreges par jour. Agence 3S uniquement.
//
// Source : "Service Ledger Entry EDMS", la table d'ecritures du DMS.
//
// Filtre "Type <> Item" : les pieces posees en atelier sont deja dans Value Entry, donc
// dans la query des ventes (factures atelier FS / FSI, avoirs AS / ASI) avec leur cout
// reel. Les inclure ici les compterait deux fois.
//
// Aucune colonne de cout n'est exposee : "Resource Cost Amount" vaut zero partout et
// "Total Cost" n'est renseigne que sur environ 4 % des lignes Labor. La main d'oeuvre est
// comptee a 100 % de marge, comme dans le Power BI existant. Les deux champs restent
// disponibles a titre indicatif pour controle, mais ne doivent pas servir au calcul.
//
// Regle de calcul cote consommateur, Agence 3S :
//   CA    = somme kpiSalesDaily + somme kpiWorkshopDaily.amountLCY
//   Cout  = somme kpiSalesDaily seulement
//   Marge = CA + Cout
//
// ReverseSign : les montants et quantites sont stockes en negatif dans la table du DMS,
// comme dans la query 25006650 deja en place. Le signe est inverse ici pour que
// amountLCY s'additionne directement au CA des ventes.
query 25006661 "KPI Workshop Daily"
{
    Caption = 'KPI atelier par jour';
    Permissions = tabledata "Service Ledger Entry EDMS" = R;
    QueryType = API;
    APIPublisher = 'sopiq';
    APIGroup = 'interne';
    APIVersion = 'v1.0';
    EntityName = 'kpiWorkshopDaily';
    EntitySetName = 'kpiWorkshopDaily';

    elements
    {
        dataitem(Service_Ledger_Entry_EDMS; "Service Ledger Entry EDMS")
        {
            DataItemTableFilter = Type = filter(<> Item);

            // seul regroupement
            column(postingDate; "Posting Date")
            {
            }

            // agregats
            column(amountLCY; "Amount (LCY)")
            {
                Method = Sum;
                ReverseSign = true;
            }
            column(quantity; Quantity)
            {
                Method = Sum;
                ReverseSign = true;
            }
            column(entryCount)
            {
                Method = Count;
            }

            // a titre indicatif, pour controle. Ne pas utiliser dans le calcul de marge.
            column(totalCost; "Total Cost")
            {
                Method = Sum;
            }
            column(resourceCostAmount; "Resource Cost Amount")
            {
                Method = Sum;
            }

            // filtrables en OData, non restitues, non regroupants
            filter(internal; Internal)
            {
            }
            filter(chargeable; Chargeable)
            {
            }
            filter(serviceOrderNo; "Service Order No.")
            {
            }
            filter(customerNo; "Customer No.")
            {
            }
            filter(makeCode; "Make Code")
            {
            }
            filter(documentType; "Document Type")
            {
            }
        }
    }
}
