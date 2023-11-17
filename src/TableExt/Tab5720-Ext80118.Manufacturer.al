tableextension 80118 "Manufacturer" extends "Manufacturer" //5720
{
    fields
    {
        field(80118; "Actif"; Boolean)
        {
            InitValue = true;
            DataClassification = ToBeClassified;
        }

        field(80119; IsSpecific; Boolean)
        {
            InitValue = false;
            DataClassification = ToBeClassified;
        }
    }

    var
        myInt: Integer;
}