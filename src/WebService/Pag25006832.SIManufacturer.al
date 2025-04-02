page 25006832 "SI Manufacturer"
{
    Caption = 'SI Manufacturer';
    APIPublisher = 'sopiq';
    APIGroup = 'interne';
    APIVersion = 'v1.0';
    EntityName = 'SiManufacturer';
    EntitySetName = 'SiManufacturer';
    SourceTable = Manufacturer;
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
                field(IDTecdOC; "ID TechDOC")
                {
                    ApplicationArea = All;
                    Caption = 'ID TechDOC';
                }
                field(NotActif; Actif)
                {
                    ApplicationArea = All;
                    Caption = 'Not Actif';
                }
                field(IsSpecific; IsSpecific)
                {
                    ApplicationArea = All;
                    Caption = 'IsSpecific';
                }

            }

        }
    }


}