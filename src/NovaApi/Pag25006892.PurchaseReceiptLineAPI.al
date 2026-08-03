// Cycle d'achat NOVA — Lignes de réception d'achat enregistrée (Purch. Rcpt. Line). Lecture seule.
page 25006892 "Purchase Receipt Line API"
{
    PageType = API;
    SourceTable = "Purch. Rcpt. Line";
    APIPublisher = 'sopiq';
    APIGroup = 'interne';
    APIVersion = 'v1.0';
    EntityName = 'purchaseReceiptLine';
    EntitySetName = 'purchaseReceiptLines';
    ODataKeyFields = SystemId;
    DelayedInsert = true;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field(id; Rec.SystemId) { Caption = 'id'; }
                field(documentNo; Rec."Document No.") { Caption = 'documentNo'; }
                field(sequence; Rec."Line No.") { Caption = 'sequence'; }
                field(lineType; Rec.Type) { Caption = 'lineType'; }
                field(lineObjectNumber; Rec."No.") { Caption = 'lineObjectNumber'; }
                field(description; Rec.Description) { Caption = 'description'; }
                field(description2; Rec."Description 2") { Caption = 'description2'; }
                field(unitOfMeasureCode; Rec."Unit of Measure Code") { Caption = 'unitOfMeasureCode'; }
                field(quantity; Rec.Quantity) { Caption = 'quantity'; }
                field(directUnitCost; Rec."Direct Unit Cost") { Caption = 'directUnitCost'; }
                field(discountPercent; Rec."Line Discount %") { Caption = 'discountPercent'; }
                field(amountExcludingTax; Rec."Line Amount") { Caption = 'amountExcludingTax'; }
            }
        }
    }
}
