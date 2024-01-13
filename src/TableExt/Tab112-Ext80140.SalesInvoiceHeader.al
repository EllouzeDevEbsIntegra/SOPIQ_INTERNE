tableextension 80140 "Sales Invoice Header" extends "Sales Invoice Header"//112
{
    fields
    {
        // Add changes to table fields here
        field(80140; "Moy Jour Paiement"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'Moyen Jour Paiement';
            DecimalPlaces = 0 : 2;
        }

        field(80141; "DiscountAmount"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = sum("Sales Invoice Line"."Line Discount Amount" WHERE("Document No." = field("No.")));
            Caption = 'Type MO';
            Editable = false;
            FieldClass = FlowField;
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

        field(80413; solde; Boolean)
        {
            DataClassification = ToBeClassified;
        }
    }

    var
        myInt: Integer;
}