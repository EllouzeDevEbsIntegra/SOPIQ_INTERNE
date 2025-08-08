page 25006841 "Service Task API"
{
    PageType = API;
    SourceTable = "Service Task";
    APIPublisher = 'sopiq';
    APIGroup = 'interne';
    APIVersion = 'v1.0';
    EntityName = 'ServiceTask';
    EntitySetName = 'ServiceTask';
    ODataKeyFields = Code;
    DelayedInsert = true;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(Code; Code)
                {
                    Caption = 'Code';
                    ApplicationArea = Basic, Suite;
                }
                field(Description; Description)
                {
                    Caption = 'Description';
                    ApplicationArea = Basic, Suite;
                }
            }
        }
    }

    var


}
