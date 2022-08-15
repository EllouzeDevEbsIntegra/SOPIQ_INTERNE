pageextension 50121 "Produit équivalent Comparateur" extends "Produit équivalent Comparateur"
{
    layout
    {
        // Add changes to page layout here
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
        }
    }

    var
        myInt: Integer;
}