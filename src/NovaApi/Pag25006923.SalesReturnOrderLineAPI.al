// Cycle de vente NOVA — Lignes retour de vente BROUILLON (Sales Line / Document Type = Return Order).
page 25006923 "Sales Return Order Line API"
{
    PageType = API;
    SourceTable = "Sales Line";
    APIPublisher = 'sopiq';
    APIGroup = 'interne';
    APIVersion = 'v1.0';
    EntityName = 'salesReturnOrderLine';
    EntitySetName = 'salesReturnOrderLines';
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
                field(unitPrice; Rec."Unit Price") { Caption = 'unitPrice'; }
                field(quantity; Rec.Quantity) { Caption = 'quantity'; }
                field(discountPercent; Rec."Line Discount %") { Caption = 'discountPercent'; }
                field(taxPercent; Rec."VAT %") { Caption = 'taxPercent'; }
                field(Amount; Rec.Amount) { Caption = 'Amount'; }
                field(AmountIncludingVAT; Rec."Amount Including VAT") { Caption = 'AmountIncludingVAT'; }
            }
        }
    }
}
