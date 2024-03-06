pageextension 80436 "Ligne archive BS" extends "Ligne archive BS"//50028
{
    layout
    {
        // Add changes to page layout here
        modify("Line Discount %")
        {
            Visible = false;
        }

        addafter("Line Discount %")
        {
            field("% Discount"; "% Discount")
            {
                ApplicationArea = all;
                Caption = 'Remise %';
            }
        }

        addafter("Document No.")
        {
            field(custNameImprime; custNameImprime)
            {
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