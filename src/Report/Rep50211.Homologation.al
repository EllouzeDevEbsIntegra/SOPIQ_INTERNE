report 50211 "Homologation"
{
    RDLCLayout = './src/report/RDLC/Homologation.rdl';
    PreviewMode = PrintLayout;
    UsageCategory = ReportsAndAnalysis;
    EnableHyperlinks = true;

    dataset
    {
        dataitem("Transit Folder"; "Transit Folder")
        {
            RequestFilterFields = "No.";
            column(Picture; CompanyInformation.Picture)
            {
            }
            column(CompanyName; CompanyInformation.Name)
            {
            }
            column(NumDossier; "Transit Folder"."No.")
            {
            }
            column(NumTransitExterne; "Transit Folder"."External Transit No.")
            {
            }
            column(Datedouverture; "Transit Folder"."Opening Date")
            {
            }
            column("Datedeclôture"; "Transit Folder"."Closing Date")
            {
            }
            column(CodeFournisseur; "Transit Folder"."Vendor No.")
            {
            }
            column(Nomfournisseur; "Transit Folder"."Vendor Name")
            {
            }
            column(Statut; "Transit Folder".Status)
            {
            }
            column(URLDossier; URLDossier)
            {
            }
            column(URLFrs; URLFrs)
            {
            }
            column(CoutPrevu; CoutPrevu)
            {
            }
            dataitem("Value Entry"; "Value Entry")
            {
                DataItemLink = "Transit Folder No." = FIELD("No.");
                DataItemTableView = SORTING("Item Ledger Entry No.", "Entry Type") ORDER(Ascending) WHERE("Document Type" = FILTER("Purchase Receipt" | "Purchase Invoice" | "Purchase Return Shipment" | "Purchase Credit Memo"));
                column(ItemNo; "Value Entry"."Item No.")
                {
                }
                column(ItemChargeNo; "Value Entry"."Item Charge No.")
                {
                }
                column(PostingDate; "Value Entry"."Posting Date")
                {
                }

                column(ItemLedgerEntryType; "Value Entry"."Item Ledger Entry Type")
                {
                }
                column(SourceNo; "Value Entry"."Source No.")
                {
                }
                column(DocumentNo; "Value Entry"."Document No.")
                {
                }
                column(Description; "Value Entry".Description)
                {
                }
                column(DocumentType; "Value Entry"."Document Type")
                {
                }
                column(ExternalDocumentNo; "Value Entry"."External Document No.")
                {
                }
                column(DocumentDate; "Value Entry"."Document Date")
                {
                }
                column(CostAmountActual; "Value Entry"."Cost Amount (Actual)")
                {
                }
                column(ValuedQuantity; "Value Entry"."Valued Quantity")
                {
                }
                column(CostAmountExpected; "Value Entry"."Cost Amount (Expected)")
                {
                }
                column(OrderNo; "Value Entry"."Order No.")
                {
                }
                column(CodeDevise; CodeDevise)
                {
                }
                column(TxChange; TxChange)
                {
                }
                column(MontantDevise; MontantDevise)
                {
                }

                column(TotalMarchandise; TotalMarchandise)
                {
                }

                column(TotalFrais; TotalFrais)
                {
                }
                column(ItemLedgerEntryQuantity; "Value Entry"."Item Ledger Entry Quantity")
                {
                }
                column(ItemLedgerEntryNo; "Value Entry"."Item Ledger Entry No.")
                {
                }
                column(PrixAchatDS; PrixAchatDS)
                {
                }
                column(MntAchatDS; MntAchatDS)
                {
                }
                column(MntFrais; MntFrais)
                {
                }
                column(PrixAchatDevise; PrixAchatDevise)
                {
                }
                column(MontantAchatDevise; MontantAchatDevise)
                {
                }
                column(TxChangeRec; TxChangeRec)
                {
                }
                column(CodeDeviseRec; CodeDeviseRec)
                {
                }
                column(CoutUnitaire; Item."Unit Cost")
                {
                }
                column(PrixUnitaire; Item."Unit Price")
                {
                }
                column(ItemDesc; Item.Description)
                {
                }
                column(ItemChargeDescription; ItemCharge.Description)
                {
                }
                column(URLItem; URLItem)
                {
                }
                column(FraisUnrealReal; FraisUnrealReal)
                {
                }
                column(bolTypeDocReciept; bolTypeDocReciept)
                {
                }
                column(bolTypeDocRetour; bolTypeDocRetour)
                {
                }
                column(bolTypeDocAvoir; bolTypeDocAvoir)
                {
                }
                column(bolTypeDocFact; bolTypeDocFact)
                {
                }

                trigger OnAfterGetRecord()
                var
                    ItemChargeTransitFolders: Record "Item Charge Transit Folder";
                    PurchRcptLine: Record "Purch. Rcpt. Line";
                    QtyToAssign: Decimal;
                    ItemLedgerEntry: Record "Item Ledger Entry";
                    Method: Option " ",Equally,Amount;
                begin
                    if "Value Entry"."Document Type" = "Value Entry"."Document Type"::"Purchase Receipt" THEN
                        bolTypeDocReciept := true
                    else
                        bolTypeDocReciept := false;

                    if "Value Entry"."Document Type" = "Value Entry"."Document Type"::"Purchase Return Shipment" THEN
                        bolTypeDocRetour := true
                    else
                        bolTypeDocRetour := false;

                    if "Value Entry"."Document Type" = "Value Entry"."Document Type"::"Purchase Invoice" THEN
                        bolTypeDocFact := true
                    else
                        bolTypeDocFact := false;
                    if "Value Entry"."Document Type" = "Value Entry"."Document Type"::"Purchase Credit Memo" THEN
                        bolTypeDocAvoir := true
                    else
                        bolTypeDocAvoir := false;



                    CodeDevise := '';
                    TxChange := 0;
                    MontantDevise := 0;
                    MntAchatDS := 0;
                    PrixAchatDS := 0;
                    MntFrais := 0;
                    PrixAchatDevise := 0;
                    MontantAchatDevise := 0;
                    TxChangeRec := 0;
                    CodeDeviseRec := '';
                    //>>DELTA 01
                    UnitCostP := 0;
                    FraisUnrealReal := 0;
                    //<<DELTA 01
                    InvoiceHeader.RESET;
                    ReceptHeader.RESET;
                    ReceptLine.RESET;
                    //Purchase Receipt|Purchase Invoice|Purchase Return Shipment|Purchase Credit Memo
                    // Calc devise+Taux Change+Montant Devise : Purch Inv Header
                    if ("Document Type" = "Document Type"::"Purchase Invoice") and ("Item Charge No." = '') then
                        if InvoiceHeader.GET("Value Entry"."Document No.") then begin
                            CodeDevise := InvoiceHeader."Currency Code";
                            if InvoiceHeader."Currency Factor" <> 0 then
                                TxChange := 1 / InvoiceHeader."Currency Factor"
                            else
                                TxChange := 1;
                            InvoiceHeader.CALCFIELDS(Amount);
                            MontantDevise := InvoiceHeader.Amount;
                            TotalMarchandise += "Value Entry"."Cost Amount (Actual)";
                        end;
                    if PurchInvLine.GET("Document No.", "Document Line No.") then begin
                        PrixAchatDevise := PurchInvLine."Direct Unit Cost";
                        MontantAchatDevise := PurchInvLine.Amount;
                    end;

                    // Calc devise+Taux Change+Montant Devise : Purchase Credit Memo PurchCrMemoHdr PurchCrMemoLine
                    if ("Document Type" = "Document Type"::"Purchase Credit Memo") and ("Item Charge No." = '') then
                        if PurchCrMemoHdr.GET("Value Entry"."Document No.") then begin
                            CodeDevise := PurchCrMemoHdr."Currency Code";
                            if PurchCrMemoHdr."Currency Factor" <> 0 then
                                TxChange := 1 / PurchCrMemoHdr."Currency Factor"
                            else
                                TxChange := 1;
                            PurchCrMemoHdr.CALCFIELDS(Amount);
                            MontantDevise := -PurchCrMemoHdr.Amount;
                            TotalMarchandise += "Value Entry"."Cost Amount (Actual)";
                        end;
                    if PurchCrMemoLine.GET("Document No.", "Document Line No.") then begin
                        PrixAchatDevise := PurchCrMemoLine."Direct Unit Cost";
                        MontantAchatDevise := -PurchCrMemoLine.Amount;
                    end;





                    // Calc Pris Achat Devise + Montant Achat Devise
                    if ("Document Type" = "Document Type"::"Purchase Receipt") and ("Item Charge No." = '') then
                        if ReceptLine.GET("Document No.", "Document Line No.") then begin
                            if ReceptHeader.GET("Document No.") then begin
                                if ReceptHeader."Currency Factor" <> 0 then
                                    TxChangeRec := 1 / ReceptHeader."Currency Factor"
                                else
                                    TxChangeRec := 1;

                                CodeDeviseRec := ReceptHeader."Currency Code";
                            end;
                            PrixAchatDevise := ReceptLine."Unit Cost";
                            MontantAchatDevise := ReceptLine."Item Charge Base Amount";

                        end;

                    // Calc Pris Achat Devise + Montant Achat Devise ReturnShipHeader  ReturnShipLine
                    if ("Document Type" = "Document Type"::"Purchase Return Shipment") and ("Item Charge No." = '') then
                        if ReturnShipLine.GET("Document No.", "Document Line No.") then begin
                            if ReturnShipHeader.GET("Document No.") then begin
                                if ReturnShipHeader."Currency Factor" <> 0 then
                                    TxChangeRec := 1 / ReturnShipHeader."Currency Factor"
                                else
                                    TxChangeRec := 1;

                                CodeDeviseRec := ReturnShipHeader."Currency Code";
                            end;
                            PrixAchatDevise := ReturnShipLine."Unit Cost";
                            MontantAchatDevise := -ReturnShipLine."Item Charge Base Amount";

                        end;



                    // Calc Montant Frais Annex
                    if (("Document Type" = "Document Type"::"Purchase Invoice") or ("Document Type" = "Document Type"::"Purchase Credit Memo")) and ("Item Charge No." <> '') then begin
                        TotalFrais += "Value Entry"."Cost Amount (Actual)";

                    end;


                    // Calc Prix Achat DS + Montant DS article
                    if "Item Charge No." = '' then begin
                        MntAchatDS := "Cost Amount (Actual)" + "Cost Amount (Expected)";
                        PrixAchatDS := 0;
                        MntFrais := 0;
                    end else begin
                        PrixAchatDS := 0;
                        MntAchatDS := 0;
                        MntFrais := "Cost Amount (Actual)" + "Cost Amount (Expected)";
                    end;


                    if Item.GET("Value Entry"."Item No.") then begin
                        URLItem := '';
                        URLItem := GETURL(CLIENTTYPE::Current, COMPANYNAME, OBJECTTYPE::Page, 30, Item);
                    end;

                    if ItemCharge.GET("Value Entry"."Item Charge No.") then;
                    //Calcul cout DS Prévu en se basant sur la methode de repartition par défaut
                    //>>DELTA 01

                    if CoutPrevu then
                        if ("Document Type" = "Document Type"::"Purchase Receipt") and ("Item Charge No." = '') then begin
                            ItemChargeTransitFolders.RESET;
                            ItemChargeTransitFolders.SETRANGE("Transit Folder No.", "Transit Folder No.");
                            ItemChargeTransitFolders.SETFILTER("Expected Purchase Amount (LCY)", '<>%1', 0);
                            ItemChargeTransitFolders.SETFILTER("Assigned Amount", '=%1', 0);
                            ItemChargeTransitFolders.SETFILTER("Not Included", '=%1', false);
                            if ItemChargeTransitFolders.FINDSET then begin
                                PurchRcptLine.RESET;
                                PurchRcptLine.SETRANGE("Transit Folder No.", "Transit Folder No.");
                                PurchRcptLine.SETRANGE("No.", "Item No.");
                                if PurchRcptLine.FINDSET then begin//
                                    repeat

                                        //  Method := ItemChargeTransitFolders."Default Repartition Method";

                                        case itemChargeTransitFolders."Default Repartition Method" of
                                            itemChargeTransitFolders."Default Repartition Method"::Amount:
                                                begin
                                                    QtyToAssign := MntAchatDS / TotAmt;
                                                    TotalCostP := QtyToAssign * ItemChargeTransitFolders."Expected Purchase Amount (LCY)";
                                                end;
                                            itemChargeTransitFolders."Default Repartition Method"::Equally:
                                                begin
                                                    TotalCostP := (ItemChargeTransitFolders."Expected Purchase Amount (LCY)" / LineReceipt);
                                                end;
                                        end;

                                        UnitCostP += TotalCostP;
                                    until ItemChargeTransitFolders.NEXT = 0;
                                    FraisUnrealReal := UnitCostP;
                                    //<<DELTA 02

                                end;
                            end;
                        end;
                end;
                //<<DELTA 01


                trigger OnPreDataItem()
                begin
                    TotalMarchandise := 0;
                    TotalFrais := 0;
                    //>>DELTA 01
                    TotAmt := 0;
                    AmtToAssign := 0;
                    ValueEntry.RESET;
                    ValueEntry.SETRANGE("Transit Folder No.", "Transit Folder"."No.");
                    ValueEntry.SETRANGE("Document Type", ValueEntry."Document Type"::"Purchase Receipt");
                    if ValueEntry.FINDSET then begin
                        repeat
                            TotAmt += ValueEntry."Purchase Amount (Expected)";
                        until ValueEntry.NEXT = 0;
                        LineReceipt := ValueEntry.COUNT;
                    end;
                    //<<DELTA 01
                end;
            }

            trigger OnAfterGetRecord()
            begin
                URLDossier := '';
                URLFrs := '';
                URLDossier := GETURL(CLIENTTYPE::Current, COMPANYNAME, OBJECTTYPE::Page, 50018, "Transit Folder");
                if Vendor.GET("Transit Folder"."Vendor No.") then
                    URLFrs := GETURL(CLIENTTYPE::Current, COMPANYNAME, OBJECTTYPE::Page, 26, Vendor);
            end;
        }
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                group(Control2)
                {
                    Caption = 'Options';
                    field(CoutPrevu; CoutPrevu)
                    {
                        Caption = 'Include Expected Cost';
                        ApplicationArea = all;
                    }
                    field(UpdateCost; UpdateCost)
                    {
                        Caption = 'Mise à jour coût théorique';

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
    }

    trigger OnPreReport()
    begin
        CompanyInformation.GET;
        CompanyInformation.CALCFIELDS(Picture);
    end;

    var
        bolTypeDocRetour: Boolean;
        bolTypeDocFact: Boolean;
        bolTypeDocAvoir: Boolean;

        bolTypeDocReciept: Boolean;
        InvoiceHeader: Record "Purch. Inv. Header";
        CodeDevise: Code[20];
        TxChange: Decimal;
        MontantDevise: Decimal;
        TotalMarchandise: Decimal;
        TotalFrais: Decimal;
        PrixAchatDS: Decimal;
        MntAchatDS: Decimal;
        MntFrais: Decimal;
        PrixAchatDevise: Decimal;
        MontantAchatDevise: Decimal;
        PurchInvLine: Record "Purch. Inv. Line";
        ReceptLine: Record "Purch. Rcpt. Line";
        ReceptHeader: Record "Purch. Rcpt. Header";
        TxChangeRec: Decimal;
        CodeDeviseRec: Code[20];
        CompanyInformation: Record "Company Information";
        RetReceiptHeader: Record "Return Receipt Header";
        RetReceiptLine: Record "Return Receipt Line";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        PurchCrMemoLine: Record "Purch. Cr. Memo Line";
        ReturnShipHeader: Record "Return Shipment Header";
        ReturnShipLine: Record "Return Shipment Line";
        Item: Record Item;
        ItemCharge: Record "Item Charge";
        URLDossier: Text[1024];
        URLFrs: Text[1024];
        URLItem: Text[1024];
        Vendor: Record Vendor;
        "--DELTA": Integer;
        CoutPrevu: Boolean;
        TotalCostP: Decimal;
        UnitCostP: Decimal;
        TotAmt: Decimal;
        ValueEntry: Record "Value Entry";
        AmtToAssign: Decimal;
        LineReceipt: Integer;
        DernierPrixAchat: Decimal;
        PrixMoyen: Decimal;
        FraisUnrealReal: Decimal;
        UpdateCost: Boolean;
        PublishedCost: Decimal;
        itemtest: Code[10];
}