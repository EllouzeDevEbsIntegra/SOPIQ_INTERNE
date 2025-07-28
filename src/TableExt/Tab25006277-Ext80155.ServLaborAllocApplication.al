tableextension 80155 "Serv. Labor Alloc. Application" extends "Serv. Labor Alloc. Application"
{
    fields
    {
        field(80155; "Date"; Date)
        {
            DataClassification = ToBeClassified;
            Caption = 'Date';
        }
        field(80154; "Labor No."; Code[20])
        {
            FieldClass = FlowField;
            Caption = 'Labor No.';
            CalcFormula = lookup("Service Line EDMS"."No." WHERE("Document No." = FIELD("Document No."),
                                                           "Line No." = field("Document Line No.")));
        }

        field(80156; "Begin Time"; DateTime)
        {
            DataClassification = ToBeClassified;
            Caption = 'Begin Time';
        }

        field(80157; "End Time"; DateTime)
        {
            DataClassification = ToBeClassified;
            Caption = 'End Time';
        }

        field(80158; "Constructor Temps"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'Constructor Temps';
        }

        field(80159; "Standard Time"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'Standard Time';
        }

        field(80160; "Task Code"; Code[20])
        {
            DataClassification = ToBeClassified;
            Caption = 'Task Code';
            TableRelation = "Service Task"."Code";
            trigger OnValidate()
            var
                ServTask: Record "Service Task";
            begin
                if "Task Code" = '' then begin
                    "Task Description" := '';
                end else begin
                    if ServTask.Get("Task Code") then begin
                        "Task Description" := ServTask.Description;
                    end;
                end;
            end;
        }

        field(80161; "Task Description"; Text[250])
        {
            DataClassification = ToBeClassified;
            Caption = 'Task Description';
            Editable = false;
        }
        field(80162; "Default Estimated Quantity"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'Task Description';
            Editable = false;
        }

        field(80163; "Estimated Quantity"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'Estimated Quantity';
            Editable = false;
        }
    }

    var
        myInt: Integer;
}
