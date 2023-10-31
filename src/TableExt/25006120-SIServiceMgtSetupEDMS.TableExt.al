tableextension 80150 "Service Mgt. Setup EDMS" extends "Service Mgt. Setup EDMS" //25006120
{
    fields
    {
        field(80000; "Begin Pack"; code[20])
        {
            Caption = 'Début package';
            DataClassification = ToBeClassified;
            TableRelation = "Standard Text";
        }
        field(80001; "End Pack"; code[20])
        {
            Caption = 'Fin package';
            DataClassification = ToBeClassified;
            TableRelation = "Standard Text";
        }

    }
}
