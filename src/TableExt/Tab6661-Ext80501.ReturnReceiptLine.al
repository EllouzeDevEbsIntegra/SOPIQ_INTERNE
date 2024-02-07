tableextension 80501 "Return Receipt Line" extends "Return Receipt Line" //6661
{
    fields
    {
        // Add changes to table fields here
        field(80415; solde; Boolean)
        {
            CalcFormula = lookup("Return Receipt Header".solde where("No." = field("Document No.")));
            Caption = 'solde';
            FieldClass = FlowField;
        }
        field(80416; BS; Boolean)
        {
            DataClassification = ToBeClassified;
        }



        field(80417; "Qty BS To Purchase"; Decimal)
        {
            DataClassification = ToBeClassified;
        }

        field(80418; "Document No BS Inverse"; code[20])
        {
            DataClassification = ToBeClassified;
        }

        field(80419; "Line No BS Inverse"; Integer)
        {
            DataClassification = ToBeClassified;
        }
    }

    keys
    {
        // Add changes to keys here
    }

    fieldgroups
    {
        // Add changes to field groups here
    }

    var
        myInt: Integer;

    trigger OnBeforeInsert()
    var
        returnHeader: Record "Return Receipt Header";
    begin
        returnHeader.Reset();
        returnHeader.SetRange("No.", Rec."Document No.");
        if returnHeader.FindFirst() then begin
            if returnHeader.BS = true then begin
                rec.BS := true;
            end
        end
    end;

    trigger OnafterInsert()
    var
        SalesShipmentLine: Record "Sales Shipment Line";
        ReturnReceiptHeader: Record "Return Receipt Header";
    begin
        ReturnReceiptHeader.Reset();
        if ReturnReceiptHeader.get(rec."Document No.") then begin
            if ReturnReceiptHeader.BS = true then begin
                SalesShipmentLine.Reset();
                SalesShipmentLine.SetRange("No.", rec."No.");
                SalesShipmentLine.SetRange(BS, true);
                SalesShipmentLine.SetRange("Quantity Invoiced", 0);
                SalesShipmentLine.SetRange(Quantity, rec.Quantity);
                SalesShipmentLine.SetFilter("Qty BS To Invoice", '>%1', 0);
                if SalesShipmentLine.FindFirst() then begin
                    SalesShipmentLine."Qty BS To Invoice" := 0;
                    SalesShipmentLine."Document No BS Inverse" := rec."Document No.";
                    SalesShipmentLine."Line No BS Inverse" := rec."Line No.";
                    rec."Qty BS To Purchase" := 0;
                    rec."Document No BS Inverse" := SalesShipmentLine."Document No.";
                    rec."Line No BS Inverse" := rec."Line No.";
                    SalesShipmentLine.Modify();
                end
                else begin
                    rec."Qty BS To Purchase" := rec.Quantity;
                end;
                rec.Modify(true);
            end;
        end;
    end;
}