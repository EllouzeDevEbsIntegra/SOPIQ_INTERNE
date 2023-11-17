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
    }

    var
        myInt: Integer;
}