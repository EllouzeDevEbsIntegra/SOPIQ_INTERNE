pageextension 80114 "Sales Order Subform" extends "Sales Order Subform" //46
{
    layout
    {
        addafter("Unit Price") // Ajout du champ prix initial dans ligne vente
        {
            field("Prix Initial"; rec."Initial Unit Price")
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