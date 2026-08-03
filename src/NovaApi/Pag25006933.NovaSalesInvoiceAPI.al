// NOVA — Facture de vente ENREGISTRÉE (Sales Invoice Header). Copie indépendante (NovaApi).
page 25006933 "Nova Sales Invoice API"
{
    PageType = API;
    SourceTable = "Sales Invoice Header";
    APIPublisher = 'sopiq';
    APIGroup = 'interne';
    APIVersion = 'v1.0';
    EntityName = 'novaSalesInvoice';
    EntitySetName = 'novaSalesInvoices';
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
                field(customerNumber; Rec."Sell-to Customer No.") { Caption = 'customerNumber'; }
                field(customerName; Rec."Sell-to Customer Name") { Caption = 'customerName'; }
                field(billToCustomerNumber; Rec."Bill-to Customer No.") { Caption = 'billToCustomerNumber'; }
                field(externalDocumentNumber; Rec."External Document No.") { Caption = 'externalDocumentNumber'; }
                field(postingDate; Rec."Posting Date") { Caption = 'postingDate'; }
                field(documentDate; Rec."Document Date") { Caption = 'documentDate'; }
                field(dueDate; Rec."Due Date") { Caption = 'dueDate'; }
                field(salesperson; Rec."Salesperson Code") { Caption = 'salesperson'; }
                field(currencyCode; Rec."Currency Code") { Caption = 'currencyCode'; }
                field(totalAmountExcludingTax; Rec.Amount) { Caption = 'totalAmountExcludingTax'; }
                field(totalAmountIncludingTax; Rec."Amount Including VAT") { Caption = 'totalAmountIncludingTax'; }
                part(novaSalesInvoiceLines; "Nova Sales Invoice Line API")
                {
                    Caption = 'novaSalesInvoiceLines';
                    SubPageLink = "Document No." = field("No.");
                    EntityName = 'novaSalesInvoiceLine';
                    EntitySetName = 'novaSalesInvoiceLines';
                }
            }
        }
    }
}
