table 70011 "Recu Caisse"
{
    DataClassification = ToBeClassified;

    fields
    {
        field(70011; No; code[10])
        {
            DataClassification = ToBeClassified;
        }
        field(70010; "Customer No"; Code[20])
        {
            DataClassification = ToBeClassified;
            TableRelation = Customer;
        }

        field(70009; custName; text[100])
        {
            DataClassification = ToBeClassified;
            Editable = false;
        }
        field(70012; dateTime; DateTime)
        {
            DataClassification = ToBeClassified;
        }
        field(70013; user; code[20])
        {
            DataClassification = ToBeClassified;
            TableRelation = "Salesperson/Purchaser";
        }
        field(70014; totalReçu; Decimal)
        {
            DataClassification = ToBeClassified;
        }

        field(70015; totalDocToPay; Decimal)
        {
            DataClassification = ToBeClassified;
        }
        field(70016; isAcompte; Boolean)
        {
            DataClassification = ToBeClassified;
        }

    }

    keys
    {
        key(Key1; No)
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
    var

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

}