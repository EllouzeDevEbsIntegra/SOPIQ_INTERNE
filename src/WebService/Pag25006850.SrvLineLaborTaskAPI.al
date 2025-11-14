page 25006850 "Srv Line Labor Task API"
{
    PageType = API;
    SourceTable = "Service Line Labor Task";
    APIPublisher = 'sopiq';
    APIGroup = 'interne';
    APIVersion = 'v1.0';
    EntityName = 'SrvLineLaborTask';
    EntitySetName = 'SrvLineLaborTask';
    ODataKeyFields = "Document No.", "Document Line No.", "Line No.";
    DelayedInsert = true;
    ModifyAllowed = true;
    InsertAllowed = true;
    DeleteAllowed = true;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(DocumentNo; "Document No.") { Caption = 'Service Document No.'; }
                field(DocumentLineNo; "Document Line No.") { Caption = 'Service Line No.'; }
                field(LineNo; "Line No.") { Caption = 'Task Line No.'; }

                field(LaborCode; "Labor Code") { Caption = 'N° Main Oeuvre'; }
                field(LaborDescription; "Labor Description") { Caption = 'Main Oeuvre'; Editable = false; }

                field(TaskCode; "Task Code") { Caption = 'Code Tâche'; }
                field(TaskDescription; "Task Description") { Caption = 'Description Tâche'; Editable = false; }

                field(DefaultEstimatedQuantity; "Default Estimated Quantity") { Caption = 'Quantité estimée par défaut'; Editable = false; }
                field(EstimatedQuantity; "Estimated Quantity") { Caption = 'Quantité estimée'; }

                field(ResourceNo; "Resource No.") { Caption = 'Ressource affectée'; }
                field(ResourceName; "Resource Name") { Caption = 'Nom Ressource'; Editable = false; }

                field(TempsPreste; "Temps Presté (Heures)") { Caption = 'Temps Presté'; Editable = false; }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        rec.CalcFields("Temps Presté (Heures)");
    end;




}
