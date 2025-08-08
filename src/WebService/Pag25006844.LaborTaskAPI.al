page 25006844 "Labor Task API"
{
    PageType = API;
    SourceTable = "Labor Tasks";
    APIPublisher = 'sopiq';
    APIGroup = 'interne';
    APIVersion = 'v1.0';
    EntityName = 'LaborTask';
    EntitySetName = 'LaborTask';
    ODataKeyFields = "Labor Code", "Task Code";
    DelayedInsert = true;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(LaborCode; "Labor Code")
                {
                    ApplicationArea = All;
                    Caption = 'Code de Main Oeuvre';
                }
                field(LaborDescription; "Labor Description")
                {
                    ApplicationArea = All;
                    Caption = 'Description de la Main Oeuvre';
                }
                field(TaskCode; "Task Code")
                {
                    ApplicationArea = All;
                    Caption = 'Code de Tâche';
                }
                field(TaskDescription; "Task Description")
                {
                    ApplicationArea = All;
                    Caption = 'Description de la Tâche';
                }
                field(DefaultEstimatedQuantity; "Default Estimated Quantity")
                {
                    ApplicationArea = All;
                    Caption = 'Quantité Estimée par Défaut';
                }

            }
        }
    }

    var

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        CalcFields("Labor Description", "Task Description");
        if ("Labor Code" = '') then
            Error('Le code de main d''oeuvre est obligatoire.');

        if ("Task Code" = '') then
            Error('Le code de tâche est obligatoire.');

        //  Vérification de la quantité estimée
        if "Default Estimated Quantity" <= 0 then
            Error('La quantité estimée doit être supérieure à zéro.');

        exit(true);
    end;
}

