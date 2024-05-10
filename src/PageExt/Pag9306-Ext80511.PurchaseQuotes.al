pageextension 80511 "Purchase Quotes" extends "Purchase Quotes" //9306
{
    layout
    {
        // Add changes to page layout here
        addafter(Status)
        {
            field("Total Line"; "Total Line")
            {
                Caption = 'Nb Lignes';
                ApplicationArea = all;
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
        rec.CalcFields("Total Line");
    end;
}