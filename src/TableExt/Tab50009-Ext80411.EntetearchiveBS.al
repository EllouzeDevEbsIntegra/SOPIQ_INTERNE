tableextension 80411 "Entete archive BS" extends "Entete archive BS" //50009
{
    fields
    {
        field(80410; "Montant Brut HT"; Decimal)
        {
            // DataClassification = ToBeClassified;
            Caption = 'Montant TTC';
            FieldClass = FlowField;
            CalcFormula = SUM("Ligne archive BS"."Line Amount" where("Document No." = field("No.")));
            Editable = false;
        }
        // Add changes to table fields here
        field(80411; "Montant reçu caisse"; Decimal)
        {
            Caption = 'Montant reçu caisse';

            FieldClass = FlowField;
            CalcFormula = sum("Recu Caisse Document"."Montant Reglement" WHERE("Document No" = field("No.")));
            Editable = false;
        }


        // field(80412; "No reçu caisse"; code[20])
        // {
        //     Caption = 'No reçu caisse';

        //     FieldClass = FlowField;
        //     CalcFormula = lookup("Recu Caisse Document"."No Recu" WHERE("Document No" = field("No.")));
        //     Editable = false;
        // }

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