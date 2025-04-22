page 25006825 "SI Make API"
{
    Caption = 'SI Make API';
    APIPublisher = 'sopiq';
    APIGroup = 'interne';
    APIVersion = 'v1.0';
    EntityName = 'SiMakeAPI';
    EntitySetName = 'SiMakeAPI';
    SourceTable = Make;
    ChangeTrackingAllowed = true;
    DelayedInsert = true;
    InsertAllowed = true;
    ModifyAllowed = true;
    DeleteAllowed = true;
    ODataKeyFields = Code;
    PageType = API;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(Code; Code)
                {
                    ApplicationArea = All;
                    Caption = 'Code', Locked = true;
                    Editable = false;
                }
                field(Description; Name)
                {
                    ApplicationArea = All;
                    Caption = 'Name';
                }
                field(Picture; Picture)
                {
                    ApplicationArea = All;
                    Caption = 'Picture';
                }
            }

        }
    }


}