tableextension 80411 "Entete archive BS" extends "Entete archive BS" //50009
{
    fields
    {

        // Add changes to table fields here
        field(80411; "Montant reçu caisse"; Decimal)
        {
            Caption = 'Montant reçu caisse';

            FieldClass = FlowField;
            CalcFormula = sum("Recu Caisse Document"."Montant Reglement" WHERE("Document No" = field("No.")));
            Editable = false;
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