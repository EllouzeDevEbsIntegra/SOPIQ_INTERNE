table 25006922 "Service Line Labor Task"
{
    DataClassification = ToBeClassified;

    fields
    {
        field(1; "Document No."; Code[20]) { Caption = 'Service Document No.'; TableRelation = "Service Header EDMS"."No."; }
        field(2; "Document Line No."; Integer) { Caption = 'Service Line No.'; }
        field(3; "Line No."; Integer) { Caption = 'Task Line No.'; }
        field(4; "Labor Code"; Code[20]) { Caption = 'N° Main Oeuvre'; TableRelation = "Service Labor"."No."; }
        field(5; "Labor Description"; Text[250]) { Caption = 'Main Oeuvre'; Editable = false; }

        field(6; "Task Code"; Code[20]) { Caption = 'Code Tâche'; TableRelation = "Service Task"."Code"; }
        field(7; "Task Description"; Text[250]) { Caption = 'Description Tâche'; Editable = false; }
        field(8; "Default Estimated Quantity"; Decimal) { Caption = 'Quantité estimée par défaut'; Editable = false; }
        field(9; "Estimated Quantity"; Decimal) { Caption = 'Quantité estimée'; }
        field(10; "Resource No."; Code[20])
        {
            Caption = 'Ressource affectée';
            TableRelation = Resource;

            trigger OnValidate()
            var
                ResRec: Record Resource;
            begin
                if "Resource No." = '' then
                    "Resource Name" := ''
                else
                    if ResRec.Get("Resource No.") then
                        "Resource Name" := ResRec.Name;
            end;
        }
        field(11; "Resource Name"; Text[100]) { Caption = 'Ressource affectée'; Editable = false; }
        field(100; "Temps Presté (Heures)"; Decimal)
        {
            Caption = 'Temps Presté (Heures)';
            CalcFormula =
        Sum("Serv. Labor Alloc. Application"."Finished Quantity (Hours)"
            WHERE(
                "Document No." = FIELD("Document No."),
                "Document Line No." = FIELD("Document Line No."),
                "Labor No." = FIELD("Labor Code"),
                "Task Code" = field("Task Code"),
                "Resource No." = FIELD("Resource No.")
            ));
            Editable = false;
            FieldClass = FlowField;
        }

    }

    keys
    {
        key(PK; "Document No.", "Document Line No.", "Line No.") { Clustered = true; }
    }

    trigger OnInsert()
    var
        TaskRec: Record "Service Line Labor Task";
        LastLineNo: Integer;
        SalesLine: Record "Sales Line";
        ServTask: Record "Service Task";
    begin
        // Calcul du prochain Line No.
        TaskRec.Reset();
        TaskRec.SetRange("Document No.", "Document No.");
        TaskRec.SetRange("Document Line No.", "Document Line No.");
        if TaskRec.FindLast() then
            LastLineNo := TaskRec."Line No."
        else
            LastLineNo := 0;

        "Line No." := LastLineNo + 10000;

        //  Description de la ligne commande
        SalesLine.Reset();
        SalesLine.SetRange("Document No.", "Document No.");
        SalesLine.SetRange("Line No.", "Document Line No.");
        if SalesLine.FindFirst() then
            "Labor Description" := SalesLine.Description;

        //  Description de la tâche associée (Service Task)
        if ServTask.Get("Task Code") then
            "Task Description" := ServTask.Description;
    end;


    procedure GenerateTasksFromLabor(LaborCode: Code[20]; DocumentNo: Code[20]; DocumentLineNo: Integer)
    var
        LaborTask: Record "Labor Tasks";
        NewTask: Record "Service Line Labor Task";
        MaxLineNo: Integer;
        LaborRec: Record "Service Labor";
        ServTask: Record "Service Task";
    begin
        NewTask.SetRange("Document No.", DocumentNo);
        NewTask.SetRange("Document Line No.", DocumentLineNo);
        if NewTask.FindLast() then
            MaxLineNo := NewTask."Line No."
        else
            MaxLineNo := 0;

        LaborTask.SetRange("Labor Code", LaborCode);
        if LaborTask.FindSet() then
            repeat
                MaxLineNo += 10000;

                NewTask.Init();
                NewTask."Document No." := DocumentNo;
                NewTask."Document Line No." := DocumentLineNo;
                NewTask."Line No." := MaxLineNo;
                NewTask."Labor Code" := LaborCode;

                //  Add Labor Description
                if LaborRec.Get(LaborCode) then
                    NewTask."Labor Description" := LaborRec.Description;

                //  Add Task Description depuis table Service Task
                if ServTask.Get(LaborTask."Task Code") then
                    NewTask."Task Description" := ServTask.Description;

                NewTask."Task Code" := LaborTask."Task Code";
                NewTask."Default Estimated Quantity" := LaborTask."Default Estimated Quantity";
                NewTask."Estimated Quantity" := LaborTask."Default Estimated Quantity";

                NewTask.Insert();
            until LaborTask.Next() = 0;
    end;


}
