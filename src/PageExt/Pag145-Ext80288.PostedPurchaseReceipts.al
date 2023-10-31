pageextension 80288 "Posted Purchase Receipts" extends "Posted Purchase Receipts"//145
{
    layout
    {
        // Add changes to page layout here
        addafter("Buy-from Vendor Name")
        {
            field("Order No."; "Order No.")
            {
                ApplicationArea = All;
                Editable = false;
                Caption = 'N° Commande';

            }

            field("Vendor Shipment No."; "Vendor Shipment No.")
            {
                ApplicationArea = All;
                Editable = false;
                Caption = 'N° BL/FA Frs';
            }
        }
    }

    actions
    {
        // Add changes to page actions here
    }

    var
        myInt: Integer;
}