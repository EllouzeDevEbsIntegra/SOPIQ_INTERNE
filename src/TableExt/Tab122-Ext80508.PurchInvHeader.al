
tableextension 80508 "Purch. Inv. Header" extends "Purch. Inv. Header" //122
{
    fields
    {
        // Add changes to table fields here
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