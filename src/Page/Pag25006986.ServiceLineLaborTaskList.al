page 25006986 "Service Line Labor Task List"
{
    PageType = List;
    SourceTable = "Service Line Labor Task";
    Caption = 'Tâches de Main Oeuvre';

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                // field("Document No."; "Document No.") { }
                // field("Document Line No."; "Document Line No.") { }
                // field("Line No."; "Line No.") { }
                field("Labor Code"; "Labor Code") { }
                field("Labor Description"; "Labor Description") { ApplicationArea = All; }
                field("Task Code"; "Task Code") { }
                field("Task Description"; "Task Description") { }
                field("Default Estimated Quantity"; "Default Estimated Quantity") { }
                field("Estimated Quantity"; "Estimated Quantity") { }
                field("Resource No."; "Resource No.") { }
                field("Resource Name"; "Resource Name") { }
                field("Temps Presté (Heures)"; "Temps Presté (Heures)")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("Dupliquer Tâche")
            {
                Caption = 'Dupliquer la Tâche';
                Image = Copy;
                trigger OnAction()
                var
                    SelectedTask: Record "Service Line Labor Task";
                    NewTask: Record "Service Line Labor Task";
                    MaxLineNo: Integer;
                    Confirmed: Boolean;
                begin
                    //  Demande de confirmation avant duplication
                    Confirmed := Confirm('Voulez-vous dupliquer cette ligne de tâche ?');

                    if not Confirmed then
                        exit;

                    SelectedTask := Rec;

                    NewTask.SetRange("Document No.", SelectedTask."Document No.");
                    NewTask.SetRange("Document Line No.", SelectedTask."Document Line No.");
                    if NewTask.FindLast() then
                        MaxLineNo := NewTask."Line No."
                    else
                        MaxLineNo := 0;

                    MaxLineNo += 10000;

                    NewTask.Init();
                    NewTask.TransferFields(SelectedTask);
                    NewTask."Line No." := MaxLineNo;
                    NewTask."Resource No." := ''; // Affectation manuelle
                    NewTask.Insert(true);
                end;
            }


        }
    }
    trigger OnAfterGetRecord()
    begin
        CalcFields("Temps Presté (Heures)");
    end;

}
