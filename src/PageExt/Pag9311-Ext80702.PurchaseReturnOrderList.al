pageextension 80702 "Purchase Return Order List" extends "Purchase Return Order List" //9311
{
    layout
    {
        // Add changes to page layout here
        addafter("Buy-from Vendor No.")
        {
            field("Vendor Cr. Memo No."; "Vendor Cr. Memo No.")
            {
                Caption = 'No. Doc Frs';
                ApplicationArea = all;
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