pageextension 80119 "Purchase Credit Memo" extends "Purchase Credit Memo"//52
{
    layout
    {
        // Add changes to page layout here
    }

    actions
    {
        // Add changes to page actions here
    }
    trigger OnOpenPage()
    begin

    end;
    // Rendre le champs timbre fiscal désactvié par défaut
    trigger OnAfterGetRecord()
    begin
        "STApply Stamp Fiscal" := false;
        "STStamp Fiscal Amount" := 0.000;
    end;

    var
        myInt: Integer;
}