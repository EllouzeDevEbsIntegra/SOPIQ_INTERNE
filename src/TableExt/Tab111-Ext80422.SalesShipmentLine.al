tableextension 80422 "Sales Shipment Line" extends "Sales Shipment Line" //111
{
    fields
    {
        field(80422; solde; Boolean)
        {
            CalcFormula = lookup("Entete archive BS".solde where("No." = field("Document No.")));
            Caption = 'solde';
            FieldClass = FlowField;
        }

        field(80423; "Salesperson Code"; code[20])
        {
            CalcFormula = lookup("Sales Shipment Header"."Salesperson Code" where("No." = field("Document No.")));
            Caption = 'Code Vendeur';
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