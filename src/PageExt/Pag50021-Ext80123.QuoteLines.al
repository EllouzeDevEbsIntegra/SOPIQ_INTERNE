pageextension 80123 "Quote Lines" extends "Quote Lines" //50021
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

    var
        myInt: Integer;
}