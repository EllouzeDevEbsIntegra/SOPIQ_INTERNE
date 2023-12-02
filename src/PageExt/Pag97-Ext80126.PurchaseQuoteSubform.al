pageextension 80126 "Purchase Quote Subform" extends "Purchase Quote Subform" //97
{
    layout
    {

        addafter(Quantity)
        {
            field("Available Inventory"; Itemstk."Available Inventory")
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

            field("Vendor Item No"; "Vendor Item No.")
            {
                Caption = 'Ref Fournisseur';
                ApplicationArea = All;
                Editable = false;
            }


        }

        addafter("Vendor Unit Cost")
        {
            field("asking price"; "asking price")
            {
                ApplicationArea = All;
                Caption = 'Prix demandé';
                StyleExpr = FieldStyleNegPrice;
                trigger OnValidate()
                begin
                    FieldStyleNegPrice := SetStyleNegociation("negotiated price", "asking price");
                end;
            }
            field("asking qty"; "asking qty")
            {
                ApplicationArea = All;
                Caption = 'Qté demandé';
            }

            field("negotiated price"; "negotiated price")
            {
                ApplicationArea = All;
                Caption = 'Prix négocié';
                StyleExpr = FieldStyleNegPrice;
                trigger OnValidate()
                begin
                    FieldStyleNegPrice := SetStyleNegociation("negotiated price", "asking price");
                end;
            }
            field("negotiated qty"; "negotiated qty")
            {
                ApplicationArea = All;
                Caption = 'Qté négocié';
            }


        }

        modify("Vendor Unit Cost")
        {
            Editable = false;
        }

        modify("Vendor Quantity")
        {
            Editable = false;
        }
    }

    actions
    {
        // Add changes to page actions here
    }

    trigger OnAfterGetRecord()

    begin

        if ItemStk.get("No.") Then
            ItemStk.CalcFields("Qty. on Purch. Order", "Available Inventory");

        FieldStyleQty := SetStyle(ItemStk.Inventory);
        FieldStyleOnOrdQty := SetStyle(ItemStk."Qty. on Purch. Order");


        FieldStyleNegPrice := SetStyleNegociation("negotiated price", "asking price");
    end;

    var
        ItemStk: Record Item;
        FieldStyleQty, FieldStyleOnOrdQty, FieldStyleNegPrice : Text[50];

    procedure SetStyle(PDecimal: Decimal): Text[50]
    begin
        IF PDecimal <= 0 THEN exit('Unfavorable') ELSE exit('Favorable');
    end;

    procedure SetStyleNegociation(PrixNeg: Decimal; PrixDemandé: Decimal): Text[50]
    begin
        IF (PrixNeg > 0) then
            IF PrixNeg > PrixDemandé THEN exit('Unfavorable') ELSE exit('Favorable');
    end;
}