pageextension 80391 "Phys. Inventory Recording List" extends "Phys. Inventory Recording List" //5880
{
    layout
    {
        // Add changes to page layout here
        addafter(Status)
        {
            field("NB Ecart"; "NB Ecart")
            {
                Caption = 'NB Ecart';
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