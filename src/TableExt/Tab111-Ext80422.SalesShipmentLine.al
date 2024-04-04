tableextension 80422 "Sales Shipment Line" extends "Sales Shipment Line" //111
{

    fields
    {
        field(80421; CustDivers; Boolean)
        {
            CalcFormula = lookup("customer"."Is Divers" where("No." = field("Bill-to Customer No.")));
            Caption = 'solde';
            FieldClass = FlowField;
        }
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

        field(80417; "Qty BS To Invoice"; Decimal)
        {
            DataClassification = ToBeClassified;
        }

        field(80418; "Document No BS Inverse"; code[20])
        {
            DataClassification = ToBeClassified;
        }
        field(80419; "Line No BS Inverse"; Integer)
        {
            DataClassification = ToBeClassified;
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

    // @@@@@@ TO VERIFY
    trigger OnafterInsert()
    var
        salesCodeUnit: Codeunit SISalesCodeUnit;
    begin
        salesCodeUnit.afterInsertSalesShipLine(rec);
    end;

}

