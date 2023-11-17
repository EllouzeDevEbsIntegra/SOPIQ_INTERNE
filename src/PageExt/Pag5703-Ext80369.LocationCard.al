pageextension 80369 "Location Card" extends "Location Card" //5703
{
    layout
    {
        // Add changes to page layout here
        addafter("Use As In-Transit")
        {
            field(ExculreStock; ExculreStock)
            {
                ApplicationArea = all;
                Caption = 'Exclure du stock Disponible';
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