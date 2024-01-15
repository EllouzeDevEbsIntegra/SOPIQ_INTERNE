table 70012 "Recu Caisse Document"
{
    DataClassification = ToBeClassified;

    fields
    {
        field(70012; "No Recu"; code[10])
        {
            DataClassification = ToBeClassified;
            TableRelation = "Recu Caisse";
        }
        field(70013; "Line No"; Integer)
        {
            DataClassification = ToBeClassified;
        }
        field(70014; type; Enum "Document Caisse Type")
        {
            DataClassification = ToBeClassified;
            trigger OnValidate()

            begin
                if xRec.type = type::null then "Line No" := incrementNo("No Recu");
            end;
        }

        field(70015; "Customer No"; code[20])
        {
            DataClassification = ToBeClassified;
            TableRelation = Customer;
        }

        field(70016; "Document No"; Code[20])
        {
            DataClassification = ToBeClassified;

        }

        field(70017; "Libelle"; Text[100])
        {
            DataClassification = ToBeClassified;
        }

        field(70019; "Total TTC"; Decimal)
        {
            DataClassification = ToBeClassified;
        }

        field(70020; "Montant Reglement"; Decimal)
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
        myInt: Integer;

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
        recRecuCaisseDoc: Record "Recu Caisse Document";
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