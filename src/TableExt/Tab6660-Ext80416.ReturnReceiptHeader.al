tableextension 80416 "Return Receipt Header" extends "Return Receipt Header" //6660
{
    fields
    {
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