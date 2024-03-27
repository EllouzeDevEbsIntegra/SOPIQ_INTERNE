table 70013 "Recu Caisse Paiement"
{
    DataClassification = ToBeClassified;

    fields
    {
        field(70011; "Date Reçu"; Date)
        {
            CalcFormula = lookup("Recu Caisse".dateRecu where(No = field("No Recu")));
            Caption = 'Date Reçu';
            Editable = false;
            FieldClass = FlowField;
        }
        field(70012; "No Recu"; code[10])
        {
            DataClassification = ToBeClassified;
            TableRelation = "Recu Caisse";
        }
        field(70013; "Line No"; Integer)
        {
            DataClassification = ToBeClassified;
        }
        field(70014; type; Enum "Paiment Caisse Type")
        {
            DataClassification = ToBeClassified;
            trigger OnValidate()

            begin
                if xRec.type = type::null then "Line No" := incrementNo("No Recu");
            end;
        }

        field(70015; "Name"; code[100])
        {
            DataClassification = ToBeClassified;
        }

        field(70016; "Paiment No"; Code[20])
        {
            DataClassification = ToBeClassified;
        }

        field(70017; "Montant"; Decimal)
        {
            DataClassification = ToBeClassified;
            trigger OnValidate()
            begin

                if xRec.type = type::null then "Line No" := incrementNo("No Recu");

            end;
        }

        field(70018; "Echeance"; date)
        {
            DataClassification = ToBeClassified;
        }

        field(70019; banque; Enum "Banque Caisse")
        {
            DataClassification = ToBeClassified;
        }

        field(70020; isDecaissement; Boolean)
        {
            DataClassification = ToBeClassified;
        }

        field(70021; "Montant Calcul"; Decimal)
        {
            DataClassification = ToBeClassified;
        }

        field(70022; "Text For Print"; Text[1000])
        {
            DataClassification = ToBeClassified;
        }

    }

    keys
    {
        key(Key1; "No Recu", "Line No")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        // Add changes to field groups here
    }


    trigger OnInsert()
    begin
    end;

    trigger OnModify()
    begin
        //"Text For Print" := Format(type) + ' ' + Format("Paiment No") + ' ' + Format(Name) + ' ' + Format(Echeance) + ' ' + Format(Montant, 12, 3);
        if isDecaissement = true then
            "Montant Calcul" := -Montant
        else
            "Montant Calcul" := Montant;
    end;

    trigger OnDelete()
    var
        recUserSetup: Record "User Setup";
        recuCaisse: Record "Recu Caisse";
    begin
        recUserSetup.Reset();
        recUserSetup.Get(UserId);
        recuCaisse.Reset();
        recuCaisse.get(rec."No Recu");
        if (recUserSetup.isRCModify = false) AND (recuCaisse.Printed = true) then begin
            Error('Vous ne pouvez pas supprmier la ligne !');
        end

    end;

    trigger OnRename()
    begin

    end;

    procedure incrementNo("No Recu": code[20]): Integer
    var
        recRecuCaisseDoc: Record "Recu Caisse Paiement";
    begin

        recRecuCaisseDoc.SetRange("No Recu", "No Recu");
        if recRecuCaisseDoc.FindLast() then begin
            exit(recRecuCaisseDoc."Line No" + 10000);
        end
        else begin
            exit(10000);
        end;

    end;

    procedure setIsDeciassement(typePaiement: Enum "Paiment Caisse Type"): Boolean
    begin
        if (typePaiement = typePaiement::"AvoirEsp") OR (typePaiement = typePaiement::"Depense") OR (typePaiement = typePaiement::"retourBS") OR (typePaiement = typePaiement::"Transport") OR (typePaiement = typePaiement::"ResteCheque") then
            exit(true)
        else
            exit(false);
    end;


}