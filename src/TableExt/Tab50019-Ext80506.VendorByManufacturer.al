tableextension 80506 "Vendor By Manufacturer" extends "Vendor By Manufacturer" //50019
{
    fields
    {
        // Add changes to table fields here
        field(80506; "Vendor No Format"; Text[50])
        {
            DataClassification = ToBeClassified;
        }
    }

    var
        myInt: Integer;
}