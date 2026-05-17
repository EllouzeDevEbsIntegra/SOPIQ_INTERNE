page 25006885 "SI Location API"
{
    Caption = 'SI Location API';
    APIPublisher = 'sopiq';
    APIGroup = 'interne';
    APIVersion = 'v1.0';
    EntityName = 'SiLocationAPI';
    EntitySetName = 'SiLocationAPI';
    SourceTable = Location;
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
                field(id; SystemId)
                {
                    ApplicationArea = All;
                    Caption = 'id', Locked = true;
                    Editable = false;
                }
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
            }

        }
    }


}