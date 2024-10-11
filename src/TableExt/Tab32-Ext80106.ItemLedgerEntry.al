tableextension 80106 "Item Ledger Entry" extends "Item Ledger Entry"//32
{
    fields
    {
        // Add changes to table fields here
        field(80105; itemDescription; text[100])
        {
            CalcFormula = lookup(item.Description where("No." = field("Item No.")));
            Editable = false;
            FieldClass = FlowField;
        }

        field(80106; isLocationExclu; Boolean)
        {
            CalcFormula = lookup(Location."ExculreStock" where("Code" = field("Location Code")));
            Editable = false;
            FieldClass = FlowField;
        }

        field(80107; isImportLocation; Boolean)
        {
            CalcFormula = lookup(Location.Import where("Code" = field("Location Code")));
            Editable = false;
            FieldClass = FlowField;
        }

        field(80108; year; Integer)
        {
            DataClassification = ToBeClassified;
        }

        field(50024; "N° Doc Frs"; code[35])
        {
            AutoFormatType = 1;
            CalcFormula = lookup("Purch. Rcpt. Header"."Vendor Shipment No." where("No." = field("Document No.")));
            Caption = 'N° Doc Frs';
            Editable = false;
            FieldClass = FlowField;
        }

        field(50025; "Cmd Achat"; code[35])
        {
            AutoFormatType = 1;
            CalcFormula = lookup("Purch. Rcpt. Header"."Order No." where("No." = field("Document No.")));
            Caption = 'Cmd Achat';
            Editable = false;
            FieldClass = FlowField;
        }

        field(50026; "Cmd Vente"; code[35])
        {
            AutoFormatType = 1;
            CalcFormula = lookup("Sales Shipment Header"."Order No." where("No." = field("Document No.")));
            Caption = 'Cmd Vente';
            Editable = false;
            FieldClass = FlowField;
        }
        // field(50027; "PurchInvNo"; code[20])
        // {
        //     AutoFormatType = 1;
        //     CalcFormula = lookup("Purch. Inv. Line"."Document No." where("Receipt No." = field("Document No."), "Receipt Line No." = field("Document Line No.")));
        //     FieldClass = FlowField;
        // }
        // field(50028; "PurchInvDocDate"; Date)
        // {
        //     AutoFormatType = 1;
        //     CalcFormula = lookup("Purch. Inv. Header"."Document Date" where("No." = field(PurchInvNo)));
        //     FieldClass = FlowField;
        // }

    }

    var
        myInt: Integer;

    trigger OnAfterModify()
    var
        recSpecItemLeadEntry: Record "Specific Item Ledger Entry";
    begin
        recSpecItemLeadEntry.Reset();
        recSpecItemLeadEntry.SetRange("Entry No.", "Entry No.");
        if recSpecItemLeadEntry.FindFirst() then begin
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
            recSpecItemLeadEntry.Year := DATE2DMY("Posting Date", 3);
            recSpecItemLeadEntry.Modify();
        end;
    end;

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
        recSpecItemLeadEntry.Year := DATE2DMY("Posting Date", 3);
        recSpecItemLeadEntry.Insert();


    end;

    trigger OnAfterInsert()
    begin
        year := DATE2DMY("Posting Date", 3);
    end;
}