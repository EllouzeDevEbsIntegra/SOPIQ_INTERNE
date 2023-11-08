pageextension 80400 "Sales Quote" extends "Sales Quote" //41
{
    layout
    {
        // Add changes to page layout here
    }

    actions
    {
        // Add changes to page actions here
        modify(chercher)
        {
            Visible = false;
            Enabled = false;
        }
        addafter(chercher)
        {
            action("Chercher Article")
            {
                ApplicationArea = All;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                ShortcutKey = 'Shift+Ctrl+F';
                Caption = 'Chercher Article';
                trigger OnAction()
                var
                    myInt: Integer;
                    ChercherItem: page "Devis Chercher Article";
                    tmpItem: Record ItemTmp;
                begin
                    TestField("Location Code");
                    ChercherItem.GetOrderNo(Rec);
                    ChercherItem.RunModal();
                end;

            }
        }


    }

    var
        myInt: Integer;
}