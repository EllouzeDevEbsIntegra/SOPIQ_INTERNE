table 90000 "Purchase Order Log"
{
    DataClassification = ToBeClassified;

    fields
    {
        field(50023; "Entry No."; BigInteger)
        {
            DataClassification = ToBeClassified;
            AutoIncrement = true;
        }
        field(50024; Filter; TEXT[200])
        {
            DataClassification = ToBeClassified;
        }

        field(50025; "Vendor No."; Code[20])
        {
            DataClassification = ToBeClassified;
        }

        field(50026; "Demande Achat No."; code[20])
        {
            DataClassification = ToBeClassified;
        }

        field(50027; "Demande Achat Date"; Date)
        {
            DataClassification = ToBeClassified;
        }
    }

    keys
    {
        key("Entry No."; "Entry No.")
        {
            Clustered = true;
        }
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

}