tableextension 80403 "Purch. Rcpt. Header" extends "Purch. Rcpt. Header"//120
{
    fields
    {
        // Add changes to table fields here
        field(80150; "Controle"; Boolean)
        {
            Caption = 'Contrôlé';
            Editable = false;
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