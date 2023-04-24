pageextension 80166 "Posted Sales Shipment" extends "Posted Sales Shipment"//130
{
    layout
    {
        // Add changes to page layout here
    }

    actions
    {
        // Add changes to page actions here
        addafter("Imprimer BL")
        {
            action("Imprimer BL Agence")
            {
                ApplicationArea = all;
                Caption = 'Imprimer BL Agence';
                Visible = not BS;
                Promoted = true;
                Image = Print;
                PromotedIsBig = true;
                PromotedCategory = Report;
                trigger OnAction()
                var
                    PostedSalesShipment: Record "Sales Shipment Header";
                    Posted: Page "Posted Sales Shipment";
                    reportBL: Report 50207;
                begin
                    CurrPage.SetSelectionFilter(PostedSalesShipment);
                    reportBL.SetTableView(PostedSalesShipment);
                    reportBL.Run();
                end;
            }
        }
    }

    var
        myInt: Integer;
}