pageextension 80135 "Customer Statistics FactBox 2" extends "Customer Statistics FactBox" //9082
{
    layout
    {
        addafter("Balance (LCY)")
        {
            group("Encours Client")
            {
                Caption = 'Encours Client';
                field("Opened Invoice"; "Opened Invoice")
                {
                    Caption = 'Facture et Avoir Ouverts';
                }
                field("Shipped Not Invoiced"; "Shipped Not Invoiced BL")
                {
                    Caption = 'Bon de livraison non facturé';
                }

                field("Return Receipts Not Invoiced"; "Return Receipts Not Invoiced")
                {
                    Caption = 'Réception retour non facturé';
                }

                field("Total Encours"; TotalEncours)
                {
                    Caption = 'Total Encours';
                    StyleExpr = FieldStyle;
                }

                field("Nb facture NP"; "Nb Opened Invoice")
                {
                    Caption = 'Nombre de facture non payée';
                }

            }
        }
        // Add changes to page layout here
        // addafter("Balance (LCY)")
        // {
        //     field("Opened Invoice"; "Opened Invoice")
        //     {
        //         Caption = 'Total Facture et Avoir Ouverts';
        //     }
        // }
    }

    actions
    {
        // Add changes to page actions here
    }

    var
        TotalEncours, Depassement : Decimal;
        FieldStyle: Text;


    trigger OnAfterGetRecord()
    begin
        CalcFields("Opened Invoice", "Shipped Not Invoiced BL");

        TotalEncours := "Opened Invoice" + "Shipped Not Invoiced BL" + "Return Receipts Not Invoiced";
        Depassement := "Credit Limit (LCY)" - TotalEncours;
        FieldStyle := SetStyleAmount(Depassement);
    end;

    procedure SetStyleAmount(PDecimal: Decimal): Text[50]
    begin
        IF PDecimal <= 0 THEN exit('Unfavorable') ELSE exit('Favorable');
    end;
}