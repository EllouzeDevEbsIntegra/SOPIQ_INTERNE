pageextension 80312 "Item Reclass. Journal" extends "Item Reclass. Journal"//393 
{

    layout
    {
        // Add changes to page layout here
        addafter(Quantity)
        {
            field(inventory; inventory)
            {

            }
        }
        modify("Item No.")
        {
            trigger OnAfterValidate()
            begin
                CalcFields(inventory);
                CurrPage.Update();
            end;
        }
        modify("Location Code")
        {
            trigger OnAfterValidate()
            begin
                CalcFields(inventory);
                CurrPage.Update();
            end;
        }
    }

    actions
    {
        // Add changes to page actions here
        modify(Post)
        {
            Visible = Not (BtnValidate);
        }
        addafter(Post)
        {
            action("Verify Stock")
            {
                trigger OnAction()
                begin
                    rec.CalcFields(inventory);
                    Message('%1', rec.inventory);

                end;
            }
            action(Validate)
            {
                Caption = 'A Valider';
                Image = PostOrder;
                Promoted = true;
                PromotedCategory = Category4;
                PromotedIsBig = true;
                Visible = BtnValidate;
                trigger OnAction()
                begin
                    rec.validate := true;
                    rec.Modify();
                end;
            }
        }
        addafter("&Print")
        {
            action("LM Ready For Validation")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Prêt à la validation';
                Ellipsis = true;
                Image = ReleaseDoc;
                Promoted = true;
                PromotedCategory = Category4;
                trigger OnAction()
                var
                    Text001: Label 'Voulez vous confirmer la préparation de la feuille pour validation';
                    ItemJournalLine: Record "Item Journal Line";
                    Text002: Label '%1 lignes ont été marquées pour être validées';
                    NbLine: Integer;
                begin
                    IF CONFIRM(Text001) THEN BEGIN
                        NbLine := 0;
                        ItemJournalLine.CopyFilters(Rec);
                        if ItemJournalLine.FindSet then
                            repeat
                                ItemJournalLine.Validate("LM Ready For Validation", true);
                                ItemJournalLine.Modify();
                                NbLine += 1;
                            until ItemJournalLine.Next() = 0;
                        if NbLine > 0 then
                            Message(Text002, NbLine);
                    END;
                end;

            }
        }
    }

    var
        BtnValidate: Boolean;

    trigger OnOpenPage()
    var
        recUserSetup: Record "User Setup";
    begin
        recUserSetup.SetFilter("User ID", UserId);
        if recUserSetup.FindFirst() then begin
            BtnValidate := recUserSetup."A Valid. Jrnl. line";
        end;
    end;

    trigger OnAfterGetRecord()
    var
    begin
        CalcFields(inventory);
    end;
}