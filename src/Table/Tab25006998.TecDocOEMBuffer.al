table 25006998 "TecDoc OEM Buffer"
{
    DataClassification = ToBeClassified;
    Caption = 'Buffer OEM TecDoc';

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
        field(3; OEMNumber; Text[50])
        {
            Caption = 'OEM Number';
        }
        field(4; Marque; Text[100])
        {
            Caption = 'Marque';
        }
        field(5; RequestID; Integer)
        {
            Caption = 'Request ID';
        }
    }

    keys
    {
        key(PK; ParentReference, dataSupplierId, OEMNumber, Marque)
        {
            Clustered = true;
        }
        key(RequestIDKey; RequestID)
        {
            Clustered = false;
        }
    }
}
