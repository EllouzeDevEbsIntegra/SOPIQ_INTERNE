tableextension 80115 "Sales Shipment Header" extends "Sales Shipment Header" //110
{
    fields
    {
        field(80113; "Montant Ouvert"; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = Sum("Sales Shipment Line"."Line Amount" WHERE("Document No." = FIELD("No."), "Qty. Shipped Not Invoiced" = Filter('>0')));
            Caption = 'Montant  Ouvert';
            Editable = false;
        }

        field(80100; Acopmpte; Decimal)
        {
            Caption = 'Total Acompte';

            FieldClass = FlowField;
            CalcFormula = sum("Payment Line"."Credit Amount" where("STOrder No." = field("Order No."), "Account No." = field("Sell-to Customer No."), Posted = filter(true)));
        }
    }

    var
        myInt: Integer;
}