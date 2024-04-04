tableextension 80501 "Return Receipt Line" extends "Return Receipt Line" //6661
{

    fields
    {
        // Add changes to table fields here
        field(80129; "Cust Name Imprime"; Code[200])
        {
            CalcFormula = lookup("Return Receipt Header".custNameImprime WHERE("Bill-to Customer No." = field("Bill-to Customer No.")));
            Caption = 'Client Imprimé';
            Editable = false;
            FieldClass = FlowField;
        }
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
        salesCodeUnit: Codeunit SISalesCodeUnit;
    begin
        salesCodeUnit.afterInsertReturnReceiptLine(rec);
    end;
}