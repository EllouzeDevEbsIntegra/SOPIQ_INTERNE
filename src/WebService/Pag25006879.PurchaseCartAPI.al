page 25006879 "Purchase Cart API"
{
    PageType = API;
    APIPublisher = 'sopiq';
    APIGroup = 'interne';
    APIVersion = 'v1.0';
    EntityName = 'purchaseCartLine';
    EntitySetName = 'purchaseCartLines';
    Caption = 'Purchase Cart API';
    SourceTable = "Purchase Cart";
    ODataKeyFields = "Line No.";
    DelayedInsert = true;
    InsertAllowed = true;
    ModifyAllowed = true;
    DeleteAllowed = false;
    Editable = true;

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field(lineNo; Rec."Line No.")
                {
                    Caption = 'Line No.';
                    Editable = false;
                }
                field(buyFromVendorNo; Rec."Buy-from Vendor No.")
                {
                    Caption = 'Buy-from Vendor No.';
                }
                field(itemNo; Rec."No.")
                {
                    Caption = 'Item No.';
                }
                field(description; Rec.Description)
                {
                    Caption = 'Description';
                }
                field(quantity; Rec.Quantity)
                {
                    Caption = 'Quantity';
                }
                field(directUnitCost; Rec."Direct Unit Cost")
                {
                    Caption = 'Direct Unit Cost';
                }
                field(compareQuoteNo; Rec."Compare Quote No.")
                {
                    Caption = 'Compare Quote No.';
                }
                field(addedDate; Rec."Added Date")
                {
                    Caption = 'Added Date';
                    Editable = false;
                }
                field(status; Rec.Status)
                {
                    Caption = 'Status';
                    Editable = false;
                }
                field(purchaseQuoteNo; Rec."Purchase Quote No.")
                {
                    Caption = 'Purchase Quote No.';
                    Editable = false;
                }
            }
        }
    }

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        // Assigner les valeurs par défaut lors de la création via l'API
        Rec.Status := Rec.Status::New;
        Rec."Added Date" := Today;
        exit(true);
    end;

    trigger OnModifyRecord(): Boolean
    var
        CannotModifyErr: Label 'Cannot modify a line that has status %1.', Comment = '%1 = Status';
    begin
        // Empêcher la modification si la ligne a déjà été transformée en devis
        if xRec.Status = xRec.Status::"Converted to Quote" then
            Error(CannotModifyErr, xRec.Status);

        exit(true);
    end;

    trigger OnDeleteRecord(): Boolean
    var
        CannotDeleteErr: Label 'Cannot delete a line that has status %1.', Comment = '%1 = Status';
    begin
        // Empêcher la suppression si la ligne a déjà été transformée en devis
        if Rec.Status = Rec.Status::"Converted to Quote" then
            Error(CannotDeleteErr, Rec.Status);

        exit(true);
    end;
}