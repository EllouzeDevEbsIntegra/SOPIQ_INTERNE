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
        field(80278; "LM Ready For Validation"; boolean)
        {
            Caption = 'Prêt à la validation';
            DataClassification = ToBeClassified;
        }

        field(80730; inventory; Decimal)
        {
            CalcFormula = Sum("Item Ledger Entry".Quantity WHERE("Item No." = FIELD("Item No."), "Location Code" = field("Location Code")));
            Caption = 'Inventory';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
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