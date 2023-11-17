report 50228 "Bord Remise Cheque Agence"
{
    DefaultLayout = RDLC;
    RDLCLayout = './src/report/RDLC/BordRemiseChequeAgence.rdl';
    UsageCategory = ReportsAndAnalysis;
    ApplicationArea = All;
    caption = 'Remise Chèques';
    dataset
    {
        dataitem("Payment Header"; "Payment Header")
        {
            DataItemTableView = SORTING("No.");
            RequestFilterFields = "No.";
            column(PaymentHeaderNo; "Payment Header"."No.")
            {
            }
            column(TitreCaption; CstG010)
            {
            }
            column(CompanyInfoName; CompanyInfo.Name)
            {
            }
            column(RSCaption; CstG011)
            {
            }
            column(NCompteCaption; CstG012)
            {
            }
            column(AnneeExercice; 'Exercice  ' + AnneeExercice)
            {
            }
            column(BanqueBankBranchNo; Banque."Bank Branch No.")
            {
            }
            column(BanqueAgencyCode; Banque."Agency Code")
            {
            }
            column(BanqueBankAccountNo; Banque."Bank Account No.")
            {
            }
            column(BanqueRIBKey; RIBKEY)
            {
            }
            column(NomBanqueCaption; CstG013)
            {
            }
            column(BankName; "Bank Name")
            {
            }
            column(DateVersementCaption; CstG014)
            {
            }
            column(PaymentHeaderPostingDate; "Payment Header"."Posting Date")
            {
            }
            column(NBRCaption; CstG015)
            {
            }
            column(NcheqCaption; CstG016)
            {
            }
            column(TireurCaption; CstG017)
            {
            }
            column(BanqueClientCaption; CstG018)
            {
            }
            column(VilleCaption; CstG019)
            {
            }
            column(MontantCaption; CstG020)
            {
            }
            // column(Presentation; Presentation) mmok
            // {
            // }
            column(NBCheqCaption; CstG021)
            {
            }
            column(SommeEnLettreCaption; CstG022)
            {
            }
            column(TotEnChiffreCaption; CstG023)
            {
            }
            column(TxtGMontantTTLettre; TxtGMontantTTLettre)
            {
            }
            column(DecGTotMontant; DecGTotMontant)
            {
                AutoFormatExpression = "Currency Code";
                AutoFormatType = 1;
            }
            column(SignatureAgenceCaption; CstG024)
            {
            }
            column(SignatureRemettantCaption; CstG025)
            {
            }
            column(DateGWorkDate; DateGWorkDate)
            {
            }
            column(Picture; CompanyInfo.Picture)
            {
            }
            column(RecGCompanyInfoCity; CompanyInfo.City)
            {
            }
            column(Phone; CompanyInfo."Phone No.")
            {

            }
            column(Fax; CompanyInfo."Fax No.")
            {

            }
            column(MatriculeFiscal; CompanyInfo."VAT Registration No.")
            {
            }
            column(TxtAdresse; TXTADRESSE)
            {

            }
            dataitem("Payment Line"; "Payment Line")
            {
                DataItemLink = "No." = FIELD("No.");
                //DataItemTableView = SORTING(Amount,"No.");//"No.", "Line No."
                DataItemTableView = SORTING("No.", "Line No.");//"No.", "Line No."
                column(PaymentLineLineNo; "Payment Line"."Line No.")
                {
                }
                column(i; i)
                {
                }
                column(Due_Date; "Due Date")
                {

                }
                column(ExternalDocumentNo; "External Document No.")
                {
                }
                column(PaymentLineDraweeReference; "Payment Line"."STDrawee Reference1")
                {
                }
                column(PaymentLineBankAccountName; "Payment Line"."Bank Account Name")
                {
                }
                column(PaymentLineBankAccountCode; "Payment Line"."Bank Account Code")
                {

                }
                column(PaymentLineBankCity; "Payment Line"."Bank City")
                {
                }
                column(ABSAmountLCY; "Amount (LCY)")
                {
                    AutoFormatExpression = "Currency Code";
                    AutoFormatType = 1;
                }
                column(Account_No; "Account No.")
                {

                }
                column(IntGCounter; IntGCounter)
                {
                }


                trigger OnAfterGetRecord()
                begin
                    //>>MIG2013 18022013///section
                    Compteur := Compteur + 1;
                    IF Compteur = 36 THEN BEGIN
                        IntGCounter += 1;
                        Compteur := 1
                    END;
                    CurrReport.NEWPAGE;
                    i := i + 1;
                    //<<MIG2013 18022013

                    //>>MIG2013 18022013
                    DecGTotMontant := DecGTotMontant + ABS("Payment Line"."Amount (LCY)");

                    TxtGMontantTTLettre := '';

                    currency.Reset();
                    currency.SetRange(Code, "Currency Code");
                    if currency.FindFirst() then begin
                        dev := currency."ISO Code";
                    end;
                    if (dev = '') or (dev = 'TND') then begin
                        CduGMontantTTlettre."Montant en texte"(TxtGMontantTTLettre, ROUND(DecGTotMontant, 0.001, '='));
                    end
                    else
                        CduGMontantTTlettre."Montant en texteDevise"(TxtGMontantTTLettre, ROUND(DecGTotMontant, 0.001, '='), dev);
                end;
            }

            trigger OnAfterGetRecord()
            begin
                //>>MIG2013 18022013
                Banque.SETRANGE(Banque.Name, "Payment Header"."Bank Name");
                IF Banque.FINDFIRST THEN;
                IF Banque."RIB Key" < 10 then
                    RIBKEY := '0' + format(Banque."RIB Key")
                else
                    RIBKEY := format(Banque."RIB Key");

                //<<MIG2013 18022013
            end;
        }
    }

    requestpage
    {
        SaveValues = true;
        layout
        {
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnInitReport()
    begin
        //>>MIG2013 18022013
        CompanyInfo.GET;
        DateGWorkDate := WORKDATE;
        //<<MIG2013 18022013
        CompanyInfo.CalcFields(Picture);
        TXTADRESSE := CompanyInfo.Address + ' ' + CompanyInfo.City + ' ' + CompanyInfo."Post Code";

    end;

    var
        Banque: Record 270;
        CompanyInfo: Record 79;
        i: Integer;
        Compteur: Integer;
        DecGTotMontant: Decimal;
        CduGMontantTTlettre: Codeunit 70004;
        TxtGMontantTTLettre: Text;

        CstG010: Label 'Bordereau de versement Chèque';
        CstG011: Label 'Nom ou R.S';
        CstG012: Label 'N° de compte';
        CstG013: Label 'Nom de la banque';
        CstG014: Label 'Date Versement';
        CstG015: Label 'Nbre';
        CstG016: Label 'N° Chèque';
        CstG017: Label 'Tiré';
        CstG018: Label 'Banque Client';
        CstG019: Label 'Ville';
        CstG020: Label 'Montant';
        CstG021: Label 'Nbre de chèque(s)';
        CstG022: Label 'Somme en Lettres';
        CstG023: Label 'Total en chiffres';
        CstG024: Label 'Signature Responsable';
        CstG025: Label 'Signature Responsable';
        IntGCounter: Integer;
        DateGWorkDate: Date;
        AnneeExercice: Text;
        currency: Record Currency;
        RIBKEY: Text[5];
        dev: Text[10];
        TXTADRESSE: text;
}

