tableextension 80505 "Sales Cr.Memo Line" extends "Sales Cr.Memo Line" //115
{
    fields
    {
        // Add changes to table fields here
        field(80129; "Cust Name Imprime"; Code[200])
        {
            CalcFormula = lookup("Sales Cr.Memo Header".custNameImprime WHERE("No." = field("Document No.")));
            Caption = 'Client Imprimé';
            Editable = false;
            FieldClass = FlowField;
        }
    }

    var
        myInt: Integer;
}