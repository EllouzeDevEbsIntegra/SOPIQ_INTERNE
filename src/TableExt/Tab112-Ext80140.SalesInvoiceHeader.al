tableextension 80140 "Sales Invoice Header" extends "Sales Invoice Header"//112
{
    fields
    {
        // Add changes to table fields here
        field(80140; "Moy Jour Paiement"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'Moyen Jour Paiement';
            DecimalPlaces = 0 : 2;
        }

        field(80141; "DiscountAmount"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = sum("Sales Invoice Line"."Line Discount Amount" WHERE("Document No." = field("No.")));
            Caption = 'Type MO';
            Editable = false;
            FieldClass = FlowField;
        }

        field(80101; custNameImprime; Text[200])
        {
            Caption = 'Nom Client Imprimé';
        }

        field(80102; custAdresseImprime; Text[200])
        {
            Caption = 'Adresse Client Imprimé';
        }

        field(80103; custMFImprime; Text[200])
        {
            Caption = 'Matricule Fiscal Imprimé';
        }

        field(80104; custVINImprime; Text[200])
        {
            Caption = 'Vin Client Imprimé';
        }

        field(80411; "Montant reçu caisse"; Decimal)
        {
            Caption = 'Montant reçu caisse';

            FieldClass = FlowField;
            CalcFormula = sum("Recu Caisse Document"."Montant Reglement" WHERE("Document No" = field("No.")));
            Editable = false;
        }

        field(80413; solde; Boolean)
        {
            DataClassification = ToBeClassified;
        }
        field(80414; "Initiateur"; code[20])
        {
            FieldClass = FlowField;
            CalcFormula = lookup("Posted Serv. Order Header"."Initiator Code" WHERE("No." = field("Service Order No.")));
        }

        field(80416; "Linked Paiement Line"; Code[10])
        {
            Caption = 'Ligne Paiement Liée';
            CalcFormula = lookup("Recu Caisse Paiement"."No Recu" WHERE("Linked Invoice" = field("No.")));
            FieldClass = FlowField;
        }

    }

    var
        myInt: Integer;

    procedure MoyJourPaiement(Facture: Record "Sales Invoice Header"): Decimal
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

    trigger OnInsert()
    var
        SISalesCodeUnit: Codeunit SISalesCodeUnit;
    begin
        WorkDescription := CopyStr(GetWorkDescription, 1, 250);
        Message(WorkDescription);
        if rec."Document Profile" = "Document Profile"::Service then
            SISalesCodeUnit.CreateSalesInvoiceHeaderForFeedback(Rec, workDescription);
    end;


    var
        workDescription: Text[250];
}