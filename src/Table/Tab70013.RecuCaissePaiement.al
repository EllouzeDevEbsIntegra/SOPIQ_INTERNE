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
        }

        field(70018; "Echeance"; date)
        {
            DataClassification = ToBeClassified;
        }

        field(70019; banque; Enum "Banque Caisse")
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

    var


    trigger OnInsert()
    begin
    end;

    trigger OnModify()
    begin

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