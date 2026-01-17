table 25006897 "Transporter Setup"
{
    Caption = 'Transporter Setup';
    DataClassification = CustomerContent;

    fields
    {
        field(1; Code; Code[20])
        {
            Caption = 'Code';
            DataClassification = SystemMetadata;
            NotBlank = true;
        }
        field(10; Description; Text[100])
        {
            Caption = 'Description';
            DataClassification = CustomerContent;
        }
        field(20; "API URL"; Text[250])
        {
            Caption = 'API URL';
            DataClassification = CustomerContent;
            NotBlank = true;
            ExtendedDatatype = URL;
        }
        field(21; "API Key"; Text[250])
        {
            Caption = 'API Key';
            DataClassification = CustomerContent;
            NotBlank = true;
        }
        field(90; "Last Fetched DateTime"; DateTime)
        {
            Caption = 'Last Fetched DateTime';
            DataClassification = SystemMetadata;
            Editable = false;
        }
    }

    keys
    {
        key(PK; Code)
        {
            Clustered = true;
        }
    }
}