tableextension 80502 "Sales Order Entity Buffer" extends "Sales Order Entity Buffer" //5495 

{
    fields
    {
        // Add changes to table fields here
        field(50100; shippingAgentCode; Code[10])
        {
            AccessByPermission = TableData "Shipping Agent Services" = R;
            Caption = 'Shipping Agent Code';
            TableRelation = "Shipping Agent".Code;
        }
    }

    keys
    {
        // Add changes to keys here
    }

    fieldgroups
    {
        // Add changes to field groups here
    }

    var
        myInt: Integer;
}