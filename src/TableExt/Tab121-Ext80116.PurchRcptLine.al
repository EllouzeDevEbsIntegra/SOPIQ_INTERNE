tableextension 80116 "Purch. Rcpt. Line" extends "Purch. Rcpt. Line"//121
{
    fields
    {
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

    }


    var
        myInt: Integer;
}