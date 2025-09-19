pageextension 80710 "Salesperson/Purchaser Card" extends "Salesperson/Purchaser Card" //5116
{
    layout
    {
        // Add changes to page layout here
        addafter("Commission %")
        {
            field(Departement; Departement)
            {
                Caption = 'Departement';
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