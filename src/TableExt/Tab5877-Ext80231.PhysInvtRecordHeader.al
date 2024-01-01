tableextension 80231 "Phys. Invt. Record Header" extends "Phys. Invt. Record Header"//5877
{
    fields
    {
        // Add changes to table fields here
        field(80231; "NB Ecart"; Integer)
        {
            AutoFormatType = 1;
            CalcFormula = count("Phys. Invt. Record Line" WHERE("Recording No." = field("Recording No."), Ecart = filter(<> 0), Recorded = filter(true), "Order No." = field("Order No.")));
            Caption = 'NB Ecart';
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