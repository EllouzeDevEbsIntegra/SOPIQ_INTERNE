pageextension 80122 "Item Transactions" extends "Item Transactions"
{
    layout
    {

    }

    actions
    {
        addafter("Ent&ry")
        {
            action("Item Old Transaction") // On click, afficher la page item info contenant l'image et les attributs  
            {
                ApplicationArea = All;
                Caption = 'Ancien Historique';
                Promoted = true;
                PromotedIsBig = true;
                PromotedCategory = Process;
                RunObject = page "Item Old Transaction";
                RunPageLink = "Item N°" = field("Item No.");
                ShortcutKey = F9;
                Image = TransferOrder;


            }
        }
    }



}