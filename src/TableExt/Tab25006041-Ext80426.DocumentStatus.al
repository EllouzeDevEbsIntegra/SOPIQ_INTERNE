tableextension 80426 "Document Status" extends "Document Status" //25006041
{
    fields
    {
        // Add changes to table fields here
        field(80426; SendMsg; Boolean)
        {
            DataClassification = ToBeClassified;
        }

        field(80427; Message; Text[145])
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