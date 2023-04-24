pageextension 80171 "Posted Sales Invoice Lines" extends "Posted Sales Invoice Lines"//526
{
    layout
    {
        // Add changes to page layout here
        addafter("Line Discount %")
        {
            field("Ressource"; "Resources (Serv.)")
            {
                ApplicationArea = All;
                Caption = 'Ressource';
            }

            field("Type MO"; "Labor Groupe Code")
            {
                ApplicationArea = All;
                Caption = 'Type MO';
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