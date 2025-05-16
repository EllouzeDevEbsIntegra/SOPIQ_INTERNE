table 25006995 "TecDoc Request Cache"
{
    DataClassification = ToBeClassified;
    Caption = 'Cache des requêtes TecDoc';
    fields
    {
        field(1; SearchQuery; Text[100])
        {
            Caption = 'Search Query';
        }
        field(2; SearchType; Integer)
        {
            Caption = 'Search Type';
        }
        field(3; IncludeAll; Boolean)
        {
            Caption = 'Include All';
        }
        field(4; Mrfid; Code[20])
        {
            Caption = 'MRF ID';
        }
        field(5; ResponseData; BLOB)
        {
            Caption = 'Response Data';
            DataClassification = ToBeClassified;
        }
        field(6; LastUpdated; DateTime)
        {
            Caption = 'Last Updated';
        }
    }
    keys
    {
        key(PK; SearchQuery, SearchType, IncludeAll, Mrfid)
        {
            Clustered = true;
        }
    }
}
