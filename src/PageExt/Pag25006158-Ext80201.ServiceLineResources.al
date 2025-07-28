pageextension 80201 "Service Line Resources" extends "Service Line Resources" //25006158
{
    layout
    {
        modify(RemainingQuantityHours)
        {
            ApplicationArea = All;
            Visible = false;
        }
        modify(RemainingCostAmount)
        {
            ApplicationArea = All;
            Visible = false;
        }

        modify(UnitCost)
        {
            ApplicationArea = All;
            Visible = false;
        }
        modify(CostAmount)
        {
            ApplicationArea = All;
            Visible = false;
        }

        modify(FinishedCostAmount)
        {
            ApplicationArea = All;
            Visible = false;
        }

        addfirst(Group)
        {
            field("Date"; "Date")
            {
                ApplicationArea = All;
                Caption = 'Date';
            }
            field("Labor Code"; "Labor No.")
            {
                ApplicationArea = All;
                Caption = 'Main Oeuvre';
            }
        }
        addafter(ResourceNo)
        {
            field("Task Code"; "Task Code")
            {
                ApplicationArea = All;
                Caption = 'Code Tâche';
                trigger OnValidate()
                var
                    ServiceTaskRec: Record "Service Task";
                    LaborTasks: Record "Labor Tasks";
                begin
                    if ServiceTaskRec.Get("Task Code") then
                        "Task Description" := ServiceTaskRec.Description
                    else
                        "Task Description" := '';

                    LaborTasks.Reset();
                    LaborTasks.SetRange("Labor Code", "Labor No.");
                    LaborTasks.SetRange("Task Code", "Task Code");
                    if LaborTasks.FindFirst() then begin
                        "Estimated Quantity" := LaborTasks."Default Estimated Quantity";
                        "Default Estimated Quantity" := LaborTasks."Default Estimated Quantity";
                    end else begin
                        "Estimated Quantity" := 0;
                    end;
                end;
            }

            field("Task Description"; "Task Description")
            {
                ApplicationArea = All;
                Caption = 'Description Tâche';
            }
            field("Default Estimated Quantity"; "Default Estimated Quantity")
            {
                ApplicationArea = All;
                Caption = 'Quantité Par Défaut Estimée';
                Style = Unfavorable;
            }
            field("Estimated Quantity"; "Estimated Quantity")
            {
                ApplicationArea = All;
                Caption = 'Quantité Estimée';
            }

        }

        addbefore(Travel)
        {
            field("Begin Time"; "Begin Time")
            {
                ApplicationArea = All;
                Caption = 'Heure Début';
            }

            field("End Time"; "End Time")
            {
                ApplicationArea = All;
                Caption = 'Heure Fin';
            }

            field("Constructor Temps"; "Constructor Temps")
            {
                ApplicationArea = All;
                Caption = 'Temps Constructeur';
            }

            field("Standard Time"; "Standard Time")
            {
                ApplicationArea = All;
                Caption = 'Temps Standard';
            }

        }
    }

    actions
    {
    }

    var
        myInt: Integer;
}
