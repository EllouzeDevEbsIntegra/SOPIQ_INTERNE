report 50231 "Etat Retour Facturation"
{
    ApplicationArea = All;
    Caption = 'Liste Retour';
    UsageCategory = ReportsAndAnalysis;
    RDLCLayout = './src/report/RDLC/ListeRRFact.rdl';
    PreviewMode = PrintLayout;
    dataset
    {
        dataitem("Return Receipt Header"; "Return Receipt Header")
        {
            RequestFilterFields = "Sell-to Customer No.", "Document Date";


            column(Order_No_; "Return Order No.")
            {
            }
            column(No_; "No.")
            {
            }
            column(Document_Date; "Document Date")
            {
            }
            column(Sell_to_Customer_Name; "Sell-to Customer Name")
            {
            }
            column(Sell_to_Customer_No_; "Sell-to Customer No.")
            {
            }
            column(Line_Amount; "Line Amount")
            {
            }
            column(afficherDetail; afficherDetail)
            {

            }
        }
    }
    requestpage
    {
        layout
        {
            area(content)
            {
                group(GroupName)
                {
                    field(afficherDetail; afficherDetail)
                    {
                        Caption = 'Masquer les détails';
                    }
                }
            }
        }
        actions
        {
            area(processing)
            {
            }
        }
    }
    var
        afficherDetail: Boolean;
}
