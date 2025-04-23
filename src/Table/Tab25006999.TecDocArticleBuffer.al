table 25006999 "TecDoc Article Buffer"
{
    DataClassification = ToBeClassified;
    Caption = 'Buffer Articles TecDoc';
    fields
    {
        field(1; Référence; Code[20])
        {
            Caption = 'Référence';
        }
        field(2; Fabricant; Text[100])
        {
            Caption = 'Fabricant';
        }
        field(3; Description; Text[250])
        {
            Caption = 'Description';
        }
        field(4; Famille; Text[100])
        {
            Caption = 'Famille';
        }
        field(5; nbPicture; Integer)
        {
            Caption = 'OEM Part';
        }
    }
    keys
    {
        key(PK; Référence)
        {
            Clustered = true;
        }
    }
}
