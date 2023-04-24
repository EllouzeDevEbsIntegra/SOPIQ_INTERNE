pageextension 80142 "Item Bin Contents" extends "Item Bin Contents" //7379
{
    layout
    {
        addafter("Quantity (Base)")
        {
            field("Count Content"; "Count Content")
            {
                ApplicationArea = All;
                Caption = 'Nombre emplacement';
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