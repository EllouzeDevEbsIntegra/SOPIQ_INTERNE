report 50221 "SI Devis  PDR"
{
    // DELTA 01 HT (17-05-2021) TMP
    DefaultLayout = RDLC;
    UsageCategory = ReportsAndAnalysis;
    ApplicationArea = All;
    RDLCLayout = './src/report/RDLC/DevisPDR.rdl';

    PreviewMode = PrintLayout;

    dataset
    {
        dataitem("Sales Header"; 36)
        {
            RequestFilterFields = "No.";

            column(No_SalesShipmentHeader; "Sales Header"."No.")
            {
            }
            column(BilltoCustomerNo_SalesShipmentHeader; "Sales Header"."Bill-to Customer No.")
            {
            }
            column(BilltoName_SalesShipmentHeader; "Sales Header"."Bill-to Name")
            {
            }
            column(PostingDate_SalesShipmentHeader; "Sales Header"."Document Date")
            {
            }
            column(BilltoAddress_SalesShipmentHeader; "Sales Header"."Bill-to Address")
            {
            }
            column(BilltoCity_SalesShipmentHeader; "Sales Header"."Bill-to City")
            {
            }
            column(ShiptoName_SalesShipmentHeader; "Sales Header"."Ship-to Name")
            {
            }
            column(CodeTva; CodeTVA)
            {
            }

            column(afficherPiedsPage; afficherPiedsPage)
            {

            }


            column(Picture; RecCompany.Picture)
            {
            }
            column(Header; RecCompany."Invoice Header Picture")
            {
            }
            column(Footer; RecCompany."Invoice Footer Picture")
            {
            }
            column(EMailCompany; RecCompany."E-Mail")
            {
            }
            column(ContactPersonCompany; RecCompany."Contact Person")
            {
            }
            column(CompanyInfo_TradeRegister; RecCompany."Trade Register")
            {
            }
            column(CompanyInfo_NonBank; RecCompany."Bank Name")
            {
            }
            column(CompanyInfo_CodeEtab; RecCompany."Bank Branch No.")
            {
            }
            column(CompanyInfo_NumComptBank; RecCompany."Bank Account No.")
            {
            }
            column(NameCompany; CompanyNames)
            {
            }
            column(Ad; CompanyAdresse)
            {
            }
            column(Tel; CompanyTel)
            {
            }
            column(Fax; CompanyFax)
            {
            }
            column(BilltoContact_SalesHeader; "Sales Header"."Bill-to Contact")
            {
            }
            column(telclient; RecCustomer."Phone No.")
            {
            }
            column(faxclient; RecCustomer."Telex No.")
            {
            }
            column(EMail; RecCustomer."E-Mail")
            {
            }
            column(PartnerType; RecCustomer."Partner Type")
            {
            }
            column(PostingDate_SalesHeader; "Sales Header"."Posting Date")
            {
            }
            column(OrderDate_SalesHeader; "Sales Header"."Order Date")
            {
            }
            column(SalespersonCode_SalesHeader; Salesperson.Name)
            {
            }
            column(VATRegistrationNo_SalesHeader; "Sales Header"."VAT Registration No.")
            {
            }
            column(Clause; Clause)
            {
            }
            column(AfficherClause; AfficherClause)
            {
            }

            column(PrintItemNo; PrintItemNo)
            {
            }
            column(TexteLettre; TexteLettre)
            {
            }
            column(PaymentTermsDescription; PaymentTerms.Description)
            {
            }
            column(PaymentTermsCode_SalesHeader; "Sales Header"."Payment Terms Code")
            {
            }
            column(InvoiceDiscountAmount_SalesHeader; "Sales Header"."Invoice Discount Amount")
            {
            }
            column(StampAmount; "Sales Header"."STStamp Amount")
            {
            }
            column(TMPBaseCaptionLbl; TMPBaseCaptionLbl)
            {
            }
            column(TMPAmtCaptionLbl; TMPAmtCaptionLbl)
            {
            }
            column(TMPAmountLineCaptionLbl; TMPAmountLineCaptionLbl)
            {
            }
            column(TMPCaptionLbl; TMPCaptionLbl)
            {
            }
            column(TMP; TMP)
            {
            }
            column(VATBaseCaptionLbl; VATBaseCaptionLbl)
            {
            }
            column(VATAmtCaptionLbl; VATAmtCaptionLbl)
            {
            }
            column(VATAmountLineCaptionLbl; VATAmountLineCaptionLbl)
            {
            }
            column(VATCaptionLbl; VATCaptionLbl)
            {
            }
            column(EstimateTMPTxtCaption; EstimateTMPTxtCaptionLbl)
            {
            }
            column(EstimateTxtCaption; EstimateTxtCaptionLbl)
            {
            }
            dataitem("Sales Line"; 37)
            {
                DataItemLink = "Document No." = FIELD("No.");
                RequestFilterFields = "Document No.";
                column(No_SalesShipmentLine; "Sales Line"."No.")
                {
                }
                column(Description_SalesShipmentLine; "Sales Line".Description)
                {
                }
                column(Quantity_SalesShipmentLine; "Sales Line".Quantity)
                {
                }
                column(UnitPrice_SalesShipmentLine; "Sales Line"."Unit Price")
                {
                    AutoFormatExpression = "Sales Header"."Currency Code";
                }
                column(VAT_SalesShipmentLine; "Sales Line"."VAT %")
                {
                }
                column(VATBaseAmount_SalesShipmentLine; "Sales Line"."VAT Base Amount")
                {
                    AutoFormatExpression = "Sales Header"."Currency Code";
                }
                column(VariantCode_SalesShipmentLine; "Sales Line"."Variant Code")
                {
                }
                column(increment; increment)
                {
                }
                column(LineAmount_SalesLine; "Sales Line"."Line Amount")
                {
                }
                column(Amount_SalesInvoiceLine; "Sales Line".Amount)
                {
                    AutoFormatExpression = "Sales Header"."Currency Code";
                }
                column(LineDiscountAmount_SalesInvoiceLine; "Sales Line".Amount + "Sales Line"."Line Discount Amount" + "Sales Line"."Inv. Discount Amount")
                {
                    AutoFormatExpression = "Sales Header"."Currency Code";
                }
                column(Montant_TVA; "Sales Line"."Amount Including VAT" - "Sales Line".Amount)
                {
                    AutoFormatExpression = "Sales Header"."Currency Code";
                }
                column(AmountIncludingVAT_SalesInvoiceLine; "Sales Line"."Amount Including VAT")
                {
                    AutoFormatExpression = "Sales Header"."Currency Code";
                }
                column(RemiseLigne; "Sales Line"."Line Discount Amount")
                {
                    AutoFormatExpression = "Sales Header"."Currency Code";
                }
                column(UnitofMeasure_SalesLine; "Sales Line"."Unit of Measure")
                {
                }
                column(LineDiscount_SalesLine; "Sales Line"."Line Discount %")
                {
                }
                column(IndexLigne; IndexLigne)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    IF Type = Type::Item THEN
                        increment := increment + 1;
                    IF increment < 10 THEN IndexLigne := '000' + FORMAT(increment);
                    IF (increment > 10) AND (increment < 1000) THEN IndexLigne := '00' + FORMAT(increment);
                    IF (increment > 1000) THEN IndexLigne := '0' + FORMAT(increment);
                    IF Type <> Type::Item THEN
                        CurrReport.SKIP;
                end;
            }
            dataitem(Integer; 2000000026)
            {
                DataItemTableView = SORTING(Number)
                                    ORDER(Ascending);
                column(Number; Number + increment)
                {
                }

                trigger OnPreDataItem()
                begin
                    SETRANGE(Number, 1, 19 - increment);
                end;
            }

            trigger OnAfterGetRecord()
            var
                LGenBusinessPostingGroup: Record 250;
            begin
                IF AfficherClause THEN Clause := STRSUBSTNO(Text001, Clause);
                increment := 0;
                CLEAR(CodeTVA);
                CodeTVA := '';
                //-------------------
                IF "Responsibility Center" = '' THEN BEGIN
                    CompanyNames := RecCompany.Name;
                    CompanyAdresse := RecCompany.Address;
                    CompanyTel := RecCompany."Phone No.";
                    CompanyFax := RecCompany."Fax No.";
                END
                ELSE BEGIN
                    CLEAR(RecResponsibilityCenter);
                    RecResponsibilityCenter.GET("Responsibility Center");
                    CompanyNames := RecResponsibilityCenter.Name;
                    CompanyAdresse := RecResponsibilityCenter.Address;
                    CompanyTel := RecResponsibilityCenter."Phone No.";
                    CompanyFax := RecResponsibilityCenter."Fax No.";


                END;
                // >> HJ DELTA
                CompanyNames := RecCompany.Name;
                CompanyAdresse := RecCompany.Address;
                CompanyTel := RecCompany."Phone No.";
                CompanyFax := RecCompany."Fax No.";
                // >> HJ DELTA
                CLEAR(RecCustomer);
                IF RecCustomer.GET("Bill-to Customer No.") THEN;
                CLEAR(GeneralLedgerSetup);
                GeneralLedgerSetup.GET;

                //-------------------

                IF "VAT Registration No." <> '' THEN
                    CodeTVA := "VAT Registration No."
                ELSE BEGIN
                    IF RecGClient.GET("Bill-to Customer No.") THEN
                        CodeTVA := RecGClient."VAT Registration No."
                    ELSE
                        CodeTVA := '';
                END;



                MontantRemiseGlobal := 0;
                // Montant en toute lettre
                MontantGloblal := 0;
                MTBaseTVA := 0;
                MontantLigneTVAGlobal := 0;
                CLEAR(SalesLine);
                SalesLine.SETRANGE("Document No.", "No.");
                //SalesLine.SETRANGE(Type,SalesLine.Type::Item);
                IF SalesLine.FINDSET THEN
                    REPEAT
                        IF SalesLine.Type = SalesLine.Type::Item THEN BEGIN

                            MontantLigne := SalesLine.Quantity * SalesLine."Unit Price";
                            // MontantRemiseLigne := ROUND(MontantLigne * SalesLine."Line Discount %"/100,0.001,'=') ;
                            MontantRemiseLigne := MontantLigne * SalesLine."Line Discount %" / 100;
                            MontantLigneGlobal += MontantLigne;
                            MontantLigneTVA += ROUND((MontantLigne - MontantRemiseLigne) * (1 + (SalesLine."VAT %" / 100)), 0.001, '=');

                            MTBaseTVA += SalesLine."VAT Base Amount" * (SalesLine."VAT %" / 100);

                            MontantRemiseGlobal += MontantRemiseLigne;

                            MontantLigne := 0;
                            MontantRemiseLigne := 0;
                        END;
                    UNTIL SalesLine.NEXT = 0;
                //TOTALNET := (MontantLigneGlobal-MontantRemiseGlobal) + MTBaseTVA + MTTIMBRE ; delta ht 170821

                CU_MntLettre."Montant en texte"(TexteLettre, (MontantLigneGlobal - MontantRemiseGlobal) + MTBaseTVA);
                MontantLigneTVAGlobal := ROUND(MontantLigneTVA, 0.001, '<');
                // END Montant
                IF Salesperson.GET("Sales Header"."Salesperson Code") THEN;



                //>>DELTA 01
                CustomerPostingGroup.GET("Sales Header"."Customer Posting Group");
                //<<DELTA 01


                //<< BHA 20/08/2021
                IF PaymentTerms.GET("Sales Header"."Payment Terms Code") THEN;
                //>>
            end;
        }
    }

    requestpage
    {

        SaveValues = true;
        layout
        {
            area(content)
            {
                field("Afficher Clause Prix"; AfficherClause)
                {
                }

                field(PrintItemNo; PrintItemNo)
                {
                    Caption = 'Afficher Code Article';
                }
                field(afficherPiedsPage; afficherPiedsPage)
                {
                    ApplicationArea = all;
                    Caption = 'Afficher entête et pied de page';
                }
            }
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
        CLEAR(RecCompany);
        RecCompany.GET;
        RecCompany.CALCFIELDS(Picture);
        RecCompany.CALCFIELDS(RecCompany."Invoice Header Picture");
        RecCompany.CALCFIELDS(RecCompany."Invoice Footer Picture");
        SalesReceivablesSetup.GET;
        afficherPiedsPage := true;
    end;

    var
        afficherPiedsPage: Boolean;
        increment: Integer;
        RecGClient: Record 18;
        CodeTVA: Code[20];
        CU_MntLettre: Codeunit 50009;
        TexteLettre: Text[1024];
        RecCompany: Record 79;
        CompanyNames: Text[50];
        CompanyAdresse: Text;
        CompanyTel: Text;
        CompanyFax: Text;
        RecResponsibilityCenter: Record 5714;
        RecCustomer: Record 18;
        GeneralLedgerSetup: Record 98;
        MTTIMBRE: Decimal;
        SalesLine: Record 37;
        MontantGloblal: Decimal;
        MontantLigne: Decimal;
        MontantRemiseLigne: Decimal;
        MontantLigneTVA: Decimal;
        Ttoalremise: Decimal;
        MontantRemiseGlobal: Decimal;
        MontantLigneTVAGlobal: Decimal;
        TOTALNET: Decimal;
        MTBaseTVA: Decimal;
        MontantLigneGlobal: Decimal;
        Salesperson: Record 13;
        IndexLigne: Text[4];
        SalesReceivablesSetup: Record 311;
        Text001: Label 'Prix donné à titre estimatif, susceptible de modification lors de l’arrivage';
        AfficherClause: Boolean;
        Clause: Text[100];
        TMPBaseCaptionLbl: Label 'TMP Base';
        TMPAmtCaptionLbl: Label 'TMP Amount';
        TMPAmountLineCaptionLbl: Label 'TMP %';
        TMPCaptionLbl: Label 'TMP rate';
        VATAmountLineCaptionLbl: Label 'VAT %';
        VATBaseCaptionLbl: Label 'VAT Base';
        VATAmtCaptionLbl: Label 'VAT Amount';
        VATCaptionLbl: Label 'VAT rate';
        TMP: Boolean;
        CustomerPostingGroup: Record 92;
        EstimateTMPTxtCaptionLbl: Label 'This estimate is at the sum of (including the ';
        EstimateTxtCaptionLbl: Label 'This estimate is at the sum of';
        PaymentTerms: Record 3;
        PrintItemNo: Boolean;
}

