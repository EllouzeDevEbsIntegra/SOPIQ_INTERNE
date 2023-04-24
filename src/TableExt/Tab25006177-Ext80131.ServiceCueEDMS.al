tableextension 80131 "Service Cue EDMS" extends "Service Cue EDMS"//25006177
{
    fields
    {
        // Add changes to table fields here
        field(50101; "CA MO"; Decimal)
        {
            Caption = 'Total CA MO';
            FieldClass = FlowField;
            CalcFormula = sum("Sales Invoice Line"."Amount" WHERE("Gen. Prod. Posting Group" = filter('MO')));

        }

        field(50102; "CA MO SRV RAPIDE"; Decimal)
        {
            Caption = 'Total CA MO SRV RAPIDE';
            FieldClass = FlowField;
            CalcFormula = sum("Sales Invoice Line"."Amount" WHERE("Gen. Prod. Posting Group" = filter('MO'), "Labor Groupe Code" = filter('SRV RAPIDE')));

        }

        field(50103; "CA MO SRV MECA"; Decimal)
        {
            Caption = 'Total CA MO SRV MECANIQUE';
            FieldClass = FlowField;
            CalcFormula = sum("Sales Invoice Line"."Amount" WHERE("Gen. Prod. Posting Group" = filter('MO'), "Labor Groupe Code" = filter('SRV MECA')));

        }

        field(50104; "CA MO SRV ELECT"; Decimal)
        {
            Caption = 'Total CA MO SRV ELECTRIQUE';
            FieldClass = FlowField;
            CalcFormula = sum("Sales Invoice Line"."Amount" WHERE("Gen. Prod. Posting Group" = filter('MO'), "Labor Groupe Code" = filter('SRV ELECT')));

        }

        field(50105; "CA MO SRV CARR"; Decimal)
        {
            Caption = 'Total CA MO SRV CARROSSERIE';
            FieldClass = FlowField;
            CalcFormula = sum("Sales Invoice Line"."Amount" WHERE("Gen. Prod. Posting Group" = filter('MO'), "Labor Groupe Code" = filter('SRV CARR')));

        }
    }

    var
        myInt: Integer;
}