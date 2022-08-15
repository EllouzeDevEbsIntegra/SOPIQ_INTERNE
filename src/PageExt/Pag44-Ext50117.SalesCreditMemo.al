pageextension 50117 "Sales Credit Memo" extends "Sales Credit Memo" //44 
{
    layout
    {
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
        "STStamp Amount" := 0.000;
    end;

    var
        myInt: Integer;
}