pageextension 80416 "Purchase Order List" extends "Purchase Order List"//9307
{
    layout
    {
        // Add changes to page layout here
        addafter("Buy-from Vendor Name")
        {
            field("Vendor Order No."; "Vendor Order No.")
            {
                Caption = 'N° Cmd Frs';
                ApplicationArea = all;
                Editable = false;
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