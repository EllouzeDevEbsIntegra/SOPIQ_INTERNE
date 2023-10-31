table 50020 "items Master"
{
    DataClassification = ToBeClassified;
    DataPerCompany = false;
    Permissions = TableData "items Master" = rimd;


    fields
    {
        field(1000; id; Integer)
        {
            DataClassification = ToBeClassified;
            AutoIncrement = true;
        }
        field(1; No; Code[20])
        {
            DataClassification = ToBeClassified;
            TableRelation = Item."No.";

        }
        field(2; Famille; Code[200])
        {
            DataClassification = ToBeClassified;
            TableRelation = "Item Category".Code;
        }

        field(3; "Sous Famille"; Code[200])
        {
            DataClassification = ToBeClassified;
            TableRelation = "Item Category".Code;
        }

        field(4; "Master"; Code[50])
        {
            DataClassification = ToBeClassified;
            TableRelation = "Item"."No.";
        }

        field(20; Company; Code[20])
        {
            DataClassification = ToBeClassified;
            TableRelation = Company.Name;
        }

        field(21; Verified; Boolean)
        {
            DataClassification = ToBeClassified;
            InitValue = false;
        }

        field(22; "Add date"; Date)
        {
            DataClassification = ToBeClassified;
        }

        field(23; "Add User"; code[50])
        {
            DataClassification = ToBeClassified;
        }

        field(24; "Validate Date"; Date)
        {
            DataClassification = ToBeClassified;
        }

        field(25; "Validate User"; code[50])
        {
            DataClassification = ToBeClassified;
        }

        field(26; "Type Ajout"; Text[200])
        {
            DataClassification = ToBeClassified;
        }


    }

    keys
    {
        key(Key1; id)
        {
            Clustered = true;
        }
    }


}