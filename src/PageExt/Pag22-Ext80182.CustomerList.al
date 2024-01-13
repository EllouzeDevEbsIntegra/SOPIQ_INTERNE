pageextension 80182 "Customer List" extends "Customer List"//22
{
    layout
    {
        addlast(Control1)
        {
            field("Opened Invoice"; "Opened Invoice")
            {
                Caption = 'Facture et Avoir Ouverts';
            }
            // field("Shipped Not Invoiced"; "Shipped Not Invoiced BL")
            // {
            //     Caption = 'Bon de livraison non facturé';
            // }

            // field("Return Receipts Not Invoiced"; "Return Receipts Not Invoiced")
            // {
            //     Caption = 'Réception retour non facturé';
            // }

            // field("Total Encours"; TotalEncours)
            // {
            //     Caption = 'Total Encours';
            //     StyleExpr = FieldStyle;
            // }

            // field("Crédit autorisé"; "Crédit autorisé")
            // {
            //     Caption = 'Encours Autorisé (Principal)';
            //     StyleExpr = FieldStyle2;
            //     Editable = true;
            // }

            // field("Dépassement (% Encours princiapl)"; Depassement2)
            // {
            //     Caption = 'Dépassement (% Encours princiapl)';
            // }

            // field("Encours supplémentaire"; "Encours supplémentaire")
            // {
            //     Caption = 'Encours Supplémentaire';
            // }

            // field("Nb facture NP"; "Nb Opened Invoice")
            // {
            //     Caption = 'Nombre de facture non payée';
            // }
        }
        // Add changes to page layout here
        addafter(CustomerStatisticsFactBox)
        {
            part(SpecificCustStatFactbox; "Specific Cust. Stat. FactBox")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "No." = FIELD("No.");
            }
        }
    }

    actions
    {
        // Add changes to page actions here
    }

    var
        TotalEncours, Depassement, Depassement2 : Decimal;
        FieldStyle, FieldStyle2 : Text;


    trigger OnAfterGetRecord()
    begin
        CalcFields("Opened Invoice", "Shipped Not Invoiced BL");

        TotalEncours := "Opened Invoice" + "Shipped Not Invoiced BL" + "Return Receipts Not Invoiced";
        Depassement := "Credit Limit (LCY)" - TotalEncours;

        if "Crédit autorisé" - TotalEncours < 0 then
            Depassement2 := "Crédit autorisé" - TotalEncours else
            Depassement2 := 0;

        FieldStyle := SetStyleAmount(Depassement);
        FieldStyle2 := SetStyleAmount(Depassement2);
    end;

    procedure SetStyleAmount(PDecimal: Decimal): Text[50]
    begin
        IF PDecimal <= 0 THEN exit('Unfavorable') ELSE exit('Favorable');
    end;


}