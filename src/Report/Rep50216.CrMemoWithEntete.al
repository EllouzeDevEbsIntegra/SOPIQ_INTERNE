report 50216 "CrMemoWithEntete"
{
    DefaultLayout = RDLC;
    UsageCategory = ReportsAndAnalysis;
    Caption = 'Avoir';
    ApplicationArea = All;
    RDLCLayout = './src/report/RDLC/CrMemoWithEntete.rdl';

    dataset
    {
        dataitem(DataItem1000000001; "Sales Cr.Memo Header")
        {
            DataItemTableView = SORTING("No.")
                                ORDER(Ascending);
            RequestFilterFields = "No.";
            column(No_SalesShipmentHeader; "No.")
            {
            }
            column(BilltoCustomerNo_SalesShipmentHeader; "Sell-to Customer No.")
            {
            }
            column(BilltoName_SalesShipmentHeader; "Sell-to Customer Name")
            {
            }
            column(PostingDate_SalesShipmentHeader; "Posting Date")
            {
            }
            column(BilltoAddress_SalesShipmentHeader; "Sell-to Address")
            {
            }
            column(OrderDate_SalesShipmentHeader; "Document Date")
            {
            }


            column(BilltoCity_SalesShipmentHeader; "Sell-to City")
            {
            }
            column(ShiptoName_SalesShipmentHeader; "Ship-to Name")
            {
            }
            column(OrderNo_SalesShipmentHeader; "External Document No.")
            {
            }
            column(CodeTva; CodeTVA)
            {
            }
            column(MontantGlobal; MontantGlobal)
            {
            }
            column(TextENLettre; TexteLettre)
            {
            }
            column(SalespersonCode_SalesHeader; Salesperson.Name)
            {
            }
            column(VATRegistrationNo_SalesHeader; "VAT Registration No.")
            {
            }
            column(DescriptionMethodeReglement; PaymentMethod.Description)
            {
            }
            column(VATRegistrationNo_SalesInvoiceHeader; "VAT Registration No.")
            {
            }
            column(ResponsibilityCenter_SalesCrMemoHeader; "Responsibility Center")
            {
            }
            column(TXTSUSP; TXTSUSP)
            {
            }
            column(PaymentTermsCode_SalesCrHeader; "Payment Terms Code")
            {
            }
            column(OrderDate_SalesCrHeader; "Document Date")
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
            column(telclient; RecGClient."Phone No.")
            {
            }
            column(faxclient; RecGClient."Telex No.")
            {
            }
            column(InvoiceDiscountAmount_SalesCrMemoHeader; "Invoice Discount Amount")
            {
            }
            column(MontantTimbre; "STStamp Amount")
            {
            }
            dataitem(DataItem1000000002; "Sales Cr.Memo Line")
            {
                DataItemLink = "Document No." = FIELD("No.");
                DataItemTableView = SORTING("Document No.", "Line No.")
                                    ORDER(Ascending);
                RequestFilterFields = "Document No.";
                column(No_SalesShipmentLine; "No.")
                {
                }
                column(Description_SalesShipmentLine; Description)
                {
                }
                column(Quantity_SalesShipmentLine; Quantity)
                {
                }
                column(UnitPrice; "Unit Price")
                {
                }
                column(VAT_SalesShipmentLine; "VAT %")
                {
                }
                column(VATBaseAmount_SalesShipmentLine; "VAT Base Amount")
                {
                }
                column(VariantCode_SalesShipmentLine; "Variant Code")
                {
                }
                column(UnitofMeasure_SalesCrMemoLine; "Unit of Measure")
                {
                }
                column(increment; increment)
                {
                }
                column(Amount_SalesInvoiceLine; Amount)
                {
                }
                column(LineDiscountAmount_SalesInvoiceLine; Amount + "Line Discount Amount" + "Inv. Discount Amount")
                {
                }
                column(LineDiscount_SalesCrMemoLine; "Line Discount %")
                {
                }
                column(Montant_TVA; "Amount Including VAT" - Amount)
                {
                }
                column(AmountIncludingVAT_SalesInvoiceLine; "Amount Including VAT")
                {
                }

                column(RemiseLigne; "Line Discount %")
                {
                }
                column(RemiseLignes; "Line Discount Amount")
                {
                }

                column(VATAmtLineVATBase; Amount)
                {
                    // AutoFormatExpression = "Sales Cr.Memo Line".GetCurrencyCode();
                    // AutoFormatType = 1;
                }
                column(VATAmtLineVATAmt; VATAmountLine."VAT Amount")
                {
                    // AutoFormatExpression = "Sales Cr.Memo Header"."Currency Code";
                    // AutoFormatType = 1;
                }
                column(VATAmtLineLineAmt; VATAmountLine."Line Amount")
                {
                    // AutoFormatExpression = "Sales Cr.Memo Header"."Currency Code";
                    // AutoFormatType = 1;
                }
                column(VATAmtLineInvDiscBaseAmt; VATAmountLine."Inv. Disc. Base Amount")
                {
                    // AutoFormatExpression = "Sales Cr.Memo Header"."Currency Code";
                    // AutoFormatType = 1;
                }
                column(VATAmtLineInvoiceDiscAmt; VATAmountLine."Invoice Discount Amount")
                {
                    // AutoFormatExpression = "Sales Cr.Memo Header"."Currency Code";
                    // AutoFormatType = 1;
                }
                column(VATAmtLineVAT; VATAmtLineVAT)
                {
                    // DecimalPlaces = 0:5;
                }
                column(VATAmtLineVATIdentifier; VATAmountLine."VAT Identifier")
                {
                }
                column(VATPercentCaption; VATPercentCaptionLbl)
                {
                }
                column(VATBaseCaption; VATBaseCaptionLbl)
                {
                }
                column(VATAmtCaption; VATAmtCaptionLbl)
                {
                }
                column(VATAmtSpecCaption; VATAmtSpecCaptionLbl)
                {
                }
                column(VATIdentCaption; VATIdentCaptionLbl)
                {
                }
                column(InvDiscBaseAmtCaption; InvDiscBaseAmtCaptionLbl)
                {
                }
                column(LineAmtCaption; LineAmtCaptionLbl)
                {
                }
                column(InvDiscAmtCaption1; InvDiscAmtCaption1Lbl)
                {
                }
                column(Type; Type)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    // IF Type = Type::"G/L Account" THEN CurrReport.SKIP;
                    // IF Type = Type::Item THEN CurrReport.SKIP;
                    IF (Type = Type::Item) THEN begin
                        VATAmtLineVAT := "VAT %";



                    end;
                    IF (Type <> Type::"G/L Account") THEN
                        increment := increment + 1;
                    // MESSAGE(FORMAT(increment));

                    /// code to include
                    /// MTBaseTVA += (MontantLigne - MontantRemiseLigne) * (SalesShipLine."VAT %" / 100);


                    VATAmountLine.INIT;
                    VATAmountLine."VAT %" := "VAT %";
                    VATAmountLine."VAT Identifier" := "VAT Identifier";
                    VATAmountLine."VAT Calculation Type" := "VAT Calculation Type";
                    VATAmountLine."Tax Group Code" := "Tax Group Code";

                    VATAmountLine."VAT Base" := Amount;
                    VATAmountLine."Amount Including VAT" := "Amount Including VAT";
                    VATAmountLine."Line Amount" := "Line Amount";
                    IF "Allow Invoice Disc." THEN
                        VATAmountLine."Inv. Disc. Base Amount" := "Line Amount";
                    VATAmountLine."Invoice Discount Amount" := "Inv. Discount Amount";
                    VATAmountLine."VAT Clause Code" := "VAT Clause Code";
                    VATAmountLine.InsertLine;

                    // end code to include
                end;

                trigger OnPostDataItem()
                begin
                    // message('%1', increment);
                end;
            }
            dataitem(DataItem1000000020; Integer)
            {
                DataItemTableView = SORTING(Number)
                                    ORDER(Ascending);
                column(Number; Number + increment)
                {
                }

                trigger OnPreDataItem()
                begin
                    SETRANGE(Number, 1, 36 - (increment MOD 36));
                end;
            }

            trigger OnAfterGetRecord()
            begin
                MontantGlobal := 0;
                MTTIMBRE := 0;
                increment := 0;
                CLEAR(CodeTVA);
                CodeTVA := '';
                IF "VAT Registration No." <> '' THEN
                    CodeTVA := "VAT Registration No."
                ELSE BEGIN
                    IF RecGClient.GET("Bill-to Customer No.") THEN
                        CodeTVA := RecGClient."VAT Registration No."
                    ELSE
                        CodeTVA := '';
                END;

                IF PaymentMethod.GET("Payment Terms Code") THEN;

                // TEST SUSPENSION TVA
                IF RecGClient.GET("Bill-to Customer No.") THEN
                    TXTSUSP := '';

                CLEAR(RecGVATPostingGroup);
                //IF (RecGVATPostingGroup.GET("Sales Cr.Memo Header"."VAT Bus. Posting Group")) AND (RecGVATPostingGroup.Exonéré)   THEN
                //BEGIN
                //     TXTSUSP:= STRSUBSTNO(TXTSUSPENION,RecGClient."No attestation",RecGClient."Date debut");
                //END;
                //--end;


                //----> MONTANT EN TOUTE LETTRE
                CLEAR(SalesCrMemoLine);
                SalesCrMemoLine.SETRANGE("No.");
                IF SalesCrMemoLine.FINDFIRST THEN
                    REPEAT
                        MontantGlobal := MontantGlobal + SalesCrMemoLine."Amount Including VAT";
                    UNTIL SalesCrMemoLine.NEXT = 0;
                // //DELTA BCH 26/10/2020
                // MontantGlobal := MontantGlobal + "Stamp Amount";
                // //DELTA BCH 26/10/2020
                // CU_MntLettre."Montant en texte"(TexteLettre, MontantGlobal);
                // //----> GET Mode de Reglement
                // IF Salesperson.GET("Salesperson Code") THEN;
            end;
        }
    }

    requestpage
    {
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
        CLEAR(RecCompany);
        RecCompany.GET;
        RecCompany.CALCFIELDS(RecCompany.Picture);
        RecCompany.CALCFIELDS(RecCompany."Invoice Header Picture");
        RecCompany.CALCFIELDS(RecCompany."Invoice Footer Picture");
        //<<DELTA MJ 01 Set default : session language
        //DisplayLanguage := language.GetLanguageCode(GLOBALLANGUAGE);
        //CurrReport.LANGUAGE := language.GetLanguageID(DisplayLanguage);
        //>>DELTA MJ 01
    end;

    var
        increment: Integer;
        VATAmtLineVAT: Decimal;
        RecGClient: Record Customer;
        CodeTVA: Code[20];
        DisplayLanguage: Code[10];
        CU_MntLettre: Codeunit MontantTouteLettre;
        TexteLettre: Text[1024];
        MontantGlobal: Decimal;
        PaymentMethod: Record "Payment Method";
        DescriptionMethodeReglement: Text[50];
        VATAmountLine: Record "VAT Amount Line" temporary;
        Text000: Label 'Salesperson';
        Text001: Label 'Total %1';
        Text002: Label 'Total %1 Incl. VAT';
        Text003: Label 'COPY';
        Text004: Label 'Sales - Invoice %1';
        PageCaptionCap: Label 'Page %1 of %2';
        Text006: Label 'Total %1 Excl. VAT';
        Text007: Label 'VAT Amount Specification in ';
        Text008: Label 'Local Currency';
        Text009: Label 'Exchange rate: %1/%2';
        Text010: Label 'Sales - Prepayment Invoice %1';
        Text10800: Label 'ShipmentNo';
        PhoneNoCaptionLbl: Label 'Phone No.';
        VATRegNoCaptionLbl: Label 'VAT Registration No.';
        GiroNoCaptionLbl: Label 'Giro No.';
        BankNameCaptionLbl: Label 'Bank';
        BankAccNoCaptionLbl: Label 'Account No.';
        DueDateCaptionLbl: Label 'Due Date';
        InvoiceNoCaptionLbl: Label 'Invoice No.';
        PostingDateCaptionLbl: Label 'Posting Date';
        HdrDimsCaptionLbl: Label 'Header Dimensions';
        UnitPriceCaptionLbl: Label 'Unit Price';
        DiscPercentCaptionLbl: Label 'Discount %';
        AmtCaptionLbl: Label 'Amount';
        VATClausesCap: Label 'VAT Clause';
        PostedShpDateCaptionLbl: Label 'Posted Shipment Date';
        InvDiscAmtCaptionLbl: Label 'Inv. Discount Amount';
        SubtotalCaptionLbl: Label 'Subtotal';
        PmtDiscVATCaptionLbl: Label 'Payment Discount on VAT';
        ShpCaptionLbl: Label 'Shipment';
        LineDimsCaptionLbl: Label 'Line Dimensions';
        VATPercentCaptionLbl: Label 'VAT %';
        VATBaseCaptionLbl: Label 'VAT Base';
        VATAmtCaptionLbl: Label 'VAT Amount';
        VATAmtSpecCaptionLbl: Label 'VAT Amount Specification';
        VATIdentCaptionLbl: Label 'VAT Identifier';
        InvDiscBaseAmtCaptionLbl: Label 'Invoice Discount Base Amount';
        LineAmtCaptionLbl: Label 'Line Amount';
        InvDiscAmtCaption1Lbl: Label 'Invoice Discount Amount';
        TotalCaptionLbl: Label 'Total';
        ShiptoAddrCaptionLbl: Label 'Ship-to Address';
        PmtTermsDescCaptionLbl: Label 'Payment Terms';
        ShpMethodDescCaptionLbl: Label 'Shipment Method';
        HomePageCaptionCap: Label 'Home Page';
        EMailCaptionLbl: Label 'E-Mail';
        DocDateCaptionLbl: Label 'Document Date';
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        RecGVATPostingGroup: Record "VAT Business Posting Group";
        TXTSUSP: Text;
        TXTSUSPENION: Label 'Vente en suspension de la TVA suivant décision N° %1 du %2 .';
        RecCompany: Record "Company Information";
        MTTIMBRE: Decimal;
        Salesperson: Record "Salesperson/Purchaser";
}