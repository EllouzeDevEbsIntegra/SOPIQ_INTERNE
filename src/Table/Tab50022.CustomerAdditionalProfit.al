table 50022 "Customer Additional Profit"
{
    DataClassification = ToBeClassified;

    fields
    {
        field(50022; "Customers"; code[20])
        {
            DataClassification = ToBeClassified;
            TableRelation = Customer."No.";
        }

        field(50023; "Item Manufacturer"; code[10])
        {
            DataClassification = ToBeClassified;
            TableRelation = Manufacturer.Code;
        }

        field(50024; "Item Group"; code[20])
        {
            DataClassification = ToBeClassified;
            TableRelation = "Item Category".Code where(Indentation = filter(0 | 1));
        }

        field(50025; "Type"; Option)
        {
            OptionMembers = "Marge Additionnelle","Remise Exceptionnelle";
        }

        field(50026; "Taux"; Decimal)
        {
            DataClassification = ToBeClassified;
        }
    }

    keys
    {
        key(Key1; "Customers", "Item Manufacturer", "Item Group", "Type")
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