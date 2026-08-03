// Cycle de vente NOVA — Avoir de vente BROUILLON (Sales Header / Document Type = Credit Memo).
page 25006924 "Sales Cr.Memo Draft API"
{
    PageType = API;
    SourceTable = "Sales Header";
    APIPublisher = 'sopiq';
    APIGroup = 'interne';
    APIVersion = 'v1.0';
    EntityName = 'salesCreditMemoDraft';
    EntitySetName = 'salesCreditMemoDraftAPI';
    ODataKeyFields = SystemId;
    DelayedInsert = true;
    SourceTableView = WHERE("Document Type" = CONST("Credit Memo"));

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field(id; Rec.SystemId) { Caption = 'id'; }
                field(number; Rec."No.") { Caption = 'number'; }
                field(customerNumber; Rec."Sell-to Customer No.") { Caption = 'customerNumber'; }
                field(customerName; Rec."Sell-to Customer Name") { Caption = 'customerName'; }
                field(billToCustomerNumber; Rec."Bill-to Customer No.") { Caption = 'billToCustomerNumber'; }
                field(externalDocumentNumber; Rec."External Document No.") { Caption = 'externalDocumentNumber'; }
                field(documentDate; Rec."Document Date") { Caption = 'documentDate'; }
                field(postingDate; Rec."Posting Date") { Caption = 'postingDate'; }
                field(dueDate; Rec."Due Date") { Caption = 'dueDate'; }
                field(salesperson; Rec."Salesperson Code") { Caption = 'salesperson'; }
                field(currencyCode; Rec."Currency Code") { Caption = 'currencyCode'; }
                field(status; Rec.Status) { Caption = 'status'; }
                field(totalAmountExcludingTax; Rec.Amount) { Caption = 'totalAmountExcludingTax'; }
                field(totalAmountIncludingTax; Rec."Amount Including VAT") { Caption = 'totalAmountIncludingTax'; }
                part(salesCreditMemoDraftLines; "Sales Cr.Memo Draft Line API")
                {
                    Caption = 'salesCreditMemoDraftLines';
                    SubPageLink = "Document Type" = field("Document Type"), "Document No." = field("No.");
                    EntityName = 'salesCreditMemoDraftLine';
                    EntitySetName = 'salesCreditMemoDraftLines';
                }
            }
        }
    }
}
