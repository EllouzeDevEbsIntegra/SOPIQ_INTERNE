tableextension 80510 "Requisition Line" extends "Requisition Line"
{
    fields
    {
        // Add changes to table fields here
        field(80508; "Total Line"; Integer)
        {
            Caption = 'Total Line';
            FieldClass = FlowField;
            Editable = false;
            CalcFormula = count("Requisition Line" where("Worksheet Template Name" = field("Worksheet Template Name"), "Journal Batch Name" = FIELD("Journal Batch Name"), "Location Code" = field("Location Code")));
        }
    }

    var
        myInt: Integer;
}