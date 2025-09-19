report 50234 "Sales Invoice COPIM"
{
    DefaultLayout = RDLC;
    RDLCLayout = './src/report/RDLC/FactureCOPIM.rdl';
    Caption = 'Facture COPIM';
    UsageCategory = ReportsAndAnalysis;

    Permissions = TableData 25 = rimd,
                  TableData 112 = rm;
    PreviewMode = PrintLayout;

    dataset
    {
        dataitem("Sales Invoice Header"; "Sales Invoice Header")
        {
            RequestFilterFields = "No.";
            column(No_SalesShipmentHeader; "Sales Invoice Header"."No.")
            {
            }
            column(InvoiceDiscountAmount; "Invoice Discount Amount")
            {
            }
            column(BilltoCustomerNo_SalesShipmentHeader; "Sales Invoice Header"."Bill-to Customer No.")
            {
            }
            column(BilltoName_SalesShipmentHeader; "Sales Invoice Header"."Bill-to Name")
            {
            }
            column(PostingDate_SalesShipmentHeader; "Sales Invoice Header"."Posting Date")
            {
            }
            column(BilltoAddress_SalesShipmentHeader; "Sales Invoice Header"."Bill-to Address")
            {
            }
            column(BilltoCity_SalesShipmentHeader; "Sales Invoice Header"."Bill-to City")
            {
            }
            column(ShiptoName_SalesShipmentHeader; "Sales Invoice Header"."Ship-to Name")
            {
            }
            column(MontantTTCG; "Amount Including VAT")
            {

            }
            column(Amount; Amount)
            {

            }
            column(CodeTva; CodeTVA)
            {
            }
            column(Picture; RecCompany.Picture)
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
            column(BillToCustomerNo_SalesHeader; "Sales Invoice Header"."Bill-to Customer No.")
            {
            }
            column(BilltoContact_SalesHeader; "Sales Invoice Header"."Bill-to Contact")
            {
            }
            column(telclient; RecCustomer."Phone No.")
            {
            }
            column(faxclient; RecCustomer."Telex No.")
            {
            }
            column(PostingDate_SalesHeader; "Sales Invoice Header"."Posting Date")
            {
            }
            column(VATRegistrationNoCustomerBill; RecCustomer."VAT Registration No.")
            {
            }
            column(MontantTimbre; MTTIMBRE)
            {
            }
            column(SalespersonCode_SalesHeader; Salesperson.Name)
            {
            }
            column(VATRegistrationNo_SalesHeader; "Sales Invoice Header"."VAT Registration No.")
            {
            }
            column(TexteLettre; TexteLettre)
            {
            }
            column(PaymentTermsCode_SalesHeader; "Sales Invoice Header"."Payment Terms Code")
            {
            }
            column(OrderNo_SalesInvHeader; "Sales Invoice Header"."Order No.")
            {
            }
            column(immatriculation; "Sales Invoice Header"."Vehicle Registration No.")
            {
            }
            column(PaymentMethodCode_SalesInvoiceHeader; "Sales Invoice Header"."Payment Method Code")
            {
            }
            column(VIN; VehicleRec.VIN)
            {
            }
            column(OrderDate_SalesInvHeader; "Sales Invoice Header"."Order Date")
            {
            }
            column(Invoice_Discount_Amount; "Invoice Discount Amount")
            {
            }
            // column(InvoiceIsPrinted; "Sales Invoice Header".InvoiceIsPrinted)
            // {
            // }
            // column(DuplicataPicture; RecCompany."Duplicata Picture")
            // {
            // }

            // COPIM
            column(PrintNoBL; PrintNoBL)
            {

            }
            column(showReference; showReference)
            {

            }
            column(showDiscount; showDiscount)
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
            //--------------------------

            column(VehicleSerialNo; "Sales Invoice Header"."Vehicle Serial No.")
            {
            }
            dataitem("Sales Inv Line"; "Sales Invoice Line")
            {
                DataItemLink = "Document No." = FIELD("No.");
                // RequestFilterFields = "Document No.";
                DataItemTableView = sorting("Document No.", "Line No.");//where(quantity = filter(<> ''));
                column(No_SalesShipmentLine; "Sales Inv Line"."No.")
                {
                }
                column(Description_SalesShipmentLine; "Sales Inv Line".Description)
                {
                }
                column(Quantity_SalesShipmentLine; "Sales Inv Line".Quantity)
                {
                }
                column(UnitPrice_SalesShipmentLine; "Sales Inv Line"."Unit Price")
                {
                }
                column(VAT_SalesShipmentLine; "Sales Inv Line"."VAT %")
                {
                }
                column(VATBaseAmount_SalesShipmentLine; "Sales Inv Line"."VAT Base Amount")
                {
                }
                column(VariantCode_SalesShipmentLine; "Sales Inv Line"."Variant Code")
                {
                }
                column(increment; increment)
                {
                }
                column(LineAmount_SalesInvoiceLine; "Sales Inv Line"."Line Amount")
                {
                }
                column(Amount_SalesInvoiceLine; "Sales Inv Line".Amount)
                {
                }
                column(LineDiscountAmount_SalesInvoiceLine; "Sales Inv Line".Amount + "Sales Inv Line"."Line Discount Amount" + "Sales Inv Line"."Inv. Discount Amount")
                {
                }
                column(Montant_TVA; "Sales Inv Line"."Amount Including VAT" - "Sales Inv Line".Amount)
                {
                }
                column(AmountIncludingVAT_SalesInvoiceLine; "Sales Inv Line"."Amount Including VAT")
                {
                }
                column(RemiseLigne; "Sales Inv Line"."Line Discount Amount")
                {
                }

                column(UnitofMeasure_SalesLine; "Sales Inv Line"."Unit of Measure")
                {
                }
                column(LineDiscount_SalesLine; "Sales Inv Line"."Line Discount %")
                {
                }
                column(Nombreligne; Nombreligne)
                {

                }
                column(TotalLigne; TotalLigne)
                {

                }
                column(pagination; pagination)
                {

                }

                trigger OnAfterGetRecord()
                begin
                    if Description = '' then CurrReport.Skip();
                    //IF Type = Type::Item THEN
                    increment := increment + 1;
                    //>>Delta Achour 11/08/2021
                    Nombreligne := Nombreligne + 1;

                    TotalLigne := TotalLigne + 1;
                    IF Nombreligne > 26 THEN
                        Nombreligne := 1;

                    PageLigne := 26;
                    CASE TotalLigne OF
                        1 .. PageLigne:
                            pagination := 1;
                        PageLigne + 1 .. (PageLigne) * 2:
                            pagination := 2;
                        (PageLigne * 2) + 1 .. (PageLigne * 3):
                            pagination := 3;
                        (PageLigne * 3) + 1 .. (PageLigne * 4):
                            pagination := 4;
                        (PageLigne * 4) + 1 .. (PageLigne * 5):
                            pagination := 5;
                        (PageLigne * 5) + 1 .. (PageLigne * 6):
                            pagination := 6;
                        (PageLigne * 6) + 1 .. (PageLigne * 7):
                            pagination := 7;
                        (PageLigne * 7) + 1 .. (PageLigne * 8):
                            pagination := 8;
                        (PageLigne * 8) + 1 .. (PageLigne * 9):
                            pagination := 9;
                        (PageLigne * 9) + 1 .. (PageLigne * 10):
                            pagination := 10;
                        (PageLigne * 10) + 1 .. (PageLigne * 11):
                            pagination := 11;
                        (PageLigne * 11) + 1 .. (PageLigne * 12):
                            pagination := 12;
                        (PageLigne * 12) + 1 .. (PageLigne * 13):
                            pagination := 13;
                        (PageLigne * 13) + 1 .. (PageLigne * 14):
                            pagination := 14;
                        (PageLigne * 14) + 1 .. (PageLigne * 15):
                            pagination := 15;
                    END;
                    //if pagination = 1 then CurrReport.Skip();
                    //  message('%1 %2 %3 %4 %5', Nombreligne, TotalLigne, PageLigne, pagination, increment);
                    // <<Delta Achour 11/08/2021
                    // IF Type <> Type::Item THEN
                    //   CurrReport.SKIP;
                    //<< MMOK
                    // VatEntry.RESET;
                    // VatEntry.setrange("Document No.","Document No.");

                    VATAmountLine.INIT;
                    VATAmountLine."VAT Identifier" := "Sales Inv Line"."VAT Identifier";
                    VATAmountLine."VAT Calculation Type" := "Sales Inv Line"."VAT Calculation Type";
                    VATAmountLine."Tax Group Code" := "Sales Inv Line"."Tax Group Code";
                    VATAmountLine."VAT %" := "Sales Inv Line"."VAT %";
                    VATAmountLine."VAT Base" := Amount;
                    VATAmountLine."Amount Including VAT" := "Amount Including VAT";
                    VATAmountLine."Line Amount" := "Sales Inv Line"."Line Amount";
                    IF "Sales Inv Line"."Allow Invoice Disc." THEN
                        VATAmountLine."Inv. Disc. Base Amount" := "Sales Inv Line"."Line Amount";
                    VATAmountLine."Invoice Discount Amount" := "Sales Inv Line"."Inv. Discount Amount";
                    VATAmountLine.InsertLine;

                end;
                //>>
                //end;
            }
            dataitem(VATCounter; Integer)
            {
                DataItemTableView = SORTING(Number)
                                    ORDER(descending);

                Column(VATAmtLineVATIdentifier; VATAmountLine."VAT Identifier")
                {

                }
                Column(VATAmtLineLineAmt; VATAmountLine."Line Amount")
                {

                }
                Column(VATAmtLineVATBase; VATAmountLine."VAT Base")
                {

                }
                Column(VATAmtLineVATAmt; VATAmountLine."VAT Amount")
                {

                }
                Column(VATPour; VATAmountLine."VAT %")
                {

                }
                trigger OnPreDataItem()
                begin
                    //<<MMOK

                    IF VATAmountLine.GetTotalVATAmount = 0 THEN
                        CurrReport.BREAK;
                    SETRANGE(Number, 1, VATAmountLine.COUNT);
                    CurrReport.CREATETOTALS(
                      VATAmountLine."Line Amount", VATAmountLine."Inv. Disc. Base Amount",
                      VATAmountLine."Invoice Discount Amount", VATAmountLine."VAT Base", VATAmountLine."VAT Amount");
                    //>>MMOK
                end;

                trigger OnAfterGetRecord()
                begin
                    VATAmountLine.GetLine(Number);
                end;
            }
            dataitem(DataItem1000000037; Integer)
            {
                DataItemTableView = SORTING(Number)
                                    ORDER(Ascending);
                column(Number; Number + increment)
                {
                }


                trigger OnPreDataItem()
                begin
                    SETRANGE(Number, 1, 26 - (increment MOD 26));
                end;

            }
            dataitem(RecVatEntry; "VAT Entry")
            {
                DataItemLink = "Document No." = FIELD("No.");
                column(VatDeclared; VatBustPostGrp."VAT %")
                {

                }
                column(vatBus; RecVatEntry."VAT Bus. Posting Group")
                {

                }
                column(vatProd; RecVatEntry."VAT Prod. Posting Group")
                {

                }
                column(BaseAmount; -RecVatEntry.Base)
                {

                }
                column(MontantCalc; -RecVatEntry.Amount)
                {

                }
                trigger OnAfterGetRecord()
                var
                    myInt: Integer;
                begin
                    if VatBustPostGrp.get(RecVatEntry."VAT Bus. Posting Group", RecVatEntry."VAT Prod. Posting Group") then;
                    // Message('%1 %2 %3', VatBustPostGrp."VAT %", -RecVatEntry.Base, -RecVatEntry.Amount);
                end;
            }
            trigger OnAfterGetRecord()
            begin
                //<<MMOK 14/12/2020
                IF VehicleRec.GET("Sales Invoice Header"."Vehicle Serial No.") THEN;
                //>>MMOK 14/12/2020

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
                CLEAR(RecCustomer);
                RecCustomer.GET("Bill-to Customer No.");
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
                //----TIMBRE
                //CHK
                IF "Sales Invoice Header"."stApply Stamp Fiscal" = TRUE THEN
                    MTTIMBRE := "Sales Invoice Header"."STStamp Amount"
                ELSE
                    MTTIMBRE := 0;


                MontantRemiseGlobal := 0;
                // Montant en toute lettre
                MontantGloblal := 0;
                MTBaseTVA := 0;
                MontantLigneTVAGlobal := 0;
                CLEAR(SalesInvoiceLine);
                SalesInvoiceLine.SETRANGE("Document No.", "No.");
                //SalesInvoiceLine.SETRANGE(Type,SalesInvoiceLine.Type::Item);
                IF SalesInvoiceLine.FINDSET THEN
                    REPEAT
                        IF SalesInvoiceLine.Type = SalesInvoiceLine.Type::Item THEN BEGIN

                            MontantLigne := SalesInvoiceLine.Quantity * SalesInvoiceLine."Unit Price";
                            // MontantRemiseLigne := ROUND(MontantLigne * SalesInvoiceLine."Line Discount %"/100,0.001,'=') ;
                            MontantRemiseLigne := MontantLigne * SalesInvoiceLine."Line Discount %" / 100;
                            MontantLigneGlobal += MontantLigne;
                            MontantLigneTVA += ROUND((MontantLigne - MontantRemiseLigne) * (1 + (SalesInvoiceLine."VAT %" / 100)), 0.001, '=');

                            MTBaseTVA += SalesInvoiceLine."VAT Base Amount" * (SalesInvoiceLine."VAT %" / 100);

                            MontantRemiseGlobal += MontantRemiseLigne;

                            MontantLigne := 0;
                            MontantRemiseLigne := 0;
                        END;
                    UNTIL SalesInvoiceLine.NEXT = 0;
                TOTALNET := (MontantLigneGlobal - MontantRemiseGlobal) + MTBaseTVA + MTTIMBRE;
                //>>Delta Achour 11/08/2021
                CalcFields("Amount Including VAT");
                TOTALNET := "Amount Including VAT" + "STStamp Amount";
                //<<Delta Achour 11/08/2021
                CU_MntLettre."Montant en texte"(TexteLettre, TOTALNET);
                MontantLigneTVAGlobal := ROUND(MontantLigneTVA, 0.001, '<');

                // END Montant
                IF Salesperson.GET("Sales Invoice Header"."Salesperson Code") THEN;

            end;

            trigger OnPreDataItem()
            begin
                RecCompany.GET;
                RecCompany.CALCFIELDS(Picture);
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

                    field(PrintNoBL; PrintNoBL)
                    {
                        Caption = 'Imprimer N° BL';
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
                            recSalesInvHeader: Record "Sales Invoice Header";
                        begin
                            if editCustInfo = true then begin
                                recSalesInvHeader.reset();
                                recSalesInvHeader.SetRange("No.", "Sales Invoice Header".GetFilter("No."));
                                if recSalesInvHeader.FindFirst() then begin
                                    custNameImp := recSalesInvHeader.custNameImprime;
                                    custAdressImp := recSalesInvHeader.custAdresseImprime;
                                    custMFImp := recSalesInvHeader.custMFImprime;
                                    custVINImp := recSalesInvHeader.custVINImprime;
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
        // CLEAR(RecCompany);
        // RecCompany.GET;
        // RecCompany.CALCFIELDS(Picture);
    end;

    trigger OnPostReport()
    var
        recSalesInvHeader: Record "Sales Invoice Header";
    begin
        if (editCustInfo = true) then begin
            recSalesInvHeader.reset();
            recSalesInvHeader.SetRange("No.", "Sales Invoice Header"."No.");
            if recSalesInvHeader.FindFirst() then begin

                recSalesInvHeader.custNameImprime := custNameImp;
                recSalesInvHeader.custAdresseImprime := custAdressImp;
                recSalesInvHeader.custMFImprime := custMFImp;
                recSalesInvHeader.custVINImprime := custVINImp;
                recSalesInvHeader.Modify();

            end;
        end;
    end;

    var
        custNameImp, custAdressImp, custMFImp, custVINImp : text;
        editCustInfo: Boolean;
        showDiscount: Boolean;
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
        SalesInvoiceLine: Record 113;
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
        // SHOWLOGO: Boolean;
        PrintNoBL, showReference : Boolean;
        // [InDataSet]
        // VisiblePrintOriginal: Boolean;
        InvoiceIsPrinted: Boolean;
        VehicleRec: Record 25006005;
        VATAmountLine: Record 290 temporary; //MMOK
        VatEntry: Record 254; //Achour
        Nombreligne: Integer;
        TotalLigne: Integer;
        PageLigne: Integer;
        pagination: Integer;
        PourcTva: Decimal;
        VatBustPostGrp: Record "VAT Posting Setup";

}

