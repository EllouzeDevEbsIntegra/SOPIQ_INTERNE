tableextension 80140 "Sales Invoice Header" extends "Sales Invoice Header"//112
{
    fields
    {
        // Add changes to table fields here
        field(80140; "Moy Jour Paiement"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'Moyen Jour Paiement';
            DecimalPlaces = 0 : 2;
        }

        field(80141; "DiscountAmount"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = sum("Sales Invoice Line"."Line Discount Amount" WHERE("Document No." = field("No.")));
            Caption = 'Type MO';
            Editable = false;
            FieldClass = FlowField;
        }
    }

    var
        myInt: Integer;
}