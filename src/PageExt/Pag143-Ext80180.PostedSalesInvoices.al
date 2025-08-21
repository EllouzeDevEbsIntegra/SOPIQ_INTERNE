pageextension 80180 "Posted Sales Invoices" extends "Posted Sales Invoices"//143
{
    layout
    {
        // Add changes to page layout here
        addafter("Amount Including VAT")
        {
            field(RemiseMoyenne; RemiseMoyenne)
            {
                ApplicationArea = all;
                Caption = 'Remise Moyenne';
            }
            field("Moy Jour Paiement"; MoyJourPaiement(rec))
            {
                ApplicationArea = all;
                Caption = 'Moyen Jour Paiement';
            }

            field("Montant reçu caisse"; "Montant reçu caisse")
            {
                ApplicationArea = all;
                Caption = 'Montant reçu caisse';
                trigger OnDrillDown()
                begin
                    DoDrillDown;
                end;
            }
            field(solde; solde)
            {
                ApplicationArea = all;
                Caption = 'Soldé';
            }
            // field("No reçu caisse"; "No reçu caisse")
            // {
            //     ApplicationArea = all;
            //     trigger OnDrillDown()
            //     var
            //         recuCaisse: Record "Recu Caisse";
            //     begin
            //         recuCaisse.SetRange("No", rec."No reçu caisse");
            //         PAGE.Run(PAGE::"Recu de caisse", recuCaisse);
            //     end;
            // }
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
            field("Linked Paiement Line"; "Linked Paiement Line")
            {
                ApplicationArea = all;
                Caption = 'Ligne Paiement Liée';
                trigger OnDrillDown()
                var
                    recRecuCaisse: Record "Recu Caisse";
                begin
                    recRecuCaisse.Reset();
                    recRecuCaisse.SetRange(No, rec."Linked Paiement Line");
                    if rec."Linked Paiement Line" <> '' then begin
                        PAGE.Run(PAGE::"Recu de caisse", recRecuCaisse);
                    end else
                        Error('Aucune ligne de paiement liée trouvée.');
                end;
            }
        }
    }

    actions
    {
        // Add changes to page actions here



    }

    var
        RemiseMoyenne: Decimal;

    trigger OnAfterGetRecord()
    begin
        rec.CalcFields("Montant reçu caisse", "Linked Paiement Line");
        if (getMntBrutHT(rec) <> 0) then RemiseMoyenne := (1 - (getMntNetHT(rec) / getMntBrutHT(rec))) * 100;
    end;

    procedure getMntBrutHT(InvHeader: Record "Sales Invoice Header"): Decimal
    var
        LigneInvoice: Record "Sales Invoice Line";
        mntBrutHt: Decimal;
    begin
        mntBrutHt := 0;
        LigneInvoice.Reset();
        LigneInvoice.SetRange("Document No.", InvHeader."No.");
        if LigneInvoice.FindSet() then begin
            repeat
                mntBrutHt := mntBrutHt + LigneInvoice.Quantity * LigneInvoice."Unit Price";
            until LigneInvoice.Next() = 0;
        end;
        exit(mntBrutHt);
    end;

    procedure getMntNetHT(InvHeader: Record "Sales Invoice Header"): Decimal
    var
        LigneInvoice: Record "Sales Invoice Line";
        mntNetHt: Decimal;
    begin
        mntNetHt := 0;
        LigneInvoice.Reset();
        LigneInvoice.SetRange("Document No.", InvHeader."No.");
        if LigneInvoice.FindSet() then begin
            repeat
                mntNetHt := mntNetHt + LigneInvoice.Quantity * (LigneInvoice."Unit Price" * (1 - (LigneInvoice."Line Discount %" / 100)));
            until LigneInvoice.Next() = 0;
        end;
        exit(mntNetHt);
    end;

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
        recuCaisseDoc: Record "Recu Caisse Document";
    begin
        recuCaisseDoc.SetRange("Document No", rec."No.");
        PAGE.Run(PAGE::"Recu Document List", recuCaisseDoc);
    end;
}