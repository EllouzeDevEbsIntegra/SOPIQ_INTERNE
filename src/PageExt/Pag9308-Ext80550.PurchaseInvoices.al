pageextension 80550 "Purchase Invoices" extends "Purchase Invoices" //9308
{
    layout
    {
        // Add changes to page layout here
        addafter("Location Code")
        {
            field("Total Line"; "Total Line")
            {
                Caption = 'Nb Lignes';
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