tableextension 80170 "Sales & Receivables Setup" extends "Sales & Receivables Setup"//311
{
    fields
    {
        // Add changes to table fields here
        field(80170; "UndoShipment"; Boolean)
        {
            InitValue = false;
        }

        field(80171; VendorCodeRequired; Boolean)
        {
            Caption = 'Code vendeur Obligatoire';
            InitValue = false;
        }

        field(80172; Tolerance; Decimal)
        {
            Caption = 'Tolérance de comparaison';
            DecimalPlaces = 0 : 2;
        }

        field(80173; margeStandard; Decimal)
        {
            Caption = 'Marge Standard';
            DecimalPlaces = 0 : 2;
        }

        field(80174; margeSpecifique; Decimal)
        {
            Caption = 'Marge Fabricant Spécifique';
            DecimalPlaces = 0 : 2;
        }

        field(80175; "Reçu Caisse Serie"; code[10])
        {
            Caption = 'N° Reçu de caisse';
            DataClassification = ToBeClassified;
            TableRelation = "No. Series";
        }
        field(80176; "Retour BS"; code[10])
        {
            Caption = 'Retour BS';
            DataClassification = ToBeClassified;
            TableRelation = "No. Series";
        }
        field(80177; "Retour BS Enregistré"; code[10])
        {
            Caption = 'Retour BS Enregistré';
            DataClassification = ToBeClassified;
            TableRelation = "No. Series";
        }

    }

    var
        myInt: Integer;
}