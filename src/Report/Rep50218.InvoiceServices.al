report 50218 "Invoice Services"
{

    RDLCLayout = './src/report/RDLC/InvoiceServices.rdl';

    Caption = 'Facture Service';
    PreviewMode = PrintLayout;
    UsageCategory = ReportsAndAnalysis;
    ApplicationArea = ALL;
    dataset
    {
        dataitem("Sales Invoice Header"; 112)
        {
            DataItemTableView = where("Internal Bill-to Customer" = const(false));
            column(NoSalesInvoiceHeader; "Sales Invoice Header"."No.")
            {
            }
            column(PostingDateSalesInvoiceHeader; "Sales Invoice Header"."Posting Date")
            {
            }
            column(OrderNoSalesInvoiceHeader; "Sales Invoice Header"."Service Order No.")
            {
            }
            column(OrderDateSalesInvoiceHeader; "Sales Invoice Header"."Order Date")
            {
            }
            column(VenderNameRecGVendor; RecGSalesPerson.Name)
            {
            }
            column(AmountSalesInvoiceHeader; "Sales Invoice Header".Amount)
            {
            }
            column(AmountTTCSalesInvoiceHeader; "Sales Invoice Header"."Amount Including VAT")
            {
            }
            column(StampAmount; "Sales Invoice Header"."stStamp Amount")
            {

                //  OptionCaption ='Stamp Tax';
            }
            column(NoRecGCustomer; RecGCustomer."No.")
            {
            }
            column(NameRecGCustomer; RecGCustomer.Name)
            {
            }
            column(AdrRecGCustomer; RecGCustomer.Address)
            {
            }
            column(MFRecGCustomer; RecGCustomer."VAT Registration No.")
            {
            }
            column(PhonRecGCustomer; RecGCustomer."Phone No.")
            {
            }
            column(MakeRecGOr; RecGOr."Make Code")
            {
            }
            column(ModelRecGOr; RecGOr."Model Code")
            {
            }
            column(DateArrivalRecGOr; RecGOr."Arrival Date")
            {
            }
            column(KilometrageRecGOr; RecGOr."Variable Field Run 1")
            {

            }
            column(VINRecGOr; RecGOr.VIN)
            {
            }
            column(ImmatriculationRecGOr; RecGOr."Vehicle Registration No.")
            {
            }
            column(MntDossier; MntDossier)
            {
            }
            column(CompanyName; CompanyNames)
            {
            }
            column(PaymentTermsSalesInvoiceHeader; "Sales Invoice Header"."Payment Terms Code")
            {
            }
            column(PaymentTermsDescription; lPaymentTerms.Description)
            {
            }
            column(MontantTText; MontantTText)
            {
            }

            column(Picture; RecGCompany.Picture)
            {
            }
            column(Entete; RecCompany."Invoice Header Picture")
            {
            }
            column(Pied; RecCompany."Invoice Footer Picture")
            {
            }

            column(afficherPiedsPage; afficherPiedsPage)
            {

            }
            column(ShowLabor; ShowLabor)
            {
            }
            column(TotPiece; TotPiece)
            {
            }
            column(TotMO; TotMO)
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
            column(DueDate; "Sales Invoice Header"."Due Date")
            {
            }
            column(PaymentMethod; PaymentMethod.Description)
            {
            }
            column(CompanyInfo_Name; RecGCompany.Name)
            {
            }
            column(CompanyInfo_Adress; RecGCompany.Address)
            {
            }
            column(CompanyInfo_PostCode; RecGCompany."Post Code")
            {
            }
            column(CompanyInfo_City; RecGCompany.City)
            {
            }
            column(CompanyInfo_Phone; RecGCompany."Phone No.")
            {
            }
            column(CompanyInfo_Fax; RecGCompany."Fax No.")
            {
            }
            column(CompanyInfo_LegalForm; RecGCompany."Legal Form")
            {
            }
            column(CompanyInfo_Capital; RecGCompany."Stock Capital")
            {
            }
            column(CompanyInfo_VatRegistration; RecGCompany."VAT Registration No.")
            {
            }
            column(CompanyInfo_Email; RecGCompany."E-Mail")
            {
            }
            column(CompanyInfo_TradeRegister; RecGCompany."Trade Register")
            {
            }
            column(CompBankName; RecGCompany."Bank Name")
            {
            }
            column(CompBankAccount; RecGCompany."Bank Account No.")
            {
            }
            column(CompIBAN; RecGCompany.IBAN)
            {
            }
            column(CompSWIFT; RecGCompany."SWIFT Code")
            {
            }
            column(Text1Footer; Text1Footer)
            {
            }

            column(Bill_to_Customer_No; "Bill-to Customer No.")
            {

            }
            column(Sell_to_Name; "Sell-to Customer Name")
            {

            }
            column(External_Document_No_; "External Document No.")
            {

            }
            dataitem("Sales Invoice Line"; 113)
            {
                DataItemLink = "Document No." = FIELD("No.");
                DataItemTableView = where("Small Parts" = const(false));
                //The property 'DataItemTableView' shouldn't have an empty value.
                //DataItemTableView = '';
                column(VAT_PourcentSalesInvoiceLIne; "Sales Invoice Line"."VAT %")
                {
                }
                column(Vat_BaseAmountSalesInvoiceLIne; "Sales Invoice Line"."VAT Base Amount")
                {
                    AutoFormatExpression = "Sales Invoice Line".GetCurrencyCode;
                }
                column(AmountTVASalesInvoiceLIne; AmountGTVA)
                {
                }
                column(SalesInvoiceLineRef; Ref)
                {
                }

                column(islabor; islabor)
                {

                }
                column(SalesInvoiceLineDescript; Gdescription)
                {
                }
                column(SalesInvoiceLineUOM; "Sales Invoice Line"."Unit of Measure")
                {
                }
                column(SalesInvoiceLineQte; "Sales Invoice Line".Quantity)
                {
                }
                column(SalesInvoiceLineUnitPrice; "Sales Invoice Line"."Unit Price")
                {
                    AutoFormatExpression = "Sales Invoice Line".GetCurrencyCode;
                }
                column(SalesInvoiceLineDiscount; "Sales Invoice Line"."Line Discount %")
                {
                }
                column(SalesInvoiceLineAmount; "Sales Invoice Line".Amount)
                {
                    AutoFormatExpression = "Sales Invoice Line".GetCurrencyCode;
                }
                column(SalesInvoiceLineVAT; "Sales Invoice Line"."VAT %")
                {
                }
                column(Discount; Discount)
                {
                }
                column(DLT_Small_Parts; "Small Parts")
                {

                }

                trigger OnAfterGetRecord()
                begin
                    increment := increment + 1;

                    AmountGTVA := ("VAT %" * "VAT Base Amount") / 100;
                    Discount := "Line Discount Amount";

                    //compte gen
                    IF Type = Type::"G/L Account" THEN begin
                        Ref := "Order Line Type No.";
                        islabor := true;
                    end
                    ELSE begin
                        Ref := "No.";
                        islabor := false;

                    end;
                    //HATEM

                    Gdescription := '';
                    IF "Sales Invoice Line".Type <> "Sales Invoice Line".Type::Item THEN
                        Gdescription := UPPERCASE("Sales Invoice Line".Description)
                    ELSE
                        Gdescription := UPPERCASE("Sales Invoice Line".Description);
                end;
            }
            /* dataitem(DataItem18; 50046)
             {
                 DataItemLink = Posted invoice No.=FIELD(No.);
                 column(Description_Multiplepaymentmethod; "Multiple payment method".Description)
                 {
                 }
                 column(Amount_Multiplepaymentmethod; "Multiple payment method".Amount)
                 {
                 }
                 column(Dateofpayment_Multiplepaymentmethod; "Multiple payment method"."Date of payment")
                 {
                 }
             }*/
            dataitem(DataItem1000000041; 2000000026)
            {
                DataItemTableView = SORTING(Number)
                                    ORDER(Ascending);
                column(Number; Number + increment)
                {
                }

                trigger OnPreDataItem()
                begin
                    SETRANGE(Number, 1, 22 - (increment MOD 22));
                end;
            }

            trigger OnAfterGetRecord()
            var
                LGenBusinessPostingGroup: Record 250;
            begin
                increment := 0;
                CLEAR(RecGOr);
                CLEAR(RecGCompany);
                CLEAR(RecGPostServOrderLine);

                IF RecGCompany.GET THEN BEGIN
                    Text1Footer := RecGCompany.Name + '& CIE/S.A au capital de ' + RecGCompany."Stock Capital" +
       'Siège Social :' + RecGCompany.Address +
     '- ' + RecGCompany."Post Code" + ' ' + RecGCompany."Address 2" +
      ' Code TVA: ' + RecGCompany."Registration No." + '- RC: ' + RecGCompany."Trade Register" + ' -CD: ' + RecGCompany."APE Code" + ': '
      + RecGCompany."Bank Name" + ':' + RecGCompany."Bank Account No.";
                    ;
                END;

                IF "Responsibility Center" = '' THEN BEGIN
                    CompanyNames := RecGCompany.Name;
                END
                ELSE BEGIN
                    CLEAR(RecGResponsibilityCenter);
                    RecGResponsibilityCenter.GET("Responsibility Center");
                    CompanyNames := RecGResponsibilityCenter.Name;
                END;

                IF RecGSalesPerson.GET("Salesperson Code") THEN;
                IF RecGCustomer.GET("Bill-to Customer No.") THEN;

                //>DELTA BCH 18/10/2020

                IF RecGOr.GET("Sales Invoice Header"."Service Order No.") THEN;


                lSalesInvoiceLine.SETRANGE("Document No.", "Sales Invoice Header"."No.");
                IF lSalesInvoiceLine.FINDSET THEN BEGIN
                    REPEAT

                        RecGPostServOrderLine.RESET;
                        RecGPostServOrderLine.SETRANGE("Document No.", lSalesInvoiceLine."Service Order No. EDMS");
                        RecGPostServOrderLine.SETRANGE("Line No.", lSalesInvoiceLine."Service Order Line No. EDMS");
                        IF RecGPostServOrderLine.FINDSET THEN BEGIN
                            CASE RecGPostServOrderLine.Type OF
                                RecGPostServOrderLine.Type::Item:
                                    TotPiece += RecGPostServOrderLine."Line Amount";
                                RecGPostServOrderLine.Type::Labor:
                                    TotMO += RecGPostServOrderLine."Line Amount";
                                RecGPostServOrderLine.Type::"External Service":
                                    TotMO += RecGPostServOrderLine."Line Amount";

                            END;
                        END;
                    UNTIL lSalesInvoiceLine.NEXT = 0
                END;
                //<DELTA BCH 18/10/2020

                //>>DELTA 01

                //<<DELTA 01

                Converter."Montant en texte"(MontantTText, "Amount Including VAT" + "STStamp Amount");
                IF lPaymentTerms.GET("Sales Invoice Header"."Payment Terms Code") THEN;
                IF PaymentMethod.GET("Sales Invoice Header"."Payment Method Code") THEN;

                CustomerPostingGroup.GET("Sales Invoice Header"."Customer Posting Group");
                IF "Sales Invoice Header"."STStamp Amount" <> 0 THEN
                    MontantTText := 'FACTURE ARRETEE A LA SOMME DE ' + MontantTText
                ELSE
                    MontantTText := 'FACTURE ARRETEE A LA SOMME DE: ' + MontantTText;
            end;
        }
    }

    requestpage
    {

        layout
        {
            area(Content)
            {
                field(ShowLabor; ShowLabor)
                {
                    ApplicationArea = all;
                    Caption = 'Afficher quantité main d''oeuvre';
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
        Clear(RecCompany);
        RecGCompany.Get();
        RecCompany.CalcFields("Invoice Footer Picture");
        RecCompany.CalcFields("Invoice Header Picture");

    end;



    var
        RecGSalesPerson: Record 13;
        RecGCustomer: Record 18;
        RecGOr: Record 25006149;
        RecGPostServOrderLine: Record 25006150;
        TotPiece: Decimal;
        TotMO: Decimal;
        TotTrExt: Decimal;
        MntDossier: Decimal;
        RecGCompany: Record 79;
        RecCompany: Record "Company Information";
        CompanyNames: Text;
        RecGResponsibilityCenter: Record 5714;
        AmountGTVA: Decimal;
        MontantTText: Text;
        Converter: Codeunit MontantTouteLettre;
        increment: Integer;
        Discount: Decimal;
        Ref: Text;
        Iteration: Integer;
        Gdescription: Code[100];
        lPaymentTerms: Record 3;
        lSalesInvoiceLine: Record 113;
        VATBaseCaptionLbl: Label 'Base TVA';
        VATAmtCaptionLbl: Label 'Montant TVA';
        VATAmountLineCaptionLbl: Label '% TVA';
        VATCaptionLbl: Label 'Taux TVA';
        TMPBaseCaptionLbl: Label 'Base TMP';
        TMPAmtCaptionLbl: Label 'Montant TMP';
        TMPAmountLineCaptionLbl: Label '% TMP';
        TMPCaptionLbl: Label 'TMP rate';
        TMP: Boolean;
        PaymentMethod: Record 289;
        CustomerPostingGroup: Record 92;
        Text1Footer: Text;
        afficherPiedsPage: Boolean;
        ShowLabor: Boolean;

        islabor: Boolean;
}

