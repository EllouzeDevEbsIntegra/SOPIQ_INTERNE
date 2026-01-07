table 25006657 "Purchase Cart"
{
    DataClassification = CustomerContent;
    Caption = 'Purchase Cart';

    fields
    {
        field(1; "Line No."; Integer)
        {
            Caption = 'Line No.';
            DataClassification = CustomerContent;
            AutoIncrement = true; // Identifiant unique auto-incrémenté
        }
        field(2; "Type"; Enum "Purchase Line Type")
        {
            Caption = 'Type';
            DataClassification = CustomerContent;
            InitValue = Item;
            Editable = false;
        }
        field(3; "Buy-from Vendor No."; Code[20])
        {
            Caption = 'Buy-from Vendor No.';
            DataClassification = CustomerContent;
            TableRelation = Vendor;
        }
        field(4; "No."; Code[20])
        {
            Caption = 'No.';
            DataClassification = CustomerContent;
            TableRelation = Item;
            trigger OnValidate()
            var
                Item: Record Item;
            begin
                // Exemple de logique : récupérer la description si c'est un article
                if Type = Type::Item then
                    if Item.Get("No.") then
                        Description := Item."Description structurée";
            end;
        }
        field(5; "Description"; Text[100])
        {
            Caption = 'Description';
            DataClassification = CustomerContent;
        }
        field(6; "Quantity"; Decimal)
        {
            Caption = 'Quantity';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;
        }
        field(7; "Direct Unit Cost"; Decimal)
        {
            Caption = 'Direct Unit Cost';
            DataClassification = CustomerContent;
            AutoFormatType = 2;
        }
        field(8; "Compare Quote No."; Code[20])
        {
            Caption = 'Compare Quote No.';
            DataClassification = CustomerContent;
            TableRelation = "Compare Quote";
        }
        field(9; "Added Date"; Date)
        {
            Caption = 'Added Date';
            DataClassification = CustomerContent;
        }
        field(10; "Status"; Enum "Purchase Cart Status")
        {
            Caption = 'Status';
            DataClassification = CustomerContent;
        }
        field(11; "Purchase Quote No."; Code[20])
        {
            Caption = 'Purchase Quote No.';
            DataClassification = CustomerContent;
            TableRelation = "Purchase Header"."No." where("Document Type" = const(Quote));
        }
        field(12; "Ref Master"; Code[20])
        {
            Caption = 'Ref Master';
            DataClassification = CustomerContent;
            TableRelation = Item where("Produit" = const(true));
        }
        field(13; "Comment"; Text[250])
        {
            Caption = 'Comment';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(PK; "Line No.")
        {
            Clustered = true;
        }
    }
}
