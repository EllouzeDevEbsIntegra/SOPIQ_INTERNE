pageextension 80121 "Produit équivalent Comparateur" extends "Produit équivalent Comparateur" //50030
{
    layout
    {
        // Add changes to page layout here
        addbefore("Unit Price")
        {
            field("Last Pursh. Date"; rec."Last Purchase Date")
            {
                Caption = 'Date Dernier Achat';
                ApplicationArea = All;
                Editable = false;
            }
        }

        addafter("Unit Price")
        {
            field("Last Curr. Price."; lastDevisePrice)
            {
                Caption = 'Dernier Prix Devise Consulté';
                ApplicationArea = All;
                Editable = false;
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

            action("Item Old Transaction")  // On click, afficher la page historique des articles 2020 - 2021  
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
        lastDevisePrice: Decimal;

    trigger OnAfterGetRecord()
    var
        lPurchasePrice: Record "purchase price";
    begin // récupérer dernier prix en devise 
        lastDevisePrice := 0;
        lPurchasePrice.Reset();
        lPurchasePrice.SetCurrentKey("Starting Date");
        lPurchasePrice.SetRange("Vendor No.", "Vendor No.");
        lPurchasePrice.SetRange("Item No.", "No.");
        lPurchasePrice.SetFilter("Unit of Measure Code", '%1|%2', "Purch. Unit of Measure", '');
        if lPurchasePrice.FindLast() then begin
            lastDevisePrice := lPurchasePrice."Direct Unit Cost";
        end;
    end;
}