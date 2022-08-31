tableextension 80106 "Item Ledger Entry" extends "Item Ledger Entry"//32
{
    fields
    {
        // Add changes to table fields here
    }

    var
        myInt: Integer;

    trigger OnInsert()
    var
        recItem: Record Item;
    begin

        recItem.Reset();
        recItem.SetRange("No.", "Item No.");

        if ("Entry Type" = 0) then begin

            if recItem.FindFirst() then begin
                recItem."Last. Pursh. Date" := "Posting Date";
                recItem.Modify();
            end;

        end;


    end;
}