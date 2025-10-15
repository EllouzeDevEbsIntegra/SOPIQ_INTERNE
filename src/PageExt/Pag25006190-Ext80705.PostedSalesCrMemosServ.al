pageextension 80705 "Posted Sales Cr.Memos (Serv.)" extends "Posted Sales Cr.Memos (Serv.)" //25006190
{
    layout
    {
        // Add changes to page layout here
        addafter(AmountIncludingVAT)
        {
            field("Remaining Amount"; "Remaining Amount")
            {
                ApplicationArea = All;
                Caption = 'Montant Ouvert';
                Editable = false;
                ToolTip = 'Shows the remaining amount to be paid.';
            }
        }
    }

    actions
    {
        // Add changes to page actions here
    }

    var
        myInt: Integer;

    trigger OnAfterGetRecord()
    begin
        CalcFields("Remaining Amount");
    end;
}