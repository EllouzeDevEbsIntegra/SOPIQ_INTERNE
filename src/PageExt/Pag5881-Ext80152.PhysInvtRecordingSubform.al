pageextension 80152 "Phys. Invt. Recording Subform" extends "Phys. Invt. Recording Subform"//5881
{
    layout
    {
        addafter(Quantity)
        {
            field("Qte Prevu"; "Qte Prevu")
            {
                ApplicationArea = all;
                Editable = false;
            }

            field("Ecart"; Ecart)
            {
                ApplicationArea = all;
                Editable = false;
                StyleExpr = FieldStyleQty;
            }
        }

        modify(Quantity)
        {
            trigger OnAfterValidate()
            begin
                rec.Ecart := Quantity - "Qte Prevu";
                rec.Modify();
                FieldStyleQty := SetStyle(rec.Ecart);
            end;


        }
    }

    actions
    {
        // Add changes to page actions here
    }


    trigger OnAfterGetRecord()

    begin

        if recComInv.get("Order No.") Then begin
            recComInv.CalcFields("Qty. Expected (Base)");
        end;

        rec.Ecart := Quantity - "Qte Prevu";
        rec.Modify();
        FieldStyleQty := SetStyle(rec.Ecart);


    end;

    procedure SetStyle(PDecimal: Decimal): Text[50]
    begin
        IF PDecimal < 0 THEN exit('Unfavorable') ELSE IF PDecimal > 0 THEN exit('Favorable');
    end;

    var
        recComInv: Record "Phys. Invt. Order Line";
        FieldStyleQty: Text[50];
}