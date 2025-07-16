page 25006827 "SI Model Version API"
{
    Caption = 'SI Model Version API';
    APIPublisher = 'sopiq';
    APIGroup = 'interne';
    APIVersion = 'v1.0';
    EntityName = 'SiModelVersionAPI';
    EntitySetName = 'SiModelVersionAPI';
    SourceTable = Item;
    SourceTableView = where("Item Type" = const(2));
    ChangeTrackingAllowed = true;
    DelayedInsert = true;
    ODataKeyFields = id;
    PageType = API;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(id; id)
                {
                    ApplicationArea = All;
                    Caption = 'id', Locked = true;
                    Editable = false;
                }
                field(Code; "No.")
                {
                    ApplicationArea = All;
                    Caption = 'Code';
                }

                field(Make; "Make Code")
                {
                    ApplicationArea = All;
                    Caption = 'Make Code';
                }
                field(Model; "Model Code")
                {
                    ApplicationArea = All;
                    Caption = 'Model Code';
                }
                field(ItemType; "Item Type")
                {
                    ApplicationArea = All;
                    Caption = 'Item Type';
                }
                field(TrackingCode; "Item Tracking Code")
                {
                    ApplicationArea = All;
                    Caption = 'Item Tracking Code';
                }
                field(finition; "Commercial Description")
                {
                    ApplicationArea = All;
                    Caption = 'Commercial Description';
                }

            }

        }
    }

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        rec."Item Tracking Code" := 'SNALL';
    end;
}