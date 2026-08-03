// Cycle d'achat NOVA — Facture d'achat ENREGISTRÉE / postée (Purch. Inv. Header). Lecture seule.
page 25006930 "Posted Purchase Invoice API"
{
    PageType = API;
    SourceTable = "Purch. Inv. Header";
    APIPublisher = 'sopiq';
    APIGroup = 'interne';
    APIVersion = 'v1.0';
    EntityName = 'postedPurchaseInvoice';
    EntitySetName = 'postedPurchaseInvoiceAPI';
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
                field(vendorInvoiceNumber; Rec."Vendor Invoice No.") { Caption = 'vendorInvoiceNumber'; }
                field(postingDate; Rec."Posting Date") { Caption = 'postingDate'; }
                field(documentDate; Rec."Document Date") { Caption = 'documentDate'; }
                field(dueDate; Rec."Due Date") { Caption = 'dueDate'; }
                field(currencyCode; Rec."Currency Code") { Caption = 'currencyCode'; }
                field(purchaser; Rec."Purchaser Code") { Caption = 'purchaser'; }
                field(totalAmountExcludingTax; Rec.Amount) { Caption = 'totalAmountExcludingTax'; }
                field(totalAmountIncludingTax; Rec."Amount Including VAT") { Caption = 'totalAmountIncludingTax'; }
                part(postedPurchaseInvoiceLines; "Posted Purch. Inv. Line API")
                {
                    Caption = 'postedPurchaseInvoiceLines';
                    SubPageLink = "Document No." = field("No.");
                    EntityName = 'postedPurchaseInvoiceLine';
                    EntitySetName = 'postedPurchaseInvoiceLines';
                }
            }
        }
    }
}
