tableextension 80720 "Sales Invoice Entity Aggregate" extends "Sales Invoice Entity Aggregate" //5475 
{
    fields
    {
        // Add changes to table fields here
        field(80720; "document profile"; Option)
        {
            FieldClass = FlowField;
            CalcFormula = lookup("Sales Invoice Header"."Document Profile" where("No." = field("No.")));
            OptionMembers = " ","Spare Parts Trade","Vehicles Trade",Service,Rent;
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