tableextension 80403 "Purch. Rcpt. Header" extends "Purch. Rcpt. Header"//120
{
    fields
    {
        // Add changes to table fields here
        field(80113; "Montant Ouvert"; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = Sum("Purch. Rcpt. Line"."Line Amount" WHERE("Document No." = FIELD("No."), "Qty. Rcd. Not Invoiced" = Filter('>0')));
            Caption = 'Montant  Ouvert';
            Editable = false;
        }
        field(80114; "Total HT"; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = Sum("Purch. Rcpt. Line"."Line Amount HT" WHERE("Document No." = FIELD("No.")));
            Caption = 'Total HT';
            Editable = false;
        }
        field(80115; "Total TTC"; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = Sum("Purch. Rcpt. Line"."Line Amount" WHERE("Document No." = FIELD("No.")));
            Caption = 'Total TTC';
            Editable = false;
        }
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