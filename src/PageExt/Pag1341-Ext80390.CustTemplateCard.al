pageextension 80390 "Cust. Template Card" extends "Cust. Template Card"//1341
{
    layout
    {
        // Add changes to page layout here
        addafter("Customer Disc. Group")
        {
            field("Location Code"; "Location Code")
            {
                ApplicationArea = All;
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