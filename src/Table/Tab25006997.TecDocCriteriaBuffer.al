table 25006997 "TecDoc Criteria Buffer"
{
    DataClassification = ToBeClassified;
    Caption = 'Buffer Critères TecDoc';
    fields
    {
        field(1; ParentReference; Code[20])
        {
            Caption = 'Référence Article';
        }
        field(2; Nom; Text[100])
        {
            Caption = 'Nom Critère';
        }
        field(3; Valeur; Text[250])
        {
            Caption = 'Valeur';
        }
    }
    keys
    {
        key(PK; ParentReference, Nom)
        {
            Clustered = true;
        }
    }
}
