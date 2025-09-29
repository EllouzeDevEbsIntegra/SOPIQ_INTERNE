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
        field(80600; "Count Master"; Integer)
        {
            Caption = 'Count Master';
            FieldClass = FlowField;
            CalcFormula = lookup(item."Count Item Manual " where("No." = field("No.")));
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