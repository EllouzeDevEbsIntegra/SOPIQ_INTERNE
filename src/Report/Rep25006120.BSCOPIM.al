report 25006120 "BS COPIM"
{
    // 24.12.2020 DELTA MJ 01
    //   Add english captions, amount format
    DefaultLayout = RDLC;
    UsageCategory = ReportsAndAnalysis;
    Caption = 'BS COPIM';
    ApplicationArea = All;
    RDLCLayout = './src/report/RDLC/BSCOPIM.rdl';
    PreviewMode = PrintLayout;
    Permissions = TableData 50009 = rm;


    dataset
    {
        dataitem(DataItem1000000001; "Entete archive BS")
        {
            RequestFilterFields = "No.";
            column(showReference; showReference)
            {

            }
            column(showDiscount; showDiscount)
            {

            }

            column(masquerRemiseColumn; masquerRemiseColumn)
            {

            }
            column(editCustInfo; editCustInfo)
            {

            }
            column(custNameImp; custNameImp)
            {

            }
            column(custAdressImp; custAdressImp)
            {

            }
            column(custMFImp; custMFImp)
            {

            }
            column(custVINImp; custVINImp)
            {

            }

            column(Caption_MF_CIN; Caption_MF_CIN)
            {
            }
            column(Caption_OrderNo; Caption_OrderNo)
            {
            }
            column(Caption_OdrerType; Caption_OdrerType)
            {
            }
            column(Caption_ShipmentDate; Caption_ShipmentDate)
            {
            }
            column(Caption_StampSign; Caption_StampSign)
            {
            }
            column(CaptionCust; "Caption-Cust")
            {
            }
            column(Order_No_; "Order No.")
            {
            }
            column(Shipping_Agent_Code; "Shipping Agent Code")
            {
            }
            column(Caption_Tilte; Caption_Tilte)
            {
            }
            column(Caption_UnitOfmeasure; Caption_UnitOfmeasure)
            {
            }
            column(Caption_Qty; Caption_Qty)
            {
            }
            column(Caption_Ref; Caption_Ref)
            {
            }
            column(Caption_Descrip; Caption_Descrip)
            {
            }
            column(Caption_OrderDate; Caption_OrderDate)
            {
            }
            column(Caption_Address; Caption_Address)
            {
            }
            column(Caption_Tel; Caption_Tel)
            {
            }
            column(Caption_CustSignature; Caption_CustSignature)
            {
            }
            column(Picture; RecCompany.Picture)
            {
            }
            column(NameCompany; CompanyNames)
            {
            }
            column(No_SalesShipmentHeader; "No.")
            {
            }
            column(BilltoCustomerNo_SalesShipmentHeader; "Bill-to Customer No.")
            {
            }
            column(BilltoName_SalesShipmentHeader; "Bill-to Name")
            {
            }
            column(Sell_to_Customer_Name; "Sell-to Customer Name")
            {
            }
            column(PostingDate_SalesShipmentHeader; "Posting Date")
            {
            }
            column(BilltoAddress_SalesShipmentHeader; "Bill-to Address")
            {
            }
            column(BilltoCity_SalesShipmentHeader; "Bill-to City")
            {
            }
            column(ShiptoName_SalesShipmentHeader; "Ship-to Name")
            {
            }
            column(OrderNo_SalesShipmentHeader; "Order No.")
            {
            }
            column(CodeTva; CodeTVA)
            {
            }
            column(ResponsibilityCenter_SalesShipmentHeader; "Responsibility Center")
            {
            }
            column(TXTSUSP; TXTSUSP)
            {
            }
            column(TransactionType_SalesShipmentHeader; "Transaction Type")
            {
            }
            column(OrderDate_SalesShipmentHeader; "Order Date")
            {
            }
            column(SalespersonCode_SalesShipmentHeader; Salesperson.Name)
            {
            }
            column(PhoneNo_Cust; RecGClient."Phone No.")
            {
            }
            column(ImgPied; RecCompany."Invoice Footer Picture")
            {
            }
            column(ImgEntete; RecCompany."Invoice Header Picture")
            {
            }

            column(BS; BS)
            {

            }
            column(Montant_TTC; "Montant TTC")
            {

            }
            dataitem(DataItem1000000002; "Ligne archive BS")
            {
                DataItemLink = "Document No." = FIELD("No.");
                DataItemTableView = SORTING("Document No.", "Line No.")
                                    ORDER(Ascending)
                                    WHERE(Quantity = FILTER(<> 0));
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
                column(UnitOfMesure_SalesShipmentLine; "Unit of Measure")
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
                column(increment; increment)
                {
                }
                column(UnitPrice; "Unit Price")
                {
                }
                column(MTHT; MTHT)
                {

                }
                column(NETHT; NETHT)
                {

                }
                column(Remise; Remise)
                {

                }

                column(MntTVAR; MntTVAR)
                {

                }
                column(MontantTVA; MontantTVA)
                {

                }

                column(MontTTC; MontTTC)
                {

                }
                column(MntTTCR; MntTTCR)
                {

                }
                column(TauxTVA; TauxTVA)
                {

                }
                column(TotHT; TotHT)
                {

                }
                column(TotRemise; TotRemise)
                {

                }

                column(LineDiscount_SalesShipmentLine; "% Discount")
                {
                }
                column(VATBaseAmount; "Item Charge Base Amount")
                {
                }
                column(CodeEmplacement; "Bin Code")
                {
                }

                trigger OnAfterGetRecord()
                begin
                    // IF Type = Type::Item THEN
                    increment := increment + 1;
                    MTHT := 0;
                    NETHT := 0;
                    Remise := 0;
                    MntTVAR := 0;
                    MntTTCR := 0;
                    MontTTC := 0;
                    TotRemise := 0;
                    CalcFields(BS);
                    //if BS then begin
                    // PrixVente := "Prix Vente 1";
                    //PrixVente := "Unit Price";

                    // MTHT := (PrixVente * Quantity) - (((PrixVente * Quantity) * ("Line Discount %" / 100)));
                    MTHT := ("Unit Price" * Quantity);
                    NETHT := ("Unit Price" * Quantity) - ((("Unit Price" * Quantity) * ("% Discount" / 100)));
                    Remise := (("Unit Price" * Quantity) * ("% Discount" / 100));
                    MntTVAR := NETHT * (("VAT %" / 100));
                    MontantTVA := MTHT * (("VAT %" / 100));
                    // MontTTC := TotHT + MontantTVA;
                    MontTTC := MTHT + MontantTVA;
                    MntTTCR := NETHT + MntTVAR;
                    TauxTVA := "VAT %";

                    //end else begin
                    //     PrixVente := "Unit Price";

                    //     MTHT := (PrixVente * Quantity) - (((PrixVente * Quantity) * ("% Discount" / 100)));
                    //     TotHT := TotHT + MTHT;
                    //     TotRemise := TotRemise + ((PrixVente * Quantity) * ("% Discount" / 100));
                    //     MontantTVA := MTHT * (("VAT %" / 100));
                    //     // MontTTC := TotHT + MontantTVA;
                    //     MontTTC := MTHT + MontantTVA;
                    //     TauxTVA := "VAT %";

                    // end;
                    IF Type <> Type::Item THEN
                        CurrReport.SKIP;

                end;

            }
            dataitem(DataItem1000000018; Integer)
            {
                DataItemTableView = SORTING(Number)
                                    ORDER(Ascending);
                column(Number; Number + increment)
                {
                }

                trigger OnPreDataItem()
                begin
                    SETRANGE(Number, 1, 13 - (increment mod 13));
                end;
            }

            trigger OnAfterGetRecord()
            begin
                increment := 0;
                CLEAR(CodeTVA);
                CodeTVA := '';

                //>> DELTA 01 MS 31/05/2016
                IF "Responsibility Center" = '' THEN
                    CompanyNames := RecCompany.Name
                ELSE BEGIN
                    CLEAR(RecResponsibilityCenter);
                    RecResponsibilityCenter.GET("Responsibility Center");
                    CompanyNames := RecResponsibilityCenter.Name;
                END;

                //<< DELTA 01 END

                IF "VAT Registration No." <> '' THEN
                    CodeTVA := "VAT Registration No."
                ELSE BEGIN
                    IF RecGClient.GET("Bill-to Customer No.") THEN
                        CodeTVA := RecGClient."VAT Registration No."
                    ELSE
                        CodeTVA := '';
                END;






                // TEST SUSPENSION TVA
                IF RecGClient.GET("Bill-to Customer No.") THEN
                    TXTSUSP := '';
                IF Salesperson.GET("Salesperson Code") THEN;


                //<<DELTA MJ 01 set vendor language if exists
                IF UseVendorLanguage THEN BEGIN
                    IF Customer.GET("Sell-to Customer No.") THEN
                        IF Customer."Language Code" <> '' THEN
                            CurrReport.LANGUAGE := language.GetLanguageID(Customer."Language Code")
                        ELSE
                            CurrReport.LANGUAGE := language.GetLanguageID("Language Code");
                END
                ELSE
                    CurrReport.LANGUAGE := language.GetLanguageID(DisplayLanguage);

                // IF CurrReport.LANGUAGE = 1033 THEN BEGIN
                //     footerCmt := SalesReceivablesSetup."Quote Footer Comment ENU";
                //     headerCmt := SalesReceivablesSetup."Quote Header Comment ENU";
                // END
                // ELSE BEGIN
                //     footerCmt := SalesReceivablesSetup."Quote Footer Comment";
                //     headerCmt := SalesReceivablesSetup."Quote Header Comment";
                // END;

                //-----translate payment terms
                IF recPaymentTermTranslation.GET("Payment Terms Code", language.GetLanguageId(Format(CurrReport.LANGUAGE))) THEN
                    PaymentTermstranslate := recPaymentTermTranslation.Description
                ELSE
                    PaymentTermstranslate := "Payment Terms Code";
                //>>DELTA MJ 01
            end;
        }
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                group(Option)
                {
                    Caption = 'Option';

                    field(ShowReference; ShowReference)
                    {
                        Caption = 'Afficher référence';
                    }

                    field(showDiscount; showDiscount)
                    {
                        Caption = 'Afficher Remise';
                    }
                    field(masquerRemiseColumn; masquerRemiseColumn)
                    {
                        Caption = 'Masquer Colonne Remise';
                    }
                }
                group(CustInfo)
                {
                    Caption = 'Information client';

                    field(editCustInfo; editCustInfo)
                    {
                        Caption = 'Modifier information client à imprimer';
                        trigger OnValidate()
                        var
                            recSalesShipHeader: Record "Entete archive BS";
                        begin
                            if editCustInfo = true then begin
                                recSalesShipHeader.reset();
                                recSalesShipHeader.SetRange("No.", DataItem1000000001.GetFilter("No."));
                                if recSalesShipHeader.FindFirst() then begin
                                    custNameImp := recSalesShipHeader.custNameImprime;
                                    custAdressImp := recSalesShipHeader.custAdresseImprime;
                                    custMFImp := recSalesShipHeader.custMFImprime;
                                    custVINImp := recSalesShipHeader.custVINImprime;
                                end;
                            end

                            else begin
                                custNameImp := '';
                                custAdressImp := '';
                                custMFImp := '';
                                custVINImp := '';
                            end;
                        end;

                    }

                    field(custNameImp; custNameImp)
                    {
                        Caption = 'Nom Client à imprimer';
                    }

                    field(custAdressImp; custAdressImp)
                    {
                        Caption = 'Adresse Client à imprimer';
                    }

                    field(custMFImp; custMFImp)
                    {
                        Caption = 'MF Client à imprimer';
                    }
                    field(custVINImp; custVINImp)
                    {
                        Caption = 'VIN Client à imprimer';
                    }
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
        RecCompany.CALCFIELDS(RecCompany.Picture);
        RecCompany.CALCFIELDS(RecCompany."Invoice Header Picture");
        RecCompany.CALCFIELDS(RecCompany."Invoice Footer Picture");
        //<<DELTA MJ 01 Set default : session language
        // DisplayLanguage := language.GetLanguageCode(GLOBALLANGUAGE);
        // CurrReport.LANGUAGE := language.GetLanguageID(DisplayLanguage);
        //>>DELTA MJ 01
        DisplayLanguage := 'FR';
    end;

    trigger OnPreReport()
    begin
        IF Valoriser THEN BEGIN
            REPORT.RUN(60019, TRUE, FALSE);
            CurrReport.QUIT;

        END;
    end;

    trigger OnPostReport()
    var
        recBsArchiveHeader: Record "Entete archive BS";
    begin
        if (editCustInfo = true) then begin
            recBsArchiveHeader.reset();
            recBsArchiveHeader.SetRange("No.", DataItem1000000001."No.");
            if recBsArchiveHeader.FindFirst() then begin
                recBsArchiveHeader.custNameImprime := custNameImp;
                recBsArchiveHeader.custAdresseImprime := custAdressImp;
                recBsArchiveHeader.custMFImprime := custMFImp;
                recBsArchiveHeader.custVINImprime := custVINImp;
                recBsArchiveHeader.Modify();
            end;
        end;
    end;

    var
        showReference: Boolean;
        masquerRemiseColumn: Boolean;
        showDiscount: Boolean;
        editCustInfo: Boolean;
        custNameImp, custAdressImp, custMFImp, custVINImp : text;
        PrixVente: Decimal;
        MTHT, NETHT, Remise, MntTVAR, MntTTCR : Decimal;
        TotHT: Decimal;
        TotRemise: Decimal;
        TauxTVA: Decimal;
        MontantTVA: Decimal;
        MontTTC: Decimal;
        increment: Integer;
        RecGClient: Record Customer;
        CodeTVA: Code[20];
        TexteLettre: Text[1024];
        MTTIMBRE: Decimal;
        GeneralLedgerSetup: Record "General Ledger Setup";
        RecGVATPostingGroup: Record "VAT Business Posting Group";
        TXTSUSP: Text;
        TXTSUSPENION: Label 'Vente en suspension de la TVA suivant décision N° %1 du %2 .';
        RecCompany: Record "Company Information";
        Salesperson: Record "Salesperson/Purchaser";
        "-- MS": Integer;
        CompanyNames: Text[50];
        RecResponsibilityCenter: Record "Responsibility Center";
        Valoriser: Boolean;
        PaymentTerms: Record "Payment Terms";
        DisplayLanguage: Code[10];
        language: Record Language;
        [InDataSet]
        UseVendorLanguage: Boolean;
        Customer: Record Customer;
        frOrEn: Boolean;
        footerCmt: Text;
        headerCmt: Text;
        PaymentTermstranslate: Text;
        recPaymentTermTranslation: Record "Payment Term Translation";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        Caption_Tilte: Label 'Spare Parts Shipment N°';
        Caption_UnitOfmeasure: Label 'Unit Of Measure';
        Caption_Qty: Label 'Qty ';
        Caption_Ref: Label 'Ref. ';
        Caption_Descrip: Label 'Description';
        Caption_OrderDate: Label 'Order Date ';
        Caption_Address: Label 'Address ';
        Caption_Tel: Label 'Phone No ';
        Caption_CustSignature: Label 'Customer Signature';
        Caption_MF_CIN: Label 'VAT Reg. No/NIC.';
        Caption_OrderNo: Label 'Order No';
        "Caption-Cust": Label 'Customer';
        Caption_OdrerType: Label 'Order Type';
        Caption_ShipmentDate: Label 'Shipment Date';
        Caption_StampSign: Label 'Stamp and Signature';
}

