pageextension 80145 "Purchase Recept. Lines" extends "Purchase Recept. Lines"
{
    layout
    {
        // Add changes to page layout here
        addafter("New Unit Price")
        {
            field("Prix Special Vendor"; "Prix Special Vendor")
            {
                ApplicationArea = all;
                Editable = true;
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