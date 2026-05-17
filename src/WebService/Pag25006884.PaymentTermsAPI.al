page 25006884 "Payment Terms API"
{
    Caption = 'Payments Term', Locked = true;
    APIPublisher = 'sopiq';
    APIGroup = 'interne';
    APIVersion = 'v1.0';
    EntityName = 'paymentTermApi';
    EntitySetName = 'paymentTermsApi';
    ODataKeyFields = SystemId;
    PageType = API;
    SourceTable = "Payment Terms";
    DelayedInsert = true;
    InsertAllowed = true;
    ModifyAllowed = true;
    DeleteAllowed = true;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                
                field(id; SystemId)
                {
                    ApplicationArea = All;
                    Caption = 'Id', Locked = true;
                    Editable = false;
                }
                field(code; Code)
                {
                    Caption = 'Code';
                    ToolTip = 'Spécifie le code pour la condition de paiement.';
                }
                field(description; Description)
                {
                    Caption = 'Description';
                    ToolTip = 'Spécifie la description de la condition de paiement.';
                }
                field(dueDateCalculation; "Due Date Calculation")
                {
                    Caption = 'Due Date Calculation';
                    ToolTip = 'Spécifie la formule qui détermine comment calculer la date d''échéance.';
                }




            }
        }

    }

    actions
    {
    }
}
