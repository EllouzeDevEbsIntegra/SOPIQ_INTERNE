tableextension 80130 "Sales Invoice Line" extends "Sales Invoice Line" //113
{
    fields
    {
        // Add changes to table fields here
        field(80130; "Labor Groupe Code"; Code[50])
        {
            AutoFormatType = 1;
            CalcFormula = lookup("Service Labor"."Group Code" WHERE("No." = field("Order Line Type No.")));
            Caption = 'Type MO';
            Editable = false;
            FieldClass = FlowField;
        }

        field(80131; "Initial Unit Price"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = lookup("Sales Line"."Initial Unit Price" WHERE("Line No." = field("Order Line No."), "Document No." = field("Order No.")));
            Caption = 'Prix Initial';
            Editable = false;
            FieldClass = FlowField;
        }

        field(80132; "Initial Discount"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = lookup("Sales Line"."Initial Discount" WHERE("Line No." = field("Order Line No."), "Document No." = field("Order No.")));
            Caption = 'Remise Initial';
            Editable = false;
            FieldClass = FlowField;
        }

        field(80133; "Price modified"; Boolean)
        {
            AutoFormatType = 1;
            CalcFormula = lookup("Sales Line"."Ctrl Modified Price" WHERE("Line No." = field("Order Line No."), "Document No." = field("Order No.")));
            Caption = 'Prix Modifie Cmd';
            Editable = false;
            FieldClass = FlowField;
        }
        field(80134; "Discount modified"; Boolean)
        {
            AutoFormatType = 1;
            CalcFormula = lookup("Sales Line"."Ctrl Modified Discount" WHERE("Line No." = field("Order Line No."), "Document No." = field("Order No.")));
            Caption = 'Remise Modifie Cmd';
            Editable = false;
            FieldClass = FlowField;
        }
        field(80135; "Ctrl Invoice Modified"; Boolean)
        {
            DataClassification = ToBeClassified;
            InitValue = false;
        }
    }

    var
        myInt: Integer;
}