table 25006920 "Service Task"
{
    DataClassification = ToBeClassified;

    fields
    {
        field(1; Code; code[10])
        {
            DataClassification = ToBeClassified;
            trigger OnValidate()
            begin
                if Code <> xRec.Code then begin
                    GetServSetup;
                    NoSeriesMgt.TestManual(ServSetup."Service Task Nos");
                end;
            end;
        }
        field(2; Description; Text[250])
        {
            DataClassification = ToBeClassified;
            Caption = 'Description';
        }
    }

    keys
    {
        key(Key1; Code)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        // Add changes to field groups here
    }

    var
        HasServSetup: Boolean;
        ServSetup: Record "Service Mgt. Setup EDMS";
        NoSeriesMgt: Codeunit NoSeriesManagement;

    trigger OnInsert()
    begin
        if Code = '' then begin
            GetServSetup;
            ServSetup.TestField("Service Task Nos");
            NoSeriesMgt.InitSeries(ServSetup."Service Task Nos", ServSetup."Service Task Nos", 0D, code, ServSetup."Service Task Nos");
        end;
    end;

    [Scope('OnPrem')]
    procedure GetServSetup()
    begin
        if not HasServSetup then begin
            ServSetup.Get;
            HasServSetup := true;
        end;
    end;

    procedure AssistEdit(): Boolean
    begin
        GetServSetup;
        ServSetup.TestField("Service Task Nos");
        if NoSeriesMgt.SelectSeries(ServSetup."Service Task Nos", ServSetup."Service Task Nos", ServSetup."Service Task Nos") then begin
            NoSeriesMgt.SetSeries(code);
            exit(true);
        end;
    end;

    trigger OnModify()
    begin

    end;

    trigger OnDelete()
    var
        LaborTasks: Record "Labor Tasks";
    begin
        LaborTasks.Reset();
        LaborTasks.SetRange("Task Code", Code);
        if LaborTasks.FindFirst() then
            Error('Vous ne pouvez pas supprimer cette tâche %1 car des tâches de main d''oeuvre y sont associées.', Code);

    end;

    trigger OnRename()
    begin

    end;

}