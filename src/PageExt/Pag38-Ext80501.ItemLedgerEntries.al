pageextension 80501 "Item Ledger Entries" extends "Item Ledger Entries" //38
{
    layout
    {
        // Add changes to page layout here
        addafter("Item No.")
        {
            field(itemDescription; itemDescription)
            {
                Caption = 'Désignation Article';
                ApplicationArea = all;
            }
        }
        addafter(Quantity)
        {
            field("N° Doc Frs"; "N° Doc Frs")
            {
                ApplicationArea = all;
                Editable = false;
            }

            field("Cmd Achat"; "Cmd Achat")
            {
                ApplicationArea = all;
                Editable = false;
            }

            field("Cmd Vente"; "Cmd Vente")
            {
                ApplicationArea = all;
                Editable = false;
                DrillDown = false;
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