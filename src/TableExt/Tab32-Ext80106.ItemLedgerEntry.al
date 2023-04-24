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
        recSpecItemLeadEntry: Record "Specific Item Ledger Entry";
    begin



        if ("Entry Type" = 0) then begin

            recItem.Reset();
            recItem.SetRange("No.", "Item No.");
            if recItem.FindFirst() then begin
                recItem."Last. Pursh. Date" := "Posting Date";
                recItem.Modify();
            end;

        end;

        recSpecItemLeadEntry.Init();
        recSpecItemLeadEntry."Applies-to Entry" := rec."Applies-to Entry";
        recSpecItemLeadEntry."Completely Invoiced" := rec."Completely Invoiced";
        recSpecItemLeadEntry.Description := rec.Description;
        recSpecItemLeadEntry."Document Date" := rec."Document Date";
        recSpecItemLeadEntry."Document Line No." := rec."Document Line No.";
        recSpecItemLeadEntry."Document No." := rec."Document No.";
        recSpecItemLeadEntry."Document Type" := rec."Document Type";
        recSpecItemLeadEntry."Drop Shipment" := rec."Drop Shipment";
        recSpecItemLeadEntry."Entry No." := rec."Entry No.";
        recSpecItemLeadEntry."Entry Type" := rec."Entry Type";
        recSpecItemLeadEntry."External Document No." := rec."External Document No.";
        recSpecItemLeadEntry."Invoiced Quantity" := rec."Invoiced Quantity";
        recSpecItemLeadEntry."Item No." := rec."Item No.";
        recSpecItemLeadEntry."Item Type" := rec."Item Type";
        recSpecItemLeadEntry."Last Invoice Date" := rec."Last Invoice Date";
        recSpecItemLeadEntry."Location Code" := rec."Location Code";
        recSpecItemLeadEntry."Make Code" := rec."Make Code";
        recSpecItemLeadEntry."Model Code" := rec."Model Code";
        recSpecItemLeadEntry."Model Code" := rec."Model Code";
        recSpecItemLeadEntry."Model Version No." := rec."Model Version No.";
        recSpecItemLeadEntry.Open := rec.Open;
        recSpecItemLeadEntry."Order Line No." := rec."Order Line No.";
        recSpecItemLeadEntry."Order No." := rec."Order No.";
        recSpecItemLeadEntry."Order Type" := rec."Order Type";
        recSpecItemLeadEntry.Positive := rec.Positive;
        recSpecItemLeadEntry."Posting Date" := rec."Posting Date";
        recSpecItemLeadEntry."Qty. per Unit of Measure" := rec."Qty. per Unit of Measure";
        recSpecItemLeadEntry.Quantity := rec.Quantity;
        recSpecItemLeadEntry."Remaining Quantity" := rec."Remaining Quantity";
        recSpecItemLeadEntry."Shpt. Method Code" := rec."Shpt. Method Code";
        recSpecItemLeadEntry."Source No." := rec."Source No.";
        recSpecItemLeadEntry."Source Type" := rec."Source Type";
        recSpecItemLeadEntry.SystemId := rec.SystemId;
        recSpecItemLeadEntry."Transaction Type" := rec."Transaction Type";
        recSpecItemLeadEntry."Transport Method" := rec."Transport Method";
        recSpecItemLeadEntry."Unit of Measure Code" := rec."Unit of Measure Code";
        recSpecItemLeadEntry.Insert();


    end;
}