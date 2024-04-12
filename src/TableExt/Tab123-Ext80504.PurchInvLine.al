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
        field(80505; "inventory"; Decimal)
        {

            CalcFormula = Sum("Item Ledger Entry".Quantity WHERE("Item No." = FIELD("No."),
                                                                  "isLocationExclu" = const(false),
                                                                  "Unit of Measure Code" = FIELD("Unit of Measure Code")));
            Caption = 'Stock Disponible';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }

    }

    var
        myInt: Integer;
}