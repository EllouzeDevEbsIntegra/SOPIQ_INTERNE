tableextension 80100 "Sales line" extends "Sales line" //37
{
    fields
    {
        modify("No.")
        {
            trigger OnAfterValidate()
            begin
                "Initial Unit Price" := "Unit Price";
            end;
        }

        modify("Unit Price")
        {
            trigger OnAfterValidate()
            begin
                if ("Unit Price" = "Initial Unit Price") Then begin
                    "Price modified" := false;
                end
                else
                    if ("Initial Unit Price" = 0) then begin
                        "Price modified" := false;
                    end
                    else
                        "Price modified" := true;

            end;
        }

        field(50100; "Initial Unit Price"; Decimal)
        {
            DataClassification = ToBeClassified;
            Editable = false;
        }

        field(50101; "Price modified"; Boolean)
        {
            DataClassification = ToBeClassified;
            InitValue = false;
            Editable = false;
        }
        field(14; "Ctrl Modified Price"; Boolean)
        {
            DataClassification = ToBeClassified;
            InitValue = false;
        }
    }

    var
        myInt: Integer;
}