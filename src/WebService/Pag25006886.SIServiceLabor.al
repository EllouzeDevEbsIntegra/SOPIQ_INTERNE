page 25006886 "SI Service Labor"
{
    Caption = 'SI Service Labor';
    APIPublisher = 'sopiq';
    APIGroup = 'interne';
    APIVersion = 'v1.0';
    EntityName = 'SiServiceLabor';
    EntitySetName = 'SiServiceLabor';
    SourceTable = "Service Labor";
    ChangeTrackingAllowed = true;
    DelayedInsert = true;
    InsertAllowed = true;
    ModifyAllowed = true;
    DeleteAllowed = true;
    ODataKeyFields = SystemId;
    PageType = API;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(id; SystemId)
                {
                    ApplicationArea = All;
                    Caption = 'id', Locked = true;
                    Editable = false;
                }

                field(No; "No.")
                {
                    ApplicationArea = All;
                    Caption = 'Code', Locked = true;
                    Editable = false;
                }
                field(Description; Description)
                {
                    ApplicationArea = All;
                    Caption = 'Description';
                }
                field("MakeCode"; "Make Code")
                {
                    ApplicationArea = All;
                    Caption = 'Make Code';
                }

                field("GroupCode"; "Group Code")
                {
                    ApplicationArea = All;
                    Caption = 'Group Code';
                }
                field("LaborType"; "Labor Type")
                {
                    ApplicationArea = All;
                    Caption = 'Labor Type';
                }




            }

        }
    }


}