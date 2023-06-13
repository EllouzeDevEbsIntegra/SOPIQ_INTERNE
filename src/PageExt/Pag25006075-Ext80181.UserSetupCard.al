pageextension 80181 "User Setup Card" extends "User Setup Card" //25006075
{
    layout
    {
        // Add changes to page layout here
        addafter(RegisterStatistics)
        {
            field("Pruch Stat CA"; "Purchase Stat CA")
            {
                ApplicationArea = All;
                Caption = 'Afficher Stat CA Achat';
            }
        }

        addlast(Service)
        {
            field("Follow Up Controler"; "Follow Up Controler")
            {
                ApplicationArea = All;
                Caption = 'Autoriser clôture Fiche Suivi';
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