// Cycle de vente NOVA — Lignes avoir de vente ENREGISTRÉ / posté (Sales Cr.Memo Line). Lecture seule.
page 25006927 "Posted Sales Cr.Memo Line"
{
    PageType = API;
    SourceTable = "Sales Cr.Memo Line";
    APIPublisher = 'sopiq';
    APIGroup = 'interne';
    APIVersion = 'v1.0';
    EntityName = 'postedSalesCreditMemoLine';
    EntitySetName = 'postedSalesCreditMemoLines';
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
