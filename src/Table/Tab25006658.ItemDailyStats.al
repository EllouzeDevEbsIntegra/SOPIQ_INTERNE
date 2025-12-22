table 25006658 "Item Daily Stats"
{
    DataClassification = ToBeClassified;
    Caption = 'Statistiques Quotidiennes Article';

    fields
    {
        field(1; "Item No."; Code[20])
        {
            DataClassification = ToBeClassified;
            Caption = 'N° Article';
            TableRelation = Item."No.";
        }

        field(2; "Date"; Date)
        {
            DataClassification = ToBeClassified;
            Caption = 'Date';
        }

        field(3; "Total Sold"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'Total Vendu';
            DecimalPlaces = 0 : 5;
        }

        field(4; "Stock Level"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'Niveau Stock';
            DecimalPlaces = 0 : 5;
        }

        field(5; "Has Positive Stock"; Boolean)
        {
            DataClassification = ToBeClassified;
            Caption = 'Stock Positif';
        }

        field(6; Year; Integer)
        {
            DataClassification = ToBeClassified;
            Caption = 'Année';
        }

        field(7; Month; Integer)
        {
            DataClassification = ToBeClassified;
            Caption = 'Mois';
        }
    }

    keys
    {
        key(PK; "Item No.", "Date")
        {
            Clustered = true;
        }

        key(YearMonth; Year, Month, "Item No.")
        {
        }

        key(ItemYear; "Item No.", Year)
        {
        }
    }
}
