pageextension 80114 "Sales Order Subform" extends "Sales Order Subform" //46
{
    layout

    {

        addafter("Unit Price") // Ajout du champ prix initial dans ligne vente
        {
            // field("Stk Mg Principal"; recItem.StockMagPrincipal)
            // {
            //     ApplicationArea = All;
            //     Editable = false;
            //     StyleExpr = FieldStyleQty;
            // }
            field("Prix Initial";
            rec."Initial Unit Price")
            {
                ApplicationArea = All;
            }
        }
    }

    actions
    {
        // Add changes to page actions here
    }

    var
        Text006: Label 'Prices including VAT cannot be calculated when %1 is %2.';
        GLSetup: Record "General Ledger Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        recItem: Record "Item";
        GLSetupRead: Boolean;
        recInventorySetup: Record "Inventory Setup";
        FieldStyleQty: Text[50];

    procedure SetStyleQte(PDecimal: Decimal): Text[50]
    begin
        IF PDecimal <= 0 THEN exit('Unfavorable') ELSE exit('Favorable');
    end;
}