report 50230 "Etat BL Facturation"
{
    ApplicationArea = All;
    Caption = 'Liste Bl';
    UsageCategory = ReportsAndAnalysis;
    RDLCLayout = './src/report/RDLC/ListeBlFact.rdl';
    PreviewMode = PrintLayout;
    dataset
    {
        dataitem("Sales Shipment Header"; "Sales Shipment Header")
        {

            RequestFilterFields = "Sell-to Customer No.", "Document Date";
            DataItemTableView = where(BS = filter(false));

            column(Order_No_; "Order No.")
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
