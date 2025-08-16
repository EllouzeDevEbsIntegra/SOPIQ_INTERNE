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
        field(2; dataSupplierId; Code[20])
        {
            Caption = 'ID Fabricant';
        }
        field(3; Fabricant; Text[100])
        {
            Caption = 'Fabricant';
        }
        field(4; Description; Text[250])
        {
            Caption = 'Description';
        }
        field(5; Famille; Text[100])
        {
            Caption = 'Famille';
        }
        field(6; nbPicture; Integer)
        {
            Caption = 'Nombre d''images';
        }
        field(7; LastUpdated; DateTime)
        {
            Caption = 'Last Updated';
        }
        field(8; RequestID; Integer)
        {
            Caption = 'Request ID';
        }
        field(9; "Item Created"; Boolean)
        {
            CalcFormula = exist(Item where("No." = field(Référence), "mrfID" = field(dataSupplierId)));
            FieldClass = FlowField;
        }

    }

    keys
    {
        key(PK; Référence, dataSupplierId)
        {
            Clustered = true;
        }
        key(SecondaryKey; Référence, Fabricant)
        {
            Clustered = false;
        }
        key(RequestIDKey; RequestID)
        {
            Clustered = false;
        }
    }
}
