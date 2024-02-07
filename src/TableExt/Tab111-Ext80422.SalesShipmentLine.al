tableextension 80422 "Sales Shipment Line" extends "Sales Shipment Line" //111
{
    fields
    {
        field(80422; solde; Boolean)
        {
            CalcFormula = lookup("Entete archive BS".solde where("No." = field("Document No.")));
            Caption = 'solde';
            FieldClass = FlowField;
        }

        field(80423; "Salesperson Code"; code[20])
        {
            CalcFormula = lookup("Sales Shipment Header"."Salesperson Code" where("No." = field("Document No.")));
            Caption = 'Code Vendeur';
            FieldClass = FlowField;
        }

        field(80417; "Qty BS To Invoice"; Decimal)
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


    trigger OnafterInsert()
    var
        ReturnReceiptLine: Record "Return Receipt Line";
        SalesShipmentHeader: Record "Sales Shipment Header";
    begin
        SalesShipmentHeader.Reset();
        if SalesShipmentHeader.get(rec."Document No.") then begin
            if SalesShipmentHeader.BS = true then begin
                ReturnReceiptLine.Reset();
                ReturnReceiptLine.SetRange("No.", rec."No.");
                ReturnReceiptLine.SetRange(BS, true);
                ReturnReceiptLine.SetRange("Quantity Invoiced", 0);
                ReturnReceiptLine.SetRange(Quantity, rec.Quantity);
                ReturnReceiptLine.SetFilter("Qty BS To Purchase", '>%1', 0);
                if ReturnReceiptLine.FindFirst() then begin
                    ReturnReceiptLine."Qty BS To Purchase" := 0;
                    ReturnReceiptLine."Document No BS Inverse" := rec."Document No.";
                    ReturnReceiptLine."Line No BS Inverse" := rec."Line No.";
                    rec."Qty BS To Invoice" := 0;
                    rec."Document No BS Inverse" := ReturnReceiptLine."Document No.";
                    rec."Line No BS Inverse" := ReturnReceiptLine."Line No.";
                    ReturnReceiptLine.Modify();
                end
                else begin
                    rec."Qty BS To Invoice" := rec.Quantity;
                end;
                rec.Modify(true);
            end;

        end;
    end;



}