tableextension 80121 "Purchases & Payables Setup" extends "Purchases & Payables Setup"//312
{
    fields
    {
        field(80120; "Default Vendor"; Code[20])
        {
            Caption = 'Fournisseur Par Défaut';
            TableRelation = Vendor;
            DataClassification = ToBeClassified;

        }

        field(80121; "MF obligatoire"; Boolean)
        {
            Caption = 'MF Fournisseur Obligatoire';
            InitValue = false;
            DataClassification = ToBeClassified;

        }

        field(80122; UpdateProfitOblogatoire; Boolean)
        {
            Caption = 'Mise à jour marge Obligatoire';
            InitValue = false;
            DataClassification = ToBeClassified;
        }

        field(80123; "Current Year"; Integer)
        {
            DataClassification = ToBeClassified;
        }

        field(80124; "Last Year"; Integer)
        {
            DataClassification = ToBeClassified;
        }

        field(80125; PurchaserCodeRequired; Boolean)
        {
            Caption = 'Code acheteur obligatoire';
            InitValue = false;
            DataClassification = ToBeClassified;
        }

        field(80126; controlePurshOrder; Boolean)
        {
            Caption = 'Contrôle Commande Achat';
            InitValue = false;
            DataClassification = ToBeClassified;
        }
    }

    var
        myInt: Integer;
}