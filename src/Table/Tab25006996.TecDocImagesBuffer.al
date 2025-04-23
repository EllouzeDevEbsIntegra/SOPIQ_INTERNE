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
        field(2; ImageID; Integer)
        {
            Caption = 'Image ID';
            Editable = false;
        }
        field(3; Image; MediaSet)
        {
            Caption = 'Image';
        }
    }
    keys
    {
        key(PK; ParentReference, ImageID)
        {
            Clustered = true;
        }
    }
}
