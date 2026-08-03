// Cycle d'achat NOVA — Facture d'achat BROUILLON (Purchase Header / Document Type = Invoice).
page 25006928 "Purchase Invoice Draft API"
{
    PageType = API;
    SourceTable = "Purchase Header";
    APIPublisher = 'sopiq';
    APIGroup = 'interne';
    APIVersion = 'v1.0';
    EntityName = 'purchaseInvoiceDraft';
    EntitySetName = 'purchaseInvoiceDraftAPI';
    ODataKeyFields = SystemId;
    DelayedInsert = true;
    SourceTableView = WHERE("Document Type" = CONST(Invoice));

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
                field(documentDate; Rec."Document Date") { Caption = 'documentDate'; }
                field(postingDate; Rec."Posting Date") { Caption = 'postingDate'; }
                field(dueDate; Rec."Due Date") { Caption = 'dueDate'; }
                field(currencyCode; Rec."Currency Code") { Caption = 'currencyCode'; }
                field(status; Rec.Status) { Caption = 'status'; }
                field(purchaser; Rec."Purchaser Code") { Caption = 'purchaser'; }
                field(totalAmountExcludingTax; Rec.Amount) { Caption = 'totalAmountExcludingTax'; }
                field(totalAmountIncludingTax; Rec."Amount Including VAT") { Caption = 'totalAmountIncludingTax'; }
                part(purchaseInvoiceDraftLines; "Purchase Inv. Draft Line API")
                {
                    Caption = 'purchaseInvoiceDraftLines';
                    SubPageLink = "Document Type" = field("Document Type"), "Document No." = field("No.");
                    EntityName = 'purchaseInvoiceDraftLine';
                    EntitySetName = 'purchaseInvoiceDraftLines';
                }
            }
        }
    }
}
