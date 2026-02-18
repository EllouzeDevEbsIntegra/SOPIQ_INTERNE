page 25006883 "Zone Recouvrement API"
{
    PageType = API;
    APIPublisher = 'sopiq';
    APIGroup = 'interne';
    APIVersion = 'v1.0';
    EntityName = 'zoneRecouvrement';
    EntitySetName = 'zoneRecouvrements';
    Caption = 'Zone Recouvrement API';
    SourceTable = "Tax Area";
    ODataKeyFields = Code;
    DelayedInsert = true;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    Editable = false;

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field(code; Rec."code")
                {
                    Caption = 'Entry No.';
                }
                field(description; Rec."description")
                {
                    Caption = 'Entry No.';
                }

            }
        }
    }


}