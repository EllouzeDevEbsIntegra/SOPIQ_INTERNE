pageextension 80224 "Sales Quote Subform" extends "Sales Quote Subform"//95
{
    layout
    {
        // Add changes to page layout here
        addafter("Unit Price") // Ajout du champ prix initial dans ligne vente
        {
            field("Stk Mg Principal"; "Stk Mg Principal")
            {
                ApplicationArea = All;
                Editable = false;
                StyleExpr = FieldStyleQty;
                DecimalPlaces = 0 : 2;

            }
        }
    }

    actions
    {
        // Add changes to page actions here
    }

    var
        FieldStyleQty: Text[50];

    procedure SetStyleQte(PDecimal: Decimal): Text[50]
    begin
        IF PDecimal <= 0 THEN exit('Unfavorable') ELSE exit('Favorable');
    end;

    trigger OnAfterGetRecord()
    begin
        FieldStyleQty := SetStyleQte("Stk Mg Principal");
    end;
}