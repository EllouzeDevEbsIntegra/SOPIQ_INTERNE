tableextension 80116 "Purch. Rcpt. Line" extends "Purch. Rcpt. Line"//121
{
    fields
    {
        field(80114; "Line Amount HT"; decimal)
        {
            DataClassification = ToBeClassified;
        }
        field(80115; "Line Amount"; decimal)
        {
            DataClassification = ToBeClassified;
        }
        field(80116; "Prix Special Vendor"; Decimal)
        {
            DataClassification = ToBeClassified;
        }

        field(80117; "Vendor Doc No."; code[50])
        {
            CalcFormula = lookup("Purch. Rcpt. Header"."Vendor Shipment No." where("No." = field("Document No.")));
            Editable = false;
            FieldClass = FlowField;
        }

        modify("New Unit Price")
        {
            trigger OnAfterValidate()
            begin
                "Prix Special Vendor" := "New Unit Price";
            end;
        }

        field(80118; "Actual Unit Price"; Decimal)
        {
            CalcFormula = lookup(Item."Unit Price" where("No." = field("No.")));
            Editable = false;
            FieldClass = FlowField;
        }

        field(80019; "Last Unit Price Devise"; Decimal)
        {
            Caption = 'Dernier prix Achat';
        }
        field(80020; "Last Unit Cost DT"; Decimal)
        {
            Caption = 'Dernier Coût';
        }

    }


    var
        SISalesCodeUnit: Codeunit SISalesCodeUnit;

    trigger OnAfterInsert()
    begin
        // "Line Amount HT" := "Unit Cost" * Quantity;
        // Message('%1', "Line Amount HT");
        // if ("VAT %" <> 0) then
        //     "Line Amount" := "Unit Cost" * Quantity * (1 + ("VAT %" / 100)) else
        //     "Line Amount" := "Unit Cost" * Quantity;
        // // @@@@@@ TO VERIFY
        // rec.Modify();
        SISalesCodeUnit.afterInsertRecptLine(rec);
    end;
}