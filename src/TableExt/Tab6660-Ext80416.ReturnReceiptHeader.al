tableextension 80416 "Return Receipt Header" extends "Return Receipt Header" //6660
{
    fields
    {
        field(80113; "Montant Ouvert"; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = Sum("Return Receipt Line"."Amount Including VAT" WHERE("Document No." = FIELD("No."), "Return Qty. Rcd. Not Invd." = Filter('>0')));
            Caption = 'Montant  Ouvert';
            Editable = false;
        }
        // Add changes to table fields here
        field(80416; BS; Boolean)
        {
            DataClassification = ToBeClassified;
        }
        field(80417; "Montant reçu caisse"; Decimal)
        {
            Caption = 'Montant reçu caisse';

            FieldClass = FlowField;
            CalcFormula = sum("Recu Caisse Document"."Montant Reglement" WHERE("Document No" = field("No.")));
            Editable = false;
        }

        field(80418; solde; Boolean)
        {
            DataClassification = ToBeClassified;
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


    trigger OnInsert()
    var
        salesHeader: Record "Sales Header";
    begin
        salesHeader.Reset();
        salesHeader.SetRange("No.", rec."Return Order No.");
        if salesHeader.FindFirst() then begin
            rec.BS := salesHeader.BS;
        end;
    end;
}