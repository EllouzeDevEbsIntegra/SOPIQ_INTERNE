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
        field(50102; Base64; BLOB)
        {
            Caption = 'Base64';
        }
        field(50103; Message; Text[250])
        {
            Caption = 'Message';
        }
        field(50104; Binary; BLOB)
        {
            Caption = 'Binary';
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