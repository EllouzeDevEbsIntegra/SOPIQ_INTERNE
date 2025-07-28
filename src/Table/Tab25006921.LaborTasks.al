table 25006921 "Labor Tasks"
{
    DataClassification = ToBeClassified;

    fields
    {
        field(1; "Labor Code"; code[10])
        {
            DataClassification = ToBeClassified;
            TableRelation = "Service Labor"."No.";

        }
        field(2; "Labor Description"; Text[100])
        {
            FieldClass = FlowField;
            caption = 'Description Main Oeuvre';
            CalcFormula = lookup("Service Labor"."Description" where("No." = field("Labor Code")));
            editable = false;
        }
        field(3; "Task Code"; code[10])
        {
            DataClassification = ToBeClassified;
            TableRelation = "Service Task".Code;
        }
        field(4; "Task Description"; Text[100])
        {
            FieldClass = FlowField;
            caption = 'Description Tâche';
            CalcFormula = lookup("Service Task".Description where(Code = field("Task Code")));
            editable = false;
        }
        field(5; "Default Estimated Quantity"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'Quantité estimée par défaut';
        }

    }

    keys
    {
        key(Key1; "Labor Code", "Task Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        // Add changes to field groups here
    }

    var
        myInt: Integer;

    trigger OnInsert()
    begin

    end;

    trigger OnModify()
    begin

    end;

    trigger OnDelete()
    begin

    end;

    trigger OnRename()
    begin

    end;

}