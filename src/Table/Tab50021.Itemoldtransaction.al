table 50021 "Item old transaction"
{
    DataClassification = ToBeClassified;

    fields
    {
        field(1; "Document N°"; CODE[50])
        {
            DataClassification = ToBeClassified;


        }

        field(2; "Document Type"; TEXT[50]) //Enum TypeDocumentOld
        {
            DataClassification = ToBeClassified;


        }

        field(3; "Is Output"; Boolean)
        {
            DataClassification = ToBeClassified;


        }

        field(4; "Is Input"; Boolean)
        {
            DataClassification = ToBeClassified;


        }

        field(5; "Tier N°"; CODE[20])
        {
            DataClassification = ToBeClassified;


        }

        field(6; "Tier Name"; TEXT[200])
        {
            DataClassification = ToBeClassified;


        }

        field(7; "Document date"; Date)
        {
            DataClassification = ToBeClassified;


        }

        field(8; "Year"; TEXT[10])
        {
            DataClassification = ToBeClassified;


        }

        field(9; "Item N°"; CODE[50])
        {
            DataClassification = ToBeClassified;


        }

        field(10; "Item Description"; TEXT[250])
        {
            DataClassification = ToBeClassified;


        }

        field(11; "Sales Qty"; Integer)
        {
            DataClassification = ToBeClassified;


        }

        field(12; "Purshase Qty"; Integer)
        {
            DataClassification = ToBeClassified;


        }

        field(13; "Unit Price HT"; Decimal)
        {
            DataClassification = ToBeClassified;


        }

        field(14; "Discount Percent"; Decimal)
        {
            DataClassification = ToBeClassified;


        }

        field(15; "Amount HT"; Decimal)
        {
            DataClassification = ToBeClassified;


        }

        field(16; "VAT Tax Amount"; Decimal)
        {
            DataClassification = ToBeClassified;


        }

        field(17; "Total Line HT"; Decimal)
        {
            DataClassification = ToBeClassified;


        }

        field(18; "Total Line TTC"; Decimal)
        {
            DataClassification = ToBeClassified;


        }


    }

    keys
    {
        // key(Key1; "Document N°")
        // {
        //     Clustered = true;
        // }
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