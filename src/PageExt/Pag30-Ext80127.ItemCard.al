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


            field("Last. Pursh. cost DS"; "Last. Pursh. cost DS")
            {
                ApplicationArea = All;
                Caption = 'Dernier prix calculé DS';
            }

            field("Last. Preferential"; "Last. Preferential")
            {
                ApplicationArea = All;
                Caption = 'Dernier préférentiel';
            }
        }

    }

    actions
    {

    }

}