// Cycle d'achat NOVA — Commande d'achat (Purchase Header / Document Type = Order).
// Exposée sur api/sopiq/interne/v1.0 comme les documents de vente (parité NOVA).
page 25006889 "Purchase Order API"
{
    PageType = API;
    SourceTable = "Purchase Header";
    APIPublisher = 'sopiq';
    APIGroup = 'interne';
    APIVersion = 'v1.0';
    EntityName = 'purchaseOrder';
    EntitySetName = 'purchaseOrderAPI';
    ODataKeyFields = SystemId;
    DelayedInsert = true;
    SourceTableView = WHERE("Document Type" = CONST(Order));

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
                field(vendorInvoiceNumber; Rec."Vendor Invoice No.") { Caption = 'vendorInvoiceNumber'; }
                field(vendorOrderNumber; Rec."Vendor Order No.") { Caption = 'vendorOrderNumber'; }
                field(orderDate; Rec."Order Date") { Caption = 'orderDate'; }
                field(documentDate; Rec."Document Date") { Caption = 'documentDate'; }
                field(postingDate; Rec."Posting Date") { Caption = 'postingDate'; }
                field(dueDate; Rec."Due Date") { Caption = 'dueDate'; }
                field(currencyCode; Rec."Currency Code") { Caption = 'currencyCode'; }
                field(status; Rec.Status) { Caption = 'status'; }
                field(purchaser; Rec."Purchaser Code") { Caption = 'purchaser'; }
                field(totalAmountExcludingTax; Rec.Amount) { Caption = 'totalAmountExcludingTax'; }
                field(totalAmountIncludingTax; Rec."Amount Including VAT") { Caption = 'totalAmountIncludingTax'; }
                part(purchaseOrderLines; "Purchase Order Line API")
                {
                    Caption = 'purchaseOrderLines';
                    SubPageLink = "Document Type" = field("Document Type"), "Document No." = field("No.");
                    EntityName = 'purchaseOrderLine';
                    EntitySetName = 'purchaseOrderLines';
                }
            }
        }
    }
}
