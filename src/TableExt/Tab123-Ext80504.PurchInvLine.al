tableextension 80504 "Purch. Inv. Line" extends "Purch. Inv. Line" //123
{
    fields
    {
        // Add changes to table fields here
        field(80503; Verified; Boolean)
        {
            DataClassification = ToBeClassified;
        }
        field(80504; Observation; Enum "Obs. Purch. Inv. Line")
        {
            DataClassification = ToBeClassified;
        }

    }

    var
        myInt: Integer;
}