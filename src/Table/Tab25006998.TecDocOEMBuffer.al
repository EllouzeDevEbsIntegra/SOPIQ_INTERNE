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
        field(2; OEMNumber; Text[50])
        {
            Caption = 'OEM Number';
        }
        field(3; Marque; Text[100])
        {
            Caption = 'Marque';
        }
    }
    keys
    {
        key(PK; ParentReference, OEMNumber)
        {
            Clustered = true;
        }
    }
}
