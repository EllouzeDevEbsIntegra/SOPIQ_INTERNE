table 25006996 "TecDoc Images Buffer"
{
    DataClassification = ToBeClassified;
    Caption = 'Buffer Images TecDoc';

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
        field(3; ImageID; Integer)
        {
            Caption = 'Image ID';
            Editable = false;
        }
        field(4; Image; MediaSet)
        {
            Caption = 'Image';
        }
        field(5; RequestID; Integer)
        {
            Caption = 'Request ID';
        }
    }

    keys
    {
        key(PK; ParentReference, dataSupplierId, ImageID)
        {
            Clustered = true;
        }
        key(RequestIDKey; RequestID)
        {
            Clustered = false;
        }
    }
}
