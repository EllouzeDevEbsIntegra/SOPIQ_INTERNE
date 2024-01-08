pageextension 80180 "Posted Sales Invoices" extends "Posted Sales Invoices"//143
{
    layout
    {
        // Add changes to page layout here
        addafter("Amount Including VAT")
        {
            field("Moy Jour Paiement"; MoyJourPaiement(rec))
            {
                Caption = 'Moyen Jour Paiement';
            }

            field("Montant reçu caisse"; "Montant reçu caisse")
            {
                Caption = 'Montant reçu caisse';
                trigger OnDrillDown()
                begin
                    DoDrillDown;
                end;
            }
            field("No reçu caisse"; "No reçu caisse")
            {
                ApplicationArea = all;
                trigger OnDrillDown()
                var
                    recuCaisse: Record "Recu Caisse";
                begin
                    recuCaisse.SetRange("No", rec."No reçu caisse");
                    PAGE.Run(PAGE::"Recu de caisse", recuCaisse);
                end;
            }
            // field("Payment Terms Code"; "Payment Terms Code")
            // {
            //     caption = 'Condition Paiement';
            // }

            field(custNameImprime; custNameImprime)
            {

            }

            field(custAdresseImprime; custAdresseImprime)
            {

            }

            field(custMFImprime; custMFImprime)
            {

            }

            field(custVINImprime; custVINImprime)
            {

            }
        }
    }

    actions
    {
        // Add changes to page actions here



    }

    var
        myInt: Integer;

    local procedure MoyJourPaiement(Facture: Record "Sales Invoice Header"): Decimal
    var
        PaymentLine: Record "Payment Line";
        MoyJourPaiement, CumulJourPaiement, nbPaiement, totalPaiement : Decimal;
        searchFacture: Text[50];

    begin
        searchFacture := '*' + Facture."No." + '*';
        nbPaiement := 0;
        totalPaiement := 0;

        // Calcul total des paiement
        PaymentLine.Reset();
        PaymentLine.SetFilter("Applies-to Invoices Nos.", '%1', searchFacture);
        PaymentLine.SetRange(IsCopy, false);
        PaymentLine.SetRange("Account Type", 1);

        if PaymentLine.FindSet() then begin
            repeat

                if (PaymentLine."Payment Class" = 'ENC_RS')
                THEN begin
                end
                ELSE begin
                    totalPaiement := totalPaiement - PaymentLine."STMontant Initial DS";
                    nbPaiement := nbPaiement + 1;
                end;

            until PaymentLine.Next() = 0;
        end;


        // Calcul nombre de jours moyen des paiements
        MoyJourPaiement := 0;
        CumulJourPaiement := 0;
        PaymentLine.Reset();
        PaymentLine.SetFilter("Applies-to Invoices Nos.", '%1', searchFacture);
        PaymentLine.SetRange(IsCopy, false);
        PaymentLine.SetRange("Account Type", 1);

        if PaymentLine.FindSet() then begin
            repeat

                if (PaymentLine."Payment Class" = 'ENC_RS')
                THEN begin
                end
                ELSE begin
                    if (totalPaiement <> 0) AND (PaymentLine."Due Date" >= rec."Posting Date")
                    THEN
                        CumulJourPaiement := CumulJourPaiement + ((-PaymentLine."STMontant Initial DS" / totalPaiement) * (PaymentLine."Due Date" - rec."Posting Date"))
                end;



            until PaymentLine.Next() = 0;
        end;
        MoyJourPaiement := CumulJourPaiement;
        exit(MoyJourPaiement);
    end;

    local procedure DoDrillDown()
    var
        SalesInvoiceHeader: Record "Recu Caisse Document";
    begin
        SalesInvoiceHeader.SetRange("Document No", rec."No.");
        PAGE.Run(PAGE::"Recu Document List", SalesInvoiceHeader);
    end;
}