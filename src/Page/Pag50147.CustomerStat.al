page 50147 "Customer Stat"
{
    PageType = List;
    Caption = 'Statistiques Clients';
    ApplicationArea = All;
    SourceTable = Customer;
    SourceTableView = sorting("No.");
    UsageCategory = Lists;
    ModifyAllowed = false;
    DeleteAllowed = false;
    InsertAllowed = false;

    layout
    {
        area(Content)
        {
            repeater("Search Item")
            {
                Caption = 'Recherche Client';
                field("No."; "No.")
                {
                    Caption = 'Code';
                    Editable = false;
                    ApplicationArea = All;
                    Style = strong;
                }
                field(Name; Name)
                {
                    Caption = 'Client';
                    ApplicationArea = All;
                    Editable = false;
                    Style = strong;
                }
                field("Opened Invoice"; "Opened Invoice")
                {
                    Caption = 'Facture et Avoir Ouverts';
                }
                field("Payment Method Code"; "Payment Method Code")
                {
                    Caption = 'Moyen de Paiement';
                }
                field("Cheque En Coffre"; "Cheque En Coffre")
                {

                }

                field("Cheque Impaye"; "Cheque Impaye")
                {

                }

                field("Traite En Coff."; "Traite En Coff.")
                {

                }
                field("Traite En Escompte"; "Traite En Escompte")
                {

                }

                field("Traite Impaye"; "Traite Impaye")
                {

                }
                // field(MoyenJourPaiement; MoyenJourPaiement)
                // {
                //     Caption = 'Moyen Jour Paiement';
                // }
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

                field("Crédit autorisé"; "Crédit autorisé")
                {
                    Caption = 'Encours Autorisé (Principal)';
                    StyleExpr = FieldStyle2;
                    Editable = true;
                }

                field("Dépassement (% Encours princiapl)"; Depassement2)
                {
                    Caption = 'Dépassement (% Encours princiapl)';
                }

                field("Encours supplémentaire"; "Encours supplémentaire")
                {
                    Caption = 'Encours Supplémentaire';
                }

                field("Nb facture NP"; "Nb Opened Invoice")
                {
                    Caption = 'Nombre de facture non payée';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ActionName)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin

                end;
            }
        }
    }

    var
        TotalEncours, Depassement, Depassement2 : Decimal;
        FieldStyle, FieldStyle2 : Text;

    trigger OnAfterGetRecord()
    var
    //SalesInvoiceHeader: Record "Sales Invoice Header";

    begin
        CalcFields("Opened Invoice", "Shipped Not Invoiced BL");

        //MoyenJourPaiement := 0;
        // SalesInvoiceHeader.Reset();
        // SalesInvoiceHeader.SetRange("Bill-to Customer No.", "No.");
        // SalesInvoiceHeader.CalcFields("Remaining Amount");
        // SalesInvoiceHeader.SetRange("Remaining Amount", 0);
        //nbInvoice := SalesInvoiceHeader.Count;
        // if SalesInvoiceHeader.FindSet() then begin
        //     repeat
        //         MoyenJourPaiement := MoyenJourPaiement + SalesInvoiceHeader.MoyJourPaiement(SalesInvoiceHeader);
        //     until SalesInvoiceHeader.Next() = 0;
        //     MoyenJourPaiement := MoyenJourPaiement / nbInvoice;
        // end;

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