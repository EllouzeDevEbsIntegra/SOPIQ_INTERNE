tableextension 80509 "Purch. Cr. Memo Hdr." extends "Purch. Cr. Memo Hdr." //124
{
    fields
    {
        field(80105; solde; Boolean)
        {
            Caption = 'Soldé';
        }
        field(80411; "Montant reçu caisse"; Decimal)
        {
            Caption = 'Montant reçu caisse';

            FieldClass = FlowField;
            CalcFormula = sum("Recu Caisse Document"."Montant Reglement" WHERE("Document No" = field("No.")));
            Editable = false;
        }

    }

    var
        myInt: Integer;
}