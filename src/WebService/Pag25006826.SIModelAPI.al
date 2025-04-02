page 25006826 "SI Model API"
{
    Caption = 'SI Make API';
    APIPublisher = 'sopiq';
    APIGroup = 'interne';
    APIVersion = 'v1.0';
    EntityName = 'SiModelAPI';
    EntitySetName = 'SiModelAPI';
    SourceTable = Model;
    ChangeTrackingAllowed = true;
    DelayedInsert = true;
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
                field(Name; "Commercial Name")
                {
                    ApplicationArea = All;
                    Caption = 'Commercial Name';
                }
                field(Make; "Make Code")
                {
                    ApplicationArea = All;
                    Caption = 'Make Code';
                }

            }

        }
    }
    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        TestField("Make Code");
        TestField(Code);
    end;

    trigger OnDeleteRecord(): Boolean
    var
        Item: Record Item;
        ServiceLedger: Record "Service Ledger Entry EDMS";
    begin
        Item.Reset;
        Item.SetCurrentkey("Item Type", "Make Code", "Model Code");
        Item.SetRange("Item Type", Item."item type"::"Model Version");
        Item.SetRange("Make Code", "Make Code");
        Item.SetRange("Model Code", Code);
        if Item.FindFirst then
            Error(Text001, TableCaption, Code, Item.TableCaption);

        ServiceLedger.Reset;
        ServiceLedger.SetCurrentkey("Make Code", "Model Code", "Model Version No.", "Posting Date");
        ServiceLedger.SetRange("Make Code", "Make Code");
        ServiceLedger.SetRange("Model Code", Code);
        if ServiceLedger.FindFirst then
            Error(Text001, TableCaption, Code, ServiceLedger.TableCaption);
    end;

    var
        Text001: label 'You cannot delete %1 %2 because there is at least one %3 that includes this model.';
}