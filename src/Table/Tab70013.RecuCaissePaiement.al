table 70013 "Recu Caisse Paiement"
{
    DataClassification = ToBeClassified;

    fields
    {
        field(70012; "No Recu"; code[10])
        {
            DataClassification = ToBeClassified;
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
                "Line No" := incrementNo("No Recu");
            end;
        }

        field(70015; "Name"; code[20])
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
                if (type = type::null) then
                    Error('Vous devez spécifier le type de règlement !') else begin
                    if (isDecaissement = true) then "Montant Calcul" := -Montant else "Montant Calcul" := Montant;
                end;
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
        if (type = type::AvoirEsp) OR (type = type::Depense) OR (type = type::retourBS) OR (type = type::Transport) OR (type = type::ResteCheque) then begin
            isDecaissement := true;
            "Montant Calcul" := -Montant;

        end
        else begin
            isDecaissement := false;
            "Montant Calcul" := Montant;
        end;

    end;

    trigger OnDelete()
    begin

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





}