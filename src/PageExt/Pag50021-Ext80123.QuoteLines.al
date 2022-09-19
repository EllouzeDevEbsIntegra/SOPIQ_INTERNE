pageextension 80123 "Quote Lines" extends "Quote Lines" //50021
{
    layout
    {
        // Add changes to page layout here
        addbefore("Initial Quantity")
        {
            field("Last Unit Price"; "Direct Unit Cost")
            {
                Caption = 'Prix Devise Consulté';
                ApplicationArea = All;
                Editable = false;
            }
            field("Initial Vendor Price"; "Initial Vendor Price")
            {
                Caption = 'Prix Initial Vendeur';
                ApplicationArea = All;
                Editable = false;
            }
        }
    }

    actions
    {
        addafter(ItemTransaction)
        {
            action("Item Old Transaction")
            {
                ApplicationArea = All;
                Caption = 'Historique article 2021';
                Promoted = true;
                PromotedIsBig = true;
                PromotedCategory = Process;
                RunObject = page "Item Transaction 2021";
                RunPageLink = "Item N°" = field("No."), Year = CONST('2021');
                ShortcutKey = F8;
            }
        }
    }
}