tableextension 80390 "Mini Customer Template" extends "Mini Customer Template"//1300
{
    fields
    {
        // Add changes to table fields here
        field(80390; "Location Code"; Code[20])
        {
            Caption = 'Location Code';
            TableRelation = "Location";
        }
    }

    var
        myInt: Integer;
}