pageextension 80312 "Item Reclass. Journal" extends "Item Reclass. Journal"//393 
{

    layout
    {
        // Add changes to page layout here
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
}