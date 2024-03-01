tableextension 80150 "Service Mgt. Setup EDMS" extends "Service Mgt. Setup EDMS" //25006120
{
    fields
    {
        field(79999; "Global Ress. Mondata"; Boolean)
        {
            caption = 'Ressource Global Obligatoire';
            dataClassification = ToBeClassified;
        }
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

        field(80002; "Statut Vehicule Pret"; code[20])
        {
            Caption = 'Statut Vehicule Pret';
            DataClassification = ToBeClassified;
            TableRelation = "Document Status".Code;
        }

        field(80003; "Statut Vehicule Receptionne"; code[20])
        {
            Caption = 'Statut Vehicule Réceptionné';
            DataClassification = ToBeClassified;
            TableRelation = "Document Status".Code;
        }

    }
}
