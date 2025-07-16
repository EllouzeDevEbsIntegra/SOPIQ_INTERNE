tableextension 80507 Vehicle extends Vehicle //25006005
{
    fields
    {
        // Add changes to table fields here
        field(80507; "Date Assurance"; Date)
        {
            Caption = 'Date Assurance';
            DataClassification = ToBeClassified;
        }
        field(80508; "Periode Assurance"; Option)
        {
            Caption = 'Période Assurance';
            DataClassification = ToBeClassified;
            OptionMembers = " ","6M","12M";
        }
        field(80509; "Assurance Compagnie"; Enum "AssuranceCompany")
        {
            Caption = 'Compagnie Assurance';
            DataClassification = ToBeClassified;
        }
        field(80510; "Date Visite Technique"; Date)
        {
            Caption = 'Date Visite Technique';
            DataClassification = ToBeClassified;
        }
        field(80511; "Type Proprietaire"; Option)
        {
            Caption = 'Type Propriétaire';
            DataClassification = ToBeClassified;
            OptionMembers = " ","Particulier","Entreprise","Leasing";
        }

    }

    keys
    {
        // Add changes to keys here
    }

    fieldgroups
    {
        // Add changes to field groups here
    }

    var
        myInt: Integer;
}