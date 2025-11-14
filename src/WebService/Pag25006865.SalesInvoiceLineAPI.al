page 25006865 "Sales Invoice Line API"
{
    PageType = API;
    SourceTable = "Sales Invoice Line";
    APIPublisher = 'sopiq';
    APIGroup = 'interne';
    APIVersion = 'v1.0';
    EntityName = 'salesInvoiceLine';
    EntitySetName = 'salesInvoiceLines';
    ODataKeyFields = SystemId;
    DelayedInsert = true;

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field(id; Rec.SystemId)
                {
                    Caption = 'id';
                }
                field(documentNo; Rec."Document No.")
                {
                    Caption = 'documentNo';
                }
                field(sequence; Rec."Line No.")
                {
                    Caption = 'sequence';
                }
                field(lineType; Rec.Type)
                {
                    Caption = 'lineType';
                }
                field(lineObjectNumber; Rec."No.")
                {
                    Caption = 'lineObjectNumber';
                }
                field(description; Rec.Description)
                {
                    Caption = 'description';
                }
                field(description2; Rec."Description 2")
                {
                    Caption = 'description2';
                }
                field(unitOfMeasureCode; Rec."Unit of Measure Code")
                {
                    Caption = 'unitOfMeasureCode';
                }
                field(unitPrice; Rec."Unit Price")
                {
                    Caption = 'unitPrice';
                }
                field(quantity; Rec.Quantity)
                {
                    Caption = 'quantity';
                }
                field(discountPercent; Rec."Line Discount %")
                {
                    Caption = 'discountPercent';
                }
                field(taxPercent; Rec."VAT %")
                {
                    Caption = 'taxPercent';
                }
                field(shipmentDate; Rec."Shipment Date")
                {
                    Caption = 'shipmentDate';
                }
            }
        }
    }

}