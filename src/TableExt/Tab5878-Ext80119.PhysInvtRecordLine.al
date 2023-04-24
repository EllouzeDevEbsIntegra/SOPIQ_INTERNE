tableextension 80119 "Phys. Invt. Record Line" extends "Phys. Invt. Record Line"//5878
{

    fields
    {
        field(80119; "Qte Prevu"; Decimal)
        {
            Caption = 'Quantité Prévu';
            DecimalPlaces = 0 : 0;
            FieldClass = FlowField;
            CalcFormula = sum("Phys. Invt. Order Line"."Qty. Expected (Base)" where("Document No." = field("Order No."), "Item No." = field("Item No.")));
        }

        field(80120; "Ecart"; Decimal)
        {
            Caption = 'Ecart';
            DataClassification = ToBeClassified;
            DecimalPlaces = 0 : 0;
        }
    }

    var
        myInt: Integer;
}