report 50203 "Puchase Document"
{

    RDLCLayout = './src/report/RDLC/PuchaseDocumentPR.rdl';

    Caption = 'Demande de prix / Bon de commande';
    PreviewMode = PrintLayout;

    UsageCategory = ReportsAndAnalysis;
    ApplicationArea = ALL;
    dataset
    {
        dataitem("Purchase Header"; 38)
        {
            RequestFilterFields = "No.";
            column(showBin; showBin)
            {

            }
            column(Vendor_Shipment_No_; "Vendor Shipment No.")
            {

            }
            column(PurchaseHeader_No; "Purchase Header"."No.")
            {
            }
            column(PostingDate; "Purchase Header"."Posting Date")
            {
            }
            column(OrderClass; "Purchase Header"."Transaction Type")
            {
            }
            column(PurchaserCode; "Purchase Header"."Purchaser Code")
            {
            }
            column(VendorOrderNo_PurchaseHeader; "Purchase Header"."Vendor Order No.")
            {
            }
            column(PurchaserPhone; Purchaser."Phone No.")
            {
            }
            column(PayToNo; "Purchase Header"."Pay-to Vendor No.")
            {
            }
            column(PayToName; "Purchase Header"."Pay-to Name")
            {
            }
            column(PayToAdress; "Purchase Header"."Pay-to Address")
            {
            }
            column(VendorPhone; Vendor."Phone No.")
            {
            }
            column(VendorEMail; Vendor."E-Mail")
            {
            }

            column(ShipmentMethodCode; ShipmentMethod.Description)
            {
            }
            column(VATRegistrationNo; "Purchase Header"."VAT Registration No.")
            {
            }
            column(PaymentMethodCode; "Purchase Header"."Payment Method Code")
            {
            }
            column(CompanyInfo_Name; Companyinfo.Name)
            {
            }
            column(CompanyInfo_Adress; Companyinfo.Address)
            {
            }
            column(CompanyInfo_PostCode; Companyinfo."Post Code")
            {
            }
            column(CompanyInfo_City; Companyinfo.City)
            {
            }
            column(CompanyInfo_Phone; Companyinfo."Phone No.")
            {
            }
            column(CompanyInfo_Fax; Companyinfo."Fax No.")
            {
            }
            column(CompanyInfo_LegalForm; Companyinfo."Legal Form")
            {
            }
            column(CompanyInfo_Capital; Companyinfo."Stock Capital")
            {
            }
            column(LocationCode_PurchaseHeader; "Purchase Header"."Location Code")
            {
            }
            column(CompanyInfo_VatRegistration; Companyinfo."VAT Registration No.")
            {
            }
            column(CompanyInfo_RC; Companyinfo."Trade Register")
            {
            }
            column(CompanyInfo_Email; Companyinfo."E-Mail")
            {
            }
            column(CompanyinfoPicture; Companyinfo."Invoice Header Picture")
            {
            }
            column(CompanyinfoPicture2; Companyinfo."Invoice Footer Picture")
            {
            }
            column(Text1Footer; Text1Footer)
            {
            }

            column(shipTermDescription; shipTermDescription)
            {
            }
            column(payTermDescription; payTermDescription)
            {
            }
            column(StampAmount; "Purchase Header"."STStamp Fiscal Amount")
            {
                IncludeCaption = true;
            }
            column(PayementMethode; "Purchase Header"."Payment Method Code")
            {
            }
            column(VendorOrderNo; "Purchase Header"."Vendor Order No.")
            {
            }
            column(Caption01; Caption01)
            {
            }
            column(Caption02; Caption02)
            {
            }
            column(Caption03; Caption03)
            {
            }
            column(Caption04; Caption04)
            {
            }
            column(Caption05; Caption05)
            {
            }
            column(Caption06; Caption06)
            {
            }
            column(Caption07; Caption07)
            {
            }
            column(Caption08; Caption08)
            {
            }
            column(Caption09; Caption09)
            {
            }
            column(Caption10; Caption10)
            {
            }
            column(Caption11; Caption11)
            {
            }
            column(Caption12; Caption12)
            {
            }
            column(Caption13; Caption13)
            {
            }
            column(Caption14; Caption14)
            {
            }
            column(Caption140; Caption140)
            {
            }
            column(Caption15; Caption15)
            {
            }
            column(Caption16; Caption16)
            {
            }
            column(Caption17; Caption17)
            {
            }
            column(Caption18; Caption18)
            {
            }
            column(Caption19; Caption19)
            {
            }
            column(Caption20; Caption20)
            {
            }
            column(Caption21; Caption21)
            {
            }
            column(Caption22; Caption22)
            {
            }
            column(Caption23; Caption23)
            {
            }
            column(Caption24; Caption24)
            {
            }
            column(Caption25; Caption25)
            {
            }
            column(Caption26; Caption26)
            {
            }
            column(Caption27; Caption27)
            {
            }
            column(Caption28; Caption28)
            {
            }
            column(Caption29; Caption29)
            {
            }
            column(Caption30; Caption30)
            {
            }
            column(Caption31; Caption31)
            {
            }
            column(PaymentTermsCode_PurchaseHeader; "Purchase Header"."Payment Terms Code")
            {
            }
            column(QuoteNo_PurchaseHeader; NoDemande)
            {
            }
            column(ExpectedReceiptDate; "Purchase Header"."Expected Receipt Date")
            {
            }
            column(CurrencyCode_PurchaseHeader; "Purchase Header"."Currency Code")
            {
            }

            column(ShowExternalReference; ShowExternalReference)
            {
            }
            column(TotalAmountTxt; TotalAmountTxt)
            {
            }
            column(Document_Profile; "Document Profile")
            {

            }
            column(Document_Type; "Purchase Header"."Document Type")
            {

            }

            column(AfficherEntetePiedPage; AfficherEntetePiedPage)
            {

            }
            column(Location; Location.Name)
            {

            }
            column(typeDocument; typeDocument)
            {

            }
            dataitem("Purchase Line"; 39)
            {
                DataItemLink = "Document Type" = FIELD("Document Type"),
                               "Document No." = FIELD("No.");
                column(Document_No; "Purchase Line"."Document No.")
                {
                }
                column(DocumentType; "Purchase Line"."Document Type")
                {
                }
                column(No_s; Nunarticle)
                {
                }
                column(No_PurchaseLine; "Purchase Line"."No.")
                {
                }
                column(Type; "Purchase Line".Type)
                {
                }
                column(BuyfromVendorNoLine; "Purchase Line"."Buy-from Vendor No.")
                {
                }
                column(VendorItemNo_PurchaseLine; "Purchase Line"."Vendor Item No.")
                {
                }
                column(Description; Desc)
                {
                }
                column(VIN_PurchaseLine; "Purchase Line".VIN)
                {
                }
                column(UnitofMeasure; "Purchase Line"."Unit of Measure")
                {
                }
                column(Quantity; "Purchase Line".Quantity)
                {
                }
                column(UnitPriceLCY; "Purchase Line"."Unit Price (LCY)")
                {
                    AutoFormatExpression = "Purchase Header"."Currency Code";
                }
                column(Amount; "Purchase Line".Amount)
                {
                    AutoFormatExpression = "Purchase Header"."Currency Code";
                }
                column(AmountIncludingVAT; "Purchase Line"."Amount Including VAT")
                {
                    AutoFormatExpression = "Purchase Header"."Currency Code";
                }
                column(VatAmount; "Purchase Line"."Amount Including VAT" - "Purchase Line".Amount)
                {
                    AutoFormatExpression = "Purchase Header"."Currency Code";
                }
                column(TVa; "Purchase Line"."VAT %")
                {
                }
                column(LineDiscountAmount; "Purchase Line"."Line Discount Amount")
                {
                    AutoFormatExpression = "Purchase Header"."Currency Code";
                    IncludeCaption = true;
                }
                column(LineDiscount; "Purchase Line"."Line Discount %")
                {
                }
                column(VATIdentifier; "Purchase Line"."VAT Identifier")
                {
                }
                column(DirectUnitCost; "Purchase Line"."Direct Unit Cost")
                {
                    AutoFormatExpression = "Purchase Header"."Currency Code";
                }
                column(Marque; ServHeaderEDMS."Make Code")
                {
                }
                column(Model; ServHeaderEDMS."Model Code")
                {
                }
                column(Chassis; ServHeaderEDMS.VIN)
                {
                }
                column(ModelCode_PurchaseLine; "Purchase Line"."Model Code")
                {
                }
                column(MakeCode_PurchaseLine; "Purchase Line"."Make Code")
                {
                }
                column(Carrosage; Carrosage)
                {
                }
                column(CrossReferenceNo_PurchaseLine; "Purchase Line"."Cross-Reference No.")
                {
                }
                column(LocationCode_PurchaseLine; "Purchase Line"."Location Code")
                {
                }
                column(PaymentMethodDescription; PaymentMethodDescription)
                {
                }
                column(bin; bin)
                {

                }

                trigger OnAfterGetRecord()
                var
                    recitem: Record item;
                begin
                    recitem.Reset();
                    bin := '';
                    recitem.SetRange("No.", "No.");
                    if recitem.FindFirst() then begin
                        recitem.setMgPrincipalFilter(recitem);
                        recitem.CalcFields("Default Bin", "Available Inventory");
                        bin := recitem."Default Bin";
                        //Message('item No %1 - bin %2 - default bin %3 - Qty %4', recitem."No.", bin, recitem."Default Bin", recitem."Available Inventory");
                    end;
                    Desc := '';
                    Nunarticle := '';
                    IF "Line Type" = "Line Type"::Vehicle THEN BEGIN
                        Desc := "Purchase Line"."Make Code" + '   ' + "Purchase Line"."Model Code" + '   ' + "Purchase Line"."Model Version No." + '   ' + ' (VIN : ' + "Purchase Line".VIN + ' )';
                        Nunarticle := "Purchase Line"."Model Version No."
                    END
                    ELSE BEGIN
                        Desc := "Purchase Line".Description;
                        Nunarticle := "Purchase Line"."No."
                    END;

                    increment := increment + 1;

                    Description := "Purchase Line".Description;
                    Nunarticle := "Purchase Line"."No.";

                    NNCPurchLineInvDiscAmt += "Line Discount Amount";
                    NNCPurchLineLineAmt += "Line Amount" + "Line Discount Amount";
                    NNCTotalLCY := NNCPurchLineLineAmt - NNCPurchLineInvDiscAmt;

                    increment := increment + 1;
                    VATBaseRemainderAfterRoundingLCY := 0;
                    AmtInclVATRemainderAfterRoundingLCY := 0;

                    VATAmountLine.INIT;
                    VATAmountLine."VAT Identifier" := "VAT Identifier";
                    VATAmountLine."VAT Calculation Type" := "VAT Calculation Type";
                    VATAmountLine."Tax Group Code" := "Tax Group Code";
                    VATAmountLine."VAT %" := "VAT %";
                    VATAmountLine."VAT Base" := Amount;
                    VATAmountLine."Amount Including VAT" := "Amount Including VAT";
                    VATAmountLine."Line Amount" := "Line Amount";
                    IF "Allow Invoice Disc." THEN
                        VATAmountLine."Inv. Disc. Base Amount" := "Line Amount";
                    VATAmountLine."Invoice Discount Amount" := "Inv. Discount Amount";
                    VATAmountLine.InsertLine;


                    VATAmount := VATAmountLine.GetTotalVATAmount;
                    TotalAmountInclVAT := VATAmountLine.GetTotalAmountInclVAT;
                    TotalAmount := "Purchase Header"."STStamp Fiscal Amount" + TotalAmountInclVAT;
                    TotalAmountTxt := '';
                end;

                trigger OnPostDataItem()
                begin
                    MTTL."Montant en texte"(TotalAmountTxt, TotalAmount);
                end;

                trigger OnPreDataItem()
                begin
                    VATAmountLine.DELETEALL;
                    Desc := '';

                end;
            }

            dataitem(VATCounter; 2000000026)
            {
                DataItemTableView = SORTING(Number);
                column(VATAmtLineVATBase; VATAmountLine."VAT Base")
                {
                    AutoFormatExpression = "Purchase Header"."Currency Code";
                    AutoFormatType = 1;
                }
                column(VATAmtLineVATAmt; VATAmountLine."VAT Amount")
                {
                    AutoFormatExpression = "Purchase Header"."Currency Code";
                    AutoFormatType = 1;
                }
                column(VATAmtLineVATPer; VATAmountLine."VAT %")
                {
                    DecimalPlaces = 0 : 5;
                }

                trigger OnAfterGetRecord()
                begin
                    VATAmountLine.GetLine(Number);
                end;

                trigger OnPreDataItem()
                begin
                    SETRANGE(Number, 1, VATAmountLine.COUNT);
                    CurrReport.CREATETOTALS(
                      VATAmountLine."Line Amount", VATAmountLine."Inv. Disc. Base Amount",
                      VATAmountLine."Invoice Discount Amount", VATAmountLine."VAT Base", VATAmountLine."VAT Amount");
                end;
            }

            trigger OnAfterGetRecord()
            begin


                payTermDescription := '';
                IF "Purchase Header"."Payment Terms Code" <> '' THEN
                    IF Payterm.GET("Payment Terms Code") THEN
                        payTermDescription := Payterm.Description;
                IF "Purchase Header"."Payment Method Code" <> '' THEN
                    IF PaymentMethod.GET("Purchase Header"."Payment Method Code") THEN
                        PaymentMethodDescription := PaymentMethod.Description;
                shipTermDescription := '';
                IF "Purchase Header"."Shipment Method Code" <> '' THEN
                    IF Shipterm.GET("Shipment Method Code") THEN
                        shipTermDescription := Shipterm.Description;
                Vendor.RESET;
                IF Vendor.GET("Buy-from Vendor No.") THEN;
                IF Purchaser.GET("Purchase Header"."Purchaser Code") THEN;
                IF ShipmentMethod.GET("Purchase Header"."Shipment Method Code") THEN;

                if Location.Get("Location Code") then;


                if ("Purchase Header"."Document Type" = "Document Type"::Quote) then DemandeAchat := true;
                if ("Purchase Header"."Document Type" = "Document Type"::Order) then DemandeAchat := false;
                if ("Purchase Header"."Document Type" = "Document Type"::Quote) then typeDocument := typeDocument::"Demande de prix";
                if ("Purchase Header"."Document Type" = "Document Type"::Order) then typeDocument := typeDocument::"Bon de commande";
                if ("Purchase Header"."Document Type" = "Document Type"::"Return Order") then typeDocument := typeDocument::"Retour Achat";
                if ("Purchase Header"."Document Type" = "Document Type"::Invoice) then typeDocument := typeDocument::"Facture Achat";



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
                group(Display)
                {
                    Caption = 'Affichage';

                    field(AfficherEntetePiedPage; AfficherEntetePiedPage)
                    {
                        Caption = 'Afficher l''entête et le pied de page';
                        ApplicationArea = all;
                    }
                    field(showBin; showBin)
                    {
                        Caption = 'Afficher casier';
                        ApplicationArea = all;
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
        l = 'o';
    }

    trigger OnInitReport()
    begin
        TotalAmountTxt := '';
        ShowExternalReference := TRUE;


    end;

    trigger OnPreReport()
    var
        UserSetup: record "User Setup";
    begin
        Companyinfo.GET;
        Companyinfo.CALCFIELDS("Invoice Footer Picture");
        Companyinfo.CALCFIELDS("Invoice Header Picture");


    end;

    var
        bin: Code[20];
        AfficherEntetePiedPage: Boolean;
        GCommandService: Record 25006146;
        Companyinfo: Record 79;
        payTermDescription: Text[50];
        Payterm: Record 3;
        Shipterm: Record 10;
        shipTermDescription: Text[50];
        Vendor: Record 23;
        increment: Integer;
        Caption01: Label 'Commande achat';
        Caption03: Label 'Type commande : ';
        Caption02: Label ' Date commande:';
        Caption04: Label 'Achat :';
        Caption05: Label 'Tel :';
        Caption06: Label 'Fournisseur :';
        Caption07: Label 'Adresse :';
        Caption08: Label 'Registration No. :';
        Caption09: Label 'E-mail :';
        Caption10: Label 'Référence';
        Caption11: Label 'Description';
        Caption12: Label 'Unité';
        Caption13: Label 'Qté';
        Caption14: Label 'P.U';
        Caption140: Label 'P.U Estimatif';
        Caption15: Label '% Rem.';
        Caption16: Label 'Mnt. HT';
        Caption17: Label '% TVA';
        Caption18: Label 'Base TVA';
        Caption19: Label 'Montant TVA';
        Caption20: Label 'Total H.T. :';
        Caption21: Label 'Remise:';
        Caption22: Label 'Total H.T.';
        Caption23: Label 'Montant TTC';
        Caption24: Label 'Timbre fiscal';
        Caption25: Label 'Total Net à payer :';
        Caption26: Label 'Condition de paiement  :';
        Caption27: Label 'Demandeur:';
        Caption28: Label 'Requesting :';
        Caption29: Label 'Signature Acheteur:';
        Caption30: Label 'Montant';
        Language: Record 8;
        ItemTranslation: Record 30;
        Description: Text[50];
        DisplayLanguage: Code[10];
        Purchaser: Record 13;
        ShipmentMethod: Record 10;
        ServHeaderEDMS: Record 25006145;
        ServLineEDMS: Record 25006146;
        VehOptLedgEntry: Record 25006388;
        OwnOpt: Record 25006372;
        Carrosage: Text;
        NoDemande: Text[50];
        ShowExternalReference: Boolean;
        Caption31: Label 'External reference';
        VATAmountLine: Record 290 temporary;
        TotalAmountTxt: Text;
        MTTL: Codeunit MontantTouteLettre;
        TotalAmount: Decimal;
        TotalAmountInclVAT: Decimal;
        NNCPurchLineInvDiscAmt: Decimal;
        NNCTotalLCY: Decimal;
        NNCPurchLineLineAmt: Decimal;
        VATBaseRemainderAfterRoundingLCY: Decimal;
        AmtInclVATRemainderAfterRoundingLCY: Decimal;
        VATAmount: Decimal;
        Desc: Text[150];
        Nunarticle: Code[20];
        PaymentMethod: Record 289;
        PaymentMethodDescription: Text[100];
        Text1Footer: Text;
        Location: Record Location;
        DemandeAchat: Boolean;
        typeDocument: Option "Demande de prix","Bon de commande","Retour Achat","Facture Achat";
        showBin: Boolean;
}

