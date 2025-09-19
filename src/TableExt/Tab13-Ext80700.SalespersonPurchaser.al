tableextension 80700 "Salesperson/Purchaser" extends "Salesperson/Purchaser" //13 
{
    fields
    {
        // Add changes to table fields here
        field(80700; Departement; Enum "Departements")
        {
            DataClassification = ToBeClassified;
            Caption = 'Departement';
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