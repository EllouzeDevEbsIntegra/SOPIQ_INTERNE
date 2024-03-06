tableextension 80412 "Ligne archive BS" extends "Ligne archive BS"//50010
{
    fields
    {
        // Add changes to table fields here
        field(80412; custNameImprime; Text[200])
        {
            Caption = 'Nom Client Imprimé';
            CalcFormula = lookup("Entete archive BS".custNameImprime where("No." = field("Document No.")));
            Editable = false;
            FieldClass = FlowField;
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