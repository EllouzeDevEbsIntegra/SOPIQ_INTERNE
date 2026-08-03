// Cycle d'achat NOVA — Expédition retour d'achat enregistrée (Return Shipment Header). Lecture seule.
page 25006914 "Purchase Return Shipment API"
{
    PageType = API;
    SourceTable = "Return Shipment Header";
    APIPublisher = 'sopiq';
    APIGroup = 'interne';
    APIVersion = 'v1.0';
    EntityName = 'purchaseReturnShipment';
    EntitySetName = 'purchaseReturnShipmentAPI';
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
                field(number; Rec."No.") { Caption = 'number'; }
                field(vendorNumber; Rec."Buy-from Vendor No.") { Caption = 'vendorNumber'; }
                field(vendorName; Rec."Buy-from Vendor Name") { Caption = 'vendorName'; }
                field(payToVendorNumber; Rec."Pay-to Vendor No.") { Caption = 'payToVendorNumber'; }
                field(postingDate; Rec."Posting Date") { Caption = 'postingDate'; }
                field(documentDate; Rec."Document Date") { Caption = 'documentDate'; }
                field(currencyCode; Rec."Currency Code") { Caption = 'currencyCode'; }
                field(purchaser; Rec."Purchaser Code") { Caption = 'purchaser'; }
                part(purchaseReturnShipmentLines; "Purch. Ret. Ship. Line API")
                {
                    Caption = 'purchaseReturnShipmentLines';
                    SubPageLink = "Document No." = field("No.");
                    EntityName = 'purchaseReturnShipmentLine';
                    EntitySetName = 'purchaseReturnShipmentLines';
                }
            }
        }
    }
}
