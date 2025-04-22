tableextension 80502 "Sales Order Entity Buffer" extends "Sales Order Entity Buffer" //5495 

{
    fields
    {
        // Add changes to table fields here
        field(50100; "Shipping Agent Code SI"; Code[10])
        {
            AccessByPermission = TableData "Shipping Agent Services" = R;
            Caption = 'Shipping Agent Code';
            TableRelation = "Shipping Agent".Code;
        }
        field(50101; "Location Code SI"; Code[10])
        {
            AccessByPermission = TableData Location = R;
            Caption = 'Location Code';
            TableRelation = Location.Code;
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
        field(80101; custNameImprime; Text[200])
        {
            Caption = 'Nom Client Imprimé';
        }

        field(80102; custAdresseImprime; Text[200])
        {
            Caption = 'Adresse Client Imprimé';
        }

        field(80103; custMFImprime; Text[200])
        {
            Caption = 'Matricule Fiscal Imprimé';
        }

        field(80104; custVINImprime; Text[200])
        {
            Caption = 'Vin Client Imprimé';
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