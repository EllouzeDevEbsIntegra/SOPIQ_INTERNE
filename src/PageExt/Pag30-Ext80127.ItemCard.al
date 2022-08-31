pageextension 80127 "Item Card" extends "Item Card"//30
{
    layout
    {
        addafter("Last Purchase Date")
        {
            field("Last. Pursh. Date"; "Last. Pursh. Date")
            {
                ApplicationArea = All;
                Caption = 'Date dernier achat validé';
            }
            field("Last. Preferential"; "Last. Preferential")
            {
                ApplicationArea = All;
                Caption = 'Dernier préférentiel';
            }
        }
        // Add changes to page layout here
    }

    actions
    {
        // Add changes to page actions here
    }

    var
        myInt: Integer;
}