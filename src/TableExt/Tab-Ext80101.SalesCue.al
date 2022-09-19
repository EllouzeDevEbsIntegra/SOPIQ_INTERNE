tableextension 80101 "Sales Cue" extends "Sales Cue"

{
    fields
    {
        field(50101; "Today Sum Sales"; Decimal)
        {
            Caption = 'Total des ventes du jour';

            FieldClass = FlowField;
            CalcFormula = sum("Sales Line"."Line Amount" where("Shipment Date" = field("date jour")));
            // CalcFormula = sum("Sales Shipment Line"."Line Amount" where("Shipment Date" = field("date jour")));

        }

        field(50102; "Sales Line PU Modif"; Integer)
        {
            Caption = 'Ligne vente avec prix unitaire modifié';

            FieldClass = FlowField;
            CalcFormula = count("Sales Line" where("Price modified" = filter(true), "Ctrl Modified Price" = filter(false), "Document Type" = filter(Order)));

        }
        field(50103; "date jour"; Date)
        {

        }
    }

    var
        myInt: Integer;
}