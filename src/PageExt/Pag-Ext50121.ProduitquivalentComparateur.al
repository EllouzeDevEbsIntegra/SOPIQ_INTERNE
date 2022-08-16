pageextension 50121 "Produit équivalent Comparateur" extends "Produit équivalent Comparateur"
{
    layout
    {
        // Add changes to page layout here
        addbefore("Import Inventory")
        {
            field("Date Dernier Achat"; rec."Last Purchase Date")
            {
                ApplicationArea = All;
            }
        }
    }

    actions
    {

        addafter(ItemTransaction)
        {
            action("Item Info") // On click, afficher la page item info contenant l'image et les attributs  
            {
                ApplicationArea = All;
                Caption = 'Information de l''article';
                Promoted = true;
                PromotedIsBig = true;
                PromotedCategory = Process;
                RunObject = page "Item info";
                RunPageLink = "No." = field("No.");


            }

            action("Item Old Transaction") // On click, afficher la page item info contenant l'image et les attributs  
            {
                ApplicationArea = All;
                Caption = 'Historique article 2020-2021';
                Promoted = true;
                PromotedIsBig = true;
                PromotedCategory = Process;
                RunObject = page "Item Old Transaction";
                RunPageLink = "Item N°" = field("No.");
                ShortcutKey = F8;


            }
        }
    }

    var
        myInt: Integer;
}