tableextension 80364 "General Ledger Setup" extends "General Ledger Setup" //98
{
    fields
    {
        // Add changes to table fields here
        field(80364; AutoComment; Boolean)
        {
            Caption = 'Commentaire ligne paiement automatique';
            DataClassification = ToBeClassified;
            InitValue = false;
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