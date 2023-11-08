report 50227 "Purchase Return"
{

    RDLCLayout = './src/report/RDLC/PurchaseReturn.rdl';

    Caption = 'Retour Achat';
    PreviewMode = PrintLayout;
    UsageCategory = ReportsAndAnalysis;
    ApplicationArea = ALL;

    dataset
    {
        dataitem("Purchase Header"; 112)
        {
            RequestFilterFields = "No.";

            dataitem("Purchase Line"; 39)
            {
                // DataItemTableView = where("Small Parts" = const(false));
                // DataItemLink = "Document No." = FIELD("No.");

            }
        }
    }
}