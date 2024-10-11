pageextension 80160 "Service Order Subform EDMS" extends "Service Order Subform EDMS"//25006184
{
    layout
    {
        // Add changes to page layout here
        addafter(Quantity)
        {


            field("Available Qty"; "Available Qty")
            {
                ApplicationArea = all;
                Caption = 'Stock Disponible';
                Editable = false;
                StyleExpr = FieldStyleQty;
                DecimalPlaces = 0 : 2;
            }

            // field("Prix Vente Public"; "Prix Vente Public")
            // {
            //     ApplicationArea = All;
            //     Caption = 'Prix Vente Public';
            //     Editable = false;
            //     style = Unfavorable;
            // }

            // field("Last Price First Vendor"; "Last Price First Vendor")
            // {
            //     ApplicationArea = All;
            //     Caption = 'Dernier Prix Frs Principal';
            //     Editable = false;
            // }

            // field("Last Price Date"; "Last Price Date")
            // {
            //     ApplicationArea = All;
            //     Caption = 'Date Prix Frs Principal';
            //     Editable = false;
            // }

            // field("Last Document Type"; "Last Document Type")
            // {
            //     ApplicationArea = All;
            //     Caption = 'Type Doc Prix Frs Principal';
            //     Editable = false;
            // }

        }
    }

    actions
    {
        // Add changes to page actions here
        addafter(ApplyReplacement)
        {
            action("Apply Discount")
            {
                Caption = 'Appliquer remise pour toute les lignes similaires';
                Image = Discount;
                trigger OnAction()
                var
                    SalesFunctions: Codeunit SISalesCodeUnit;
                    SalesLine: Record "Service Line EDMS";
                begin
                    CurrPage.SetSelectionFilter(SalesLine);
                    SalesLine.FindFirst();
                    SalesFunctions.UpdateServiceLineDiscount(SalesLine);
                end;
            }
        }
    }

    var
        FieldStyleQty: Text[50];

    procedure SetStyleQte(PDecimal: Decimal): Text[50]
    begin
        IF PDecimal <= 0 THEN exit('Unfavorable') ELSE exit('Favorable');
    end;

    trigger OnAfterGetRecord()
    begin
        FieldStyleQty := SetStyleQte("Available Qty");
    end;
}