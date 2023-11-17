tableextension 80362 "Location" extends "Location" //14
{
    fields
    {
        // Add changes to table fields here
        field(80362; ExculreStock; Boolean)
        {
            DataClassification = ToBeClassified;
            InitValue = false;
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