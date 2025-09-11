page 25006800 "ItemUpdateAPI"
{
    PageType = API;
    Caption = 'Item Update API';
    APIPublisher = 'sopiq';
    APIGroup = 'interne';
    APIVersion = 'v1.0';
    EntityName = 'ItemUpdate';
    EntitySetName = 'ItemUpdate';
    SourceTable = Item;
    DelayedInsert = true;
    ODataKeyFields = SystemId;
    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                field(id; SystemId)
                {
                    Caption = 'Id';
                    Editable = false;
                }
                // field("ItemNo"; "No.")
                // {
                //     ApplicationArea = All;
                //     Caption = 'Item No.';
                //     Editable = true;
                // }
                field(CountRef; "Count Item Manual ")
                {
                    ApplicationArea = All;
                    Caption = 'Count OEM';
                    Editable = true;
                }
            }
        }

    }

    trigger OnModifyRecord(): Boolean
    var
        recItem: Record Item;
        recEqvItem: Record Item;
        recMaster: Record Item;
        totalCount: Decimal;
    begin
        totalCount := 0;
        recItem.Reset();
        // recItem.SetRange("No.",rec."No.");
        recItem.SetRange(SystemId, rec.SystemId);
        recItem.FindFirst();

        if (recItem."Count Item Manual " <> Rec."Count Item Manual ") then begin
            recItem.TransferFields(rec, false);
            rec.TransferFields(recItem);
            totalCount := recItem."Count Item Manual ";
        end;

        recEqvItem.Reset();
        recEqvItem.SetRange(Produit, false);
        recEqvItem.SetRange("Reference Origine Lié", recItem."Reference Origine Lié");
        if recEqvItem.FindSet() then begin
            repeat
                if (recEqvItem."No." <> recItem."No.") then totalCount := totalCount + recEqvItem."Count Item Manual ";
            until recEqvItem.Next() = 0;
        end;

        recMaster.Reset();
        recMaster.SetRange("No.", recItem."Reference Origine Lié");
        recMaster.FindFirst();
        recMaster."Count Item Manual " := totalCount;
        recMaster.Modify();


    end;



}