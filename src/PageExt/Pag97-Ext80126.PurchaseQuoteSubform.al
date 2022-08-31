pageextension 80126 "Purchase Quote Subform" extends "Purchase Quote Subform" //97
{
    layout
    {
        addafter(Quantity)
        {
            field(Stock; Itemstk.Inventory)
            {
                Caption = 'Stock actuel';
                ApplicationArea = All;
                Editable = false;
                StyleExpr = FieldStyleQty;
            }

            field("On Pursh. Qty"; Itemstk."Qty. on Purch. Order")
            {
                Caption = 'Qté cmd sur achat';
                ApplicationArea = All;
                Editable = false;
                StyleExpr = FieldStyleOnOrdQty;
            }


        }
    }

    actions
    {
        // Add changes to page actions here
    }

    trigger OnAfterGetRecord()

    begin

        if ItemStk.get("No.") Then
            ItemStk.CalcFields(Inventory, "Qty. on Purch. Order");

        FieldStyleQty := SetStyle(ItemStk.Inventory);
        FieldStyleOnOrdQty := SetStyle(ItemStk."Qty. on Purch. Order");
    end;

    var
        ItemStk: Record Item;
        FieldStyleQty, FieldStyleOnOrdQty : Text[50];

    procedure SetStyle(PDecimal: Decimal): Text[50]
    begin
        IF PDecimal <= 0 THEN exit('Unfavorable') ELSE exit('Favorable');
    end;
}