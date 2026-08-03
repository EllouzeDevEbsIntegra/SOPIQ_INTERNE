// NOVA — Expédition de vente ENREGISTRÉE (Sales Shipment Header). Copie indépendante (NovaApi).
page 25006935 "Nova Sales Shipment API"
{
    PageType = API;
    SourceTable = "Sales Shipment Header";
    APIPublisher = 'sopiq';
    APIGroup = 'interne';
    APIVersion = 'v1.0';
    EntityName = 'novaSalesShipment';
    EntitySetName = 'novaSalesShipments';
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
                field(externalDocumentNumber; Rec."External Document No.") { Caption = 'externalDocumentNumber'; }
                field(shipmentDate; Rec."Shipment Date") { Caption = 'shipmentDate'; }
                field(postingDate; Rec."Posting Date") { Caption = 'postingDate'; }
                field(orderNumber; Rec."Order No.") { Caption = 'orderNumber'; }
                field(salesperson; Rec."Salesperson Code") { Caption = 'salesperson'; }
                field(currencyCode; Rec."Currency Code") { Caption = 'currencyCode'; }
                part(novaSalesShipmentLines; "Nova Sales Shipment Line API")
                {
                    Caption = 'novaSalesShipmentLines';
                    SubPageLink = "Document No." = field("No.");
                    EntityName = 'novaSalesShipmentLine';
                    EntitySetName = 'novaSalesShipmentLines';
                }
            }
        }
    }
}
