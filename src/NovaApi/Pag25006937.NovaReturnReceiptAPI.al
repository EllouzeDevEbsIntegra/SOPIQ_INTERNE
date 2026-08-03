// NOVA — Retour reçu de vente ENREGISTRÉ (Return Receipt Header). Copie indépendante (NovaApi).
page 25006937 "Nova Return Receipt API"
{
    PageType = API;
    SourceTable = "Return Receipt Header";
    APIPublisher = 'sopiq';
    APIGroup = 'interne';
    APIVersion = 'v1.0';
    EntityName = 'novaReturnReceipt';
    EntitySetName = 'novaReturnReceipts';
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
                field(postingDate; Rec."Posting Date") { Caption = 'postingDate'; }
                field(documentDate; Rec."Document Date") { Caption = 'documentDate'; }
                field(salesperson; Rec."Salesperson Code") { Caption = 'salesperson'; }
                field(currencyCode; Rec."Currency Code") { Caption = 'currencyCode'; }
                part(novaReturnReceiptLines; "Nova Return Receipt Line API")
                {
                    Caption = 'novaReturnReceiptLines';
                    SubPageLink = "Document No." = field("No.");
                    EntityName = 'novaReturnReceiptLine';
                    EntitySetName = 'novaReturnReceiptLines';
                }
            }
        }
    }
}
