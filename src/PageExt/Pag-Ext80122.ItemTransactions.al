pageextension 80122 "Item Transactions" extends "Item Transactions"
{
    layout
    {
        // Add changes to page layout here
    }

    actions
    {
        addafter("Ent&ry")
        {
            action("Item Old Transaction") // On click, afficher la page item info contenant l'image et les attributs  
            {
                ApplicationArea = All;
                Caption = 'Historique article 2021';
                Promoted = true;
                PromotedIsBig = true;
                PromotedCategory = Process;
                RunObject = page "Item Transaction 2021";
                RunPageLink = "Item N°" = field("Item No."), Year = CONST('2021');
                ShortcutKey = F9;


            }
        }
    }

    var
        myInt: Integer;
}