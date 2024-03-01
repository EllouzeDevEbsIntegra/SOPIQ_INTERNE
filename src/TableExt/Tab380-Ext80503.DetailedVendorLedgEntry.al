tableextension 80503 "Detailed Vendor Ledg. Entry" extends "Detailed Vendor Ledg. Entry"//380 
{
    fields
    {
        // Add changes to table fields here
        field(80503; "Document Date"; Date)
        {
            CalcFormula = lookup("Vendor Ledger Entry"."Document Date" WHERE("Entry No." = FIELD("Vendor Ledger Entry No."), "Document No." = field("Document No.")));
            Caption = 'Document Date';
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