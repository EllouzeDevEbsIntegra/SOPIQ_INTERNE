page 25006855 "Sales Invoice Feedback API"
{
    PageType = API;
    SourceTable = "Sales Invoice Feedback";
    APIPublisher = 'sopiq';
    APIGroup = 'interne';
    APIVersion = 'v1.0';
    EntityName = 'salesInvoiceFeedbackAPI';
    EntitySetName = 'salesInvoiceFeedbackAPI';
    ODataKeyFields = "No.";
    DelayedInsert = true;
    ModifyAllowed = true;
    InsertAllowed = false;
    DeleteAllowed = true;

    layout
    {
        area(content)
        {
            field(No; "No.") { }
            field(postingDate; "Posting Date") { }
            field(amount; Amount) { }
            field(amountIncludingVAT; "Amount Including VAT") { }
            field(workDescription; "Work Description") { }
            field(documentProfile; "Document Profile") { }
            field(sellToCustomerNo; "Sell-to Customer No.") { }
            field(sellToCustomerName; "Sell-to Customer Name") { }
            field(billToCustomerNo; "Bill-to Customer No.") { }
            field(billToName; "Bill-to Name") { }
            field(orderNo; "Order No.") { }
            field(salespersonCode; "Salesperson Code") { }
            field(serviceOrderNo; "Service Order No.") { }
            field(orderCreator; "Order Creator") { }
            field(orderDate; "Order Date") { }
            field(dealTypeCode; "Deal Type Code") { }
            field(serviceDocument; "Service Document") { }
            field(documentDate; "Document Date") { }
            field(externalDocumentNo; "External Document No.") { }
            field(userId; "User ID") { }
            field(sellToPhoneNo; "Sell-to Phone No.") { }
            field(phoneNo; "Phone No.") { }
            field(mobilePhoneNo; "Mobile Phone No.") { }
            field(vehicleRegistrationNo; "Vehicle Registration No.") { }
            field(makeCode; "Make Code") { }
            field(modelCode; "Model Code") { }
            field(vehicleSerialNo; "Vehicle Serial No.") { }
            field(vin; VIN) { }
            field(feedback; feedback) { }
            field("FeedbackDate"; "Feedback Date") { }


        }
    }
    trigger OnAfterGetRecord()
    var
        Vehicle: Record Vehicle;
    begin

        Vehicle.reset();
        Vehicle.SetRange("Serial No.", "Vehicle Serial No.");
        if Vehicle.FindFirst() then
            VIN := Vehicle."VIN";


    end;

}