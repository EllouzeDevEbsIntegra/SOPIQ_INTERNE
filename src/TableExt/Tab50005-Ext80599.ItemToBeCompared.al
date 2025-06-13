tableextension 80599 "Item To Be Compared" extends "Item To Be Compared" // 50005
{
    fields
    {
        // Add changes to table fields here
        field(80599; "Selected No"; Code[20])
        {
            Caption = 'Article Sélectionné';
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