pageextension 50123 "Quote Lines" extends "Quote Lines"
{
    layout
    {
        // Add changes to page layout here
    }

    actions
    {
        addafter(ItemTransaction)
        {
            action("Item Old Transaction")
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