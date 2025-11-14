page 25006856 "SalesShipment API"
{
    PageType = API;
    SourceTable = "Sales Shipment Header";
    APIPublisher = 'sopiq';
    APIGroup = 'interne';
    APIVersion = 'v1.0';
    EntityName = 'salesShipmentAPI';
    EntitySetName = 'salesShipmentAPI';
    ODataKeyFields = SystemId;
    DelayedInsert = true;

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field(id; SystemId)
                {
                    Caption = 'id';
                }
                field(number; "No.")
                {
                    Caption = 'number';
                }
                field(externalDocumentNumber; "External Document No.")
                {
                    Caption = 'externalDocumentNumber';
                }
                field(shipmentDate; "Shipment Date")
                {
                    Caption = 'shipmentDate';
                }
                field(postingDate; "Posting Date")
                {
                    Caption = 'postingDate';
                }

                field(customerNumber; "Sell-to Customer No.")
                {
                    Caption = 'customerNumber';
                }
                field(customerName; "Sell-to Customer Name")
                {
                    Caption = 'customerName';
                }
                field(sellToAddressLine1; "Sell-to Address")
                {
                    Caption = 'sellToAddressLine1';
                }
                field(sellToAddressLine2; "Sell-to Address 2")
                {
                    Caption = 'sellToAddressLine2';
                }
                field(sellToCity; "Sell-to City")
                {
                    Caption = 'sellToCity';
                }
                field(sellToCountry; "Sell-to County")
                {
                    Caption = 'sellToCountry';
                }
                field(phoneNumber; "Sell-to Phone No.")
                {
                    Caption = 'phoneNumber';
                }
                field(email; "Sell-to E-Mail")
                {
                    Caption = 'email';
                }

                field(billToName; "Bill-to Name")
                {
                    Caption = 'billToName';
                }
                field(billToCustomerNumber; "Bill-to Customer No.")
                {
                    Caption = 'billToCustomerNumber';
                }
                field(billToAddressLine1; "Bill-to Address")
                {
                    Caption = 'billToAddressLine1';
                }
                field(billToAddressLine2; "Bill-to Address 2")
                {
                    Caption = 'billToAddressLine2';
                }
                field(billToCity; "Bill-to City")
                {
                    Caption = 'billToCity';
                }
                field(billToCountry; "Bill-to County")
                {
                    Caption = 'billToCountry';
                }

                field(shipToName; "Ship-to Name")
                {
                    Caption = 'shipToName';
                }
                field(shipToContact; "Ship-to Contact")
                {
                    Caption = 'shipToContact';
                }
                field(shipToAddressLine1; "Ship-to Address")
                {
                    Caption = 'shipToAddressLine1';
                }
                field(shipToAddressLine2; "Ship-to Address 2")
                {
                    Caption = 'shipToAddressLine2';
                }
                field(shipToCity; "Ship-to City")
                {
                    Caption = 'shipToCity';
                }
                field(shipToCountry; "Ship-to Country/Region Code")
                {
                    Caption = 'shipToCountry';
                }
                field(shipToState; "Ship-to County")
                {
                    Caption = 'shipToState';
                }
                field(shipToPostCode; "Ship-to Post Code")
                {
                    Caption = 'shipToPostCode';
                }

                field(currencyCode; "Currency Code")
                {
                    Caption = 'currencyCode';
                }
                field(orderNumber; "Order No.")
                {
                    Caption = 'orderNumber';
                }
                field(paymentTermsCode; "Payment Terms Code")
                {
                    Caption = 'paymentTermsCode';
                }
                field(shipmentMethodCode; "Shipment Method Code")
                {
                    Caption = 'shipmentMethodCode';
                }
                field(salesperson; "Salesperson Code")
                {
                    Caption = 'salesperson';
                }
                field(pricesIncludeTax; "Prices Including VAT")
                {
                    Caption = 'pricesIncludeTax';
                }

                field(lineAmountTTC; "Line Amount")
                {
                    Caption = 'lineAmountTTC';
                }
                field(lineAmountHT; "Line Amount HT")
                {
                    Caption = 'lineAmountHT';
                }
                part(salesShipmentLines; "Sales Shipment Line API")
                {
                    Caption = 'salesShipmentLines';
                    SubPageLink = "Document No." = field("No.");
                    EntityName = 'salesShipmentLine';
                    EntitySetName = 'salesShipmentLines';
                }
            }
        }
    }

}
