// Cycle d'achat NOVA — Avoir d'achat ENREGISTRÉ / posté (Purch. Cr. Memo Hdr.). Lecture seule.
// Complément du brouillon (page 25006916, Purchase Header / Credit Memo).
page 25006918 "Posted Purch. Cr. Memo API"
{
    PageType = API;
    SourceTable = "Purch. Cr. Memo Hdr.";
    APIPublisher = 'sopiq';
    APIGroup = 'interne';
    APIVersion = 'v1.0';
    EntityName = 'postedPurchaseCreditMemo';
    EntitySetName = 'postedPurchaseCreditMemoAPI';
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
                field(vendorCrMemoNumber; Rec."Vendor Cr. Memo No.") { Caption = 'vendorCrMemoNumber'; }
                field(documentDate; Rec."Document Date") { Caption = 'documentDate'; }
                field(postingDate; Rec."Posting Date") { Caption = 'postingDate'; }
                field(dueDate; Rec."Due Date") { Caption = 'dueDate'; }
                field(currencyCode; Rec."Currency Code") { Caption = 'currencyCode'; }
                field(purchaser; Rec."Purchaser Code") { Caption = 'purchaser'; }
                field(totalAmountExcludingTax; Rec.Amount) { Caption = 'totalAmountExcludingTax'; }
                field(totalAmountIncludingTax; Rec."Amount Including VAT") { Caption = 'totalAmountIncludingTax'; }
                part(postedPurchaseCreditMemoLines; "Posted Purch. Cr. Memo Line")
                {
                    Caption = 'postedPurchaseCreditMemoLines';
                    SubPageLink = "No." = field("No.");
                    EntityName = 'postedPurchaseCreditMemoLine';
                    EntitySetName = 'postedPurchaseCreditMemoLines';
                }
            }
        }
    }
}
