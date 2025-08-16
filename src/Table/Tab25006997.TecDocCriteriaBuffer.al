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
        field(2; dataSupplierId; Code[20])
        {
            Caption = 'ID Fabricant';
        }
        field(3; Nom; Text[100])
        {
            Caption = 'Nom Critère';
        }
        field(4; Valeur; Text[250])
        {
            Caption = 'Valeur';
        }
        field(5; RequestID; Integer)
        {
            Caption = 'Request ID';
        }
    }

    keys
    {
        key(PK; ParentReference, dataSupplierId, Nom)
        {
            Clustered = true;
        }
        key(RequestIDKey; RequestID)
        {
            Clustered = false;
        }
    }
}
