tableextension 80116 "Purch. Rcpt. Line" extends "Purch. Rcpt. Line"//121
{
    fields
    {
        field(80116; "Prix Special Vendor"; Decimal)
        {
            DataClassification = ToBeClassified;
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