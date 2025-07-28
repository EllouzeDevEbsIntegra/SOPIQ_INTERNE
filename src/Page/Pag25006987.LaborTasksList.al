page 25006987 "Labor Tasks List"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "Labor Tasks";

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Labor Code"; "Labor Code")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Code Main Oeuvre';
                }
                field("Labor Description"; "Labor Description")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Description Main Oeuvre';
                }
                field("Task Code"; "Task Code")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Code Tâche';
                }
                field("Task Description"; "Task Description")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Description Tâche';
                }
                field("Default Estimated Quantity"; "Default Estimated Quantity")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Qte Estimée par défaut';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ActionName)
            {

                trigger OnAction()
                begin

                end;
            }
        }
    }

    var
        myInt: Integer;

    trigger OnAfterGetRecord()
    begin
        rec.CalcFields("Labor Description", "Task Description");
    end;
}