tableextension 80277 "Item Journal Line" extends "Item Journal Line" //83
{
    fields
    {
        // Add changes to table fields here
        field(80277; validate; Boolean)
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