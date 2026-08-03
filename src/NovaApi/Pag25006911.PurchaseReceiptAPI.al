// Cycle d'achat NOVA — Réception d'achat enregistrée (Purch. Rcpt. Header). Lecture seule.
page 25006911 "Purchase Receipt API"
{
    PageType = API;
    SourceTable = "Purch. Rcpt. Header";
    APIPublisher = 'sopiq';
    APIGroup = 'interne';
    APIVersion = 'v1.0';
    EntityName = 'purchaseReceipt';
    EntitySetName = 'purchaseReceiptAPI';
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
                field(vendorShipmentNumber; Rec."Vendor Shipment No.") { Caption = 'vendorShipmentNumber'; }
                field(orderNumber; Rec."Order No.") { Caption = 'orderNumber'; }
                field(postingDate; Rec."Posting Date") { Caption = 'postingDate'; }
                field(documentDate; Rec."Document Date") { Caption = 'documentDate'; }
                field(currencyCode; Rec."Currency Code") { Caption = 'currencyCode'; }
                field(purchaser; Rec."Purchaser Code") { Caption = 'purchaser'; }
                part(purchaseReceiptLines; "Purchase Receipt Line API")
                {
                    Caption = 'purchaseReceiptLines';
                    SubPageLink = "Document No." = field("No.");
                    EntityName = 'purchaseReceiptLine';
                    EntitySetName = 'purchaseReceiptLines';
                }
            }
        }
    }
}
