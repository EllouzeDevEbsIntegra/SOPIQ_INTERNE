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
    }
    keys
    {
        key(PK; Référence)
        {
            Clustered = true;
        }
    }
}
