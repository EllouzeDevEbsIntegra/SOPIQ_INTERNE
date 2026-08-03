// Cycle d'achat NOVA — Lignes de retour d'achat (Purchase Line / Document Type = Return Order).
page 25006913 "Purchase Return Order Line API"
{
    PageType = API;
    SourceTable = "Purchase Line";
    APIPublisher = 'sopiq';
    APIGroup = 'interne';
    APIVersion = 'v1.0';
    EntityName = 'purchaseReturnOrderLine';
    EntitySetName = 'purchaseReturnOrderLines';
    ODataKeyFields = SystemId;
    DelayedInsert = true;
    SourceTableView = WHERE("Document Type" = CONST("Return Order"));

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
                field(amountIncludingTax; Rec."Amount Including VAT") { Caption = 'amountIncludingTax'; }
                field(taxPercent; Rec."VAT %") { Caption = 'taxPercent'; }
            }
        }
    }
}
