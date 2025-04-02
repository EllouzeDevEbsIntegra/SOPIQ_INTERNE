tableextension 80321 Vendor extends Vendor //23
{
    fields
    {
        // Add changes to table fields here
        field(80321; "Default Marge"; Decimal)
        {
            DataClassification = ToBeClassified;
        }

        field(80322; "Default Discount"; Decimal)
        {
            DataClassification = ToBeClassified;
        }
        field(80323; "Frs Local"; Boolean)
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
}