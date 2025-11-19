page 50129 "Admin Comm. Gros KPI"
{
    Caption = 'Indicateurs clés d''activités';
    PageType = CardPart;
    RefreshOnActivate = false;
    SourceTable = "Sales Cue";

    layout
    {
        area(content)
        {
            cuegroup(ADMIN)
            {
                Caption = 'Notification Admin';
                field("Unit price modified 2"; rec."Sales Line PU Modif")
                {
                    Caption = 'Prix vente modifié';
                    ApplicationArea = All;
                    DrillDownPageId = "Sales line";
                    DrillDown = true;
                }
                field("Discount modified"; rec."Sales Line Disc. Modif")
                {
                    Caption = 'Remise modifié';
                    ApplicationArea = All;
                    DrillDownPageId = "Sales line";
                    DrillDown = true;
                }

                field("Today Sum Sales"; KPIManagement.GetTodaySales())
                {
                    Caption = 'Vente du jour';
                    ApplicationArea = All;
                    DrillDownPageId = "Sales line";
                    DrillDown = true;
                }

                field("Today Sum Return"; KPIManagement.GetTodayReturns())
                {
                    Caption = 'Retour du jour';
                    ApplicationArea = All;
                    DrillDownPageId = "Sales Line";
                    DrillDown = true;
                }

                field("Vente Annuelle"; Vente4)
                {
                    ApplicationArea = Basic;
                    Caption = 'Année';
                    DecimalPlaces = 0 : 0;
                    Image = Calculator;
                }
            }

            cuegroup("Paiment")
            {
                Caption = 'Paiement Client';
                field("Cheque En Coffre"; KPIManagement.GetChequeEnCoffre())
                {
                    ApplicationArea = All;
                    Caption = 'Total Cheque En Coffre';
                    DecimalPlaces = 0 : 0;
                    trigger OnDrillDown()
                    var
                        PaymentLine: Record "Payment Line";
                    begin
                        PaymentLine.Reset();
                        PaymentLine.SetFilter("Type réglement", '%1', 'ENC_CHEQUE');
                        PaymentLine.SetFilter("Account Type", '%1', PaymentLine."Account Type"::Customer);
                        PaymentLine.SetFilter("Status No.", '%1', 21000);
                        PaymentLine.SetFilter("Copied To No.", '%1', '');
                        Page.Run(page::"Payment Lines List", PaymentLine);

                    end;
                }

                field("Cheque Impaye"; KPIManagement.GetChequeImpaye())
                {
                    ApplicationArea = All;
                    Caption = 'Total Cheque Impayé';
                    DecimalPlaces = 0 : 0;
                    trigger OnDrillDown()
                    var
                        PaymentLine: Record "Payment Line";
                    begin
                        PaymentLine.Reset();
                        PaymentLine.SetFilter("Type réglement", '%1', 'ENC_CHEQUE');
                        PaymentLine.SetFilter("Account Type", '%1', PaymentLine."Account Type"::Customer);
                        PaymentLine.SetFilter("Status No.", '%1', 32000);
                        PaymentLine.SetFilter("Copied To No.", '%1', '');
                        Page.Run(page::"Payment Lines List", PaymentLine);

                    end;
                }

                field("Traite En Coff."; KPIManagement.GetTraiteEnCoffre())
                {
                    ApplicationArea = All;
                    Caption = 'Total Traite En Coffre';
                    DecimalPlaces = 0 : 0;
                    trigger OnDrillDown()
                    var
                        PaymentLine: Record "Payment Line";
                    begin
                        PaymentLine.Reset();
                        PaymentLine.SetFilter("Type réglement", '%1', 'ENC_TRAITE');
                        PaymentLine.SetFilter("Account Type", '%1', PaymentLine."Account Type"::Customer);
                        PaymentLine.SetFilter("Status No.", '%1', 30000);
                        PaymentLine.SetFilter("Copied To No.", '%1', '');
                        Page.Run(page::"Payment Lines List", PaymentLine);

                    end;
                }

                field("Traite En Escompte"; KPIManagement.GetTraiteEscompte())
                {
                    ApplicationArea = All;
                    Caption = 'Total Traite Escompte';
                    DecimalPlaces = 0 : 0;
                    trigger OnDrillDown()
                    var
                        PaymentLine: Record "Payment Line";
                    begin
                        PaymentLine.Reset();
                        PaymentLine.SetFilter("Type réglement", '%1', 'ENC_TRAITE');
                        PaymentLine.SetFilter("Account Type", '%1', PaymentLine."Account Type"::Customer);
                        PaymentLine.SetFilter("Status No.", '%1', 50030);
                        PaymentLine.SetFilter("Copied To No.", '%1', '');
                        PaymentLine.SetFilter("Due Date", '>%1', WorkDate);
                        Page.Run(page::"Payment Lines List", PaymentLine);

                    end;
                }

                field("Traite Impaye"; KPIManagement.GetTraiteImpayee())
                {
                    ApplicationArea = All;
                    Caption = 'Total Traite Impayee';
                    DecimalPlaces = 0 : 0;
                    trigger OnDrillDown()
                    var
                        PaymentLine: Record "Payment Line";
                    begin
                        PaymentLine.Reset();
                        PaymentLine.SetFilter("Type réglement", '%1', 'ENC_TRAITE');
                        PaymentLine.SetFilter("Account Type", '%1', PaymentLine."Account Type"::Customer);
                        PaymentLine.SetFilter("Status No.", '%1|%2', 40050, 50070);
                        PaymentLine.SetFilter("Copied To No.", '%1', '');
                        Page.Run(page::"Payment Lines List", PaymentLine);

                    end;
                }
            }

            cuegroup("Reglement Reçu de caisse")
            {
                Caption = 'Non Réglée Reçu de caisse';
                field(TotalFactNonRegleeRC; KPIManagement.GetTotalFactureNonRegleeRC())
                {
                    Caption = 'Factures Non Reg RC';
                    ApplicationArea = all;
                    trigger OnDrillDown()
                    var
                        salesInvoice: Record "Sales Invoice Header";
                    begin
                        salesInvoice.Reset();
                        salesInvoice.SetRange(solde, false);
                        Page.Run(Page::"Posted Sales Invoices", salesInvoice);
                    end;
                }
                field(TotalAVNonRegleeRC; -KPIManagement.GetTotalAvoirNonRegleeRC())
                {
                    Caption = 'Avoir Non Reg RC';
                    ApplicationArea = all;
                    trigger OnDrillDown()
                    var
                        salesCrMemo: Record "Sales Cr.Memo Header";
                    begin
                        salesCrMemo.Reset();
                        salesCrMemo.SetRange(solde, false);
                        Page.Run(Page::"Posted Sales Credit Memos", salesCrMemo);
                    end;
                }

                field(TotalBSNonRegleRC; KPIManagement.GetTotalBSNonRegleeRC())
                {
                    Caption = 'BS Non Reg RC';
                    ApplicationArea = all;
                    trigger OnDrillDown()
                    var
                        salesBS: Record "Entete archive BS";
                    begin
                        salesBS.Reset();
                        salesBS.SetRange(solde, false);
                        Page.Run(Page::"Liste archive Bon de sortie", salesBS);
                    end;
                }

                field(TotalRetourBSNonRegleRC; -KPIManagement.GetTotalRetourBSNonRegleeRC())
                {
                    Caption = 'Retour BS Non Reg RC';
                    ApplicationArea = all;
                    trigger OnDrillDown()
                    var
                        salesReturnBS: Record "Return Receipt Header";
                    begin
                        salesReturnBS.Reset();
                        salesReturnBS.SetRange(solde, false);
                        salesReturnBS.SetRange(bs, true);
                        Page.Run(Page::"Posted Return Receipts BS", salesReturnBS);
                    end;
                }

                field(TotalBLNonRegleRC; KPIManagement.GetTotalBLNonRegleeRC())
                {
                    Caption = 'BL Non Reg RC';
                    ApplicationArea = all;
                    trigger OnDrillDown()
                    var
                        salesBL: Record "Sales Shipment Header";
                    begin
                        salesBL.Reset();
                        salesBL.SetRange(solde, false);
                        salesBL.SetRange(bs, false);
                        Page.Run(Page::"Posted Sales Shipments", salesBL);
                    end;
                }

                field(TotalReturnBLNonRegleRC; -KPIManagement.GetTotalRetourBLNonRegleeRC())
                {
                    Caption = 'Retour BL Non Reg RC';
                    ApplicationArea = all;
                    trigger OnDrillDown()
                    var
                        salesReturnBL: Record "Return Receipt Header";
                    begin
                        salesReturnBL.Reset();
                        salesReturnBL.SetRange(solde, false);
                        salesReturnBL.SetRange(bs, false);
                        Page.Run(Page::"Posted Return Receipt List", salesReturnBL);
                    end;
                }
            }

            cuegroup(FactureNonRegle)
            {
                Caption = 'Factures & Avoirs';
                field(factureNonReg; KPIManagement.GetNbFacturesNonReglees())
                {
                    Caption = 'Facture non réglée';
                    ApplicationArea = All;
                    trigger OnDrillDown()
                    var
                        CustomerLedEntries: Record "Cust. Ledger Entry";
                    begin
                        CustomerLedEntries.Reset();
                        CustomerLedEntries.SetRange("Document Type", CustomerLedEntries."Document Type"::Invoice);
                        CustomerLedEntries.SetRange(Open, true);
                        CustomerLedEntries.SetFilter("Customer Posting Group", '<>CLT-INT');
                        Page.Run(Page::"Customer Ledger Entries", CustomerLedEntries);
                    end;
                }
                field(TotalfactureNonReg; KPIManagement.GetTotalFacturesNonReglees())
                {
                    Caption = 'Total Facture non réglée';
                    ApplicationArea = All;
                    trigger OnDrillDown()
                    var
                        CustomerLedEntries: Record "Cust. Ledger Entry";
                    begin
                        CustomerLedEntries.Reset();
                        CustomerLedEntries.SetRange("Document Type", CustomerLedEntries."Document Type"::Invoice);
                        CustomerLedEntries.SetRange(Open, true);
                        CustomerLedEntries.SetFilter("Customer Posting Group", '<>CLT-INT');
                        Page.Run(Page::"Customer Ledger Entries", CustomerLedEntries);
                    end;
                }
                field(AvoirNonReg; KPIManagement.GetNbAvoirsNonReglees())
                {
                    Caption = 'Avoir non réglée';
                    ApplicationArea = All;
                    trigger OnDrillDown()
                    var
                        CustomerLedEntries: Record "Cust. Ledger Entry";
                    begin
                        CustomerLedEntries.Reset();
                        CustomerLedEntries.SetRange("Document Type", CustomerLedEntries."Document Type"::"Credit Memo");
                        CustomerLedEntries.SetRange(Open, true);
                        CustomerLedEntries.SetFilter("Customer Posting Group", '<>CLT-INT');
                        Page.Run(Page::"Customer Ledger Entries", CustomerLedEntries);
                    end;
                }
                field(TotalAvoirNonRegle; KPIManagement.GetTotalAvoirsNonReglees())
                {
                    Caption = 'Total Avoir non réglée';
                    ApplicationArea = All;
                    trigger OnDrillDown()
                    var
                        CustomerLedEntries: Record "Cust. Ledger Entry";
                    begin
                        CustomerLedEntries.Reset();
                        CustomerLedEntries.SetRange("Document Type", CustomerLedEntries."Document Type"::"Credit Memo");
                        CustomerLedEntries.SetRange(Open, true);
                        CustomerLedEntries.SetFilter("Customer Posting Group", '<>CLT-INT');
                        Page.Run(Page::"Customer Ledger Entries", CustomerLedEntries);
                    end;
                }
            }

            cuegroup(PanierBS)
            {
                Caption = 'Panier BS';
                field("Total BS Ligne Inc. VAT"; "Total BS Ligne Inc. VAT")
                {
                    ApplicationArea = All;
                    trigger OnDrillDown()
                    var
                        SalesShitLine: Record "Sales Shipment Line";
                    begin
                        SalesShitLine.SetRange(BS, true);
                        Page.Run(Page::"Ligne Bon de sortie", SalesShitLine);
                    end;
                }
            }

            cuegroup(Article)
            {
                Caption = 'Articles';
                field("Litige +"; FilterLitige)
                {
                    ApplicationArea = All;
                    trigger OnDrillDown()
                    var
                        BinContent: Record "Bin Content";
                    begin
                        InvSetup.Get();
                        BinContent.Reset();
                        BinContent.SetRange("Location Code", InvSetup."Magasin litige");
                        BinContent.SetRange("Bin Code", InvSetup."Emplacement Litige +");
                        BinContent.Setfilter(Quantity, '>0');
                        Page.Run(Page::"Item Bin Contents", BinContent);
                    end;
                }
                field("Neg Ajust Year"; "Neg Ajust Year")
                {
                    Caption = 'NB article Ajust Neg -';
                    ApplicationArea = All;
                    DrillDownPageId = "Item Ledger Entries";
                    DrillDown = true;
                }

                field(ItemHasStockWithoutUnitPrice; ItemHasStockWithoutUnitPrice)
                {
                    Caption = 'En Stock & Sans prix vente';
                    ApplicationArea = All;
                    trigger OnDrillDown()
                    var
                        lItem: Record Item;
                    begin
                        lItem.SetRange("Unit Price", 0);
                        lItem.SetFilter("Location Filter", '<>%1 & <>%2', PurchSetup."Import Location Code", InvSetup."Magasin litige");
                        lItem.CalcFields(Inventory);
                        lItem.SetFilter(Inventory, '<>0');
                        lItem.Setfilter(Type, 'Stock');
                        Page.Run(Page::"Item List", lItem);
                    end;
                }
            }

            cuegroup(AjustLitige)
            {
                Caption = 'Ajustements et litige ';
                field(AjustPosi; KPIManagement.GetAjustementPositif())
                {
                    Caption = 'Ajust. positif (£)';
                    ApplicationArea = All;
                    trigger OnDrillDown()
                    var
                        ItemLedgerEntries: Record "Item Ledger Entry";
                    begin
                        GLSetup.Get();
                        ItemLedgerEntries.Reset();
                        ItemLedgerEntries.SetRange("Entry Type", ItemLedgerEntries."Entry Type"::"Positive Adjmt.");
                        ItemLedEnt.SetFilter("Posting Date", '%1..%2', System.DMY2Date(3, 1, System.Date2DMY(Today, 3)), WorkDate());
                        ItemLedgerEntries.SetFilter("Remaining Quantity", '<>0');
                        Page.Run(Page::"Item Ledger Entries", ItemLedgerEntries);
                    end;
                }
                field(AjustNeg; KPIManagement.GetAjustementNegatif())
                {
                    Caption = 'Ajust. négatif (£)';
                    ApplicationArea = All;
                    trigger OnDrillDown()
                    var
                        ItemLedgerEntries: Record "Item Ledger Entry";
                    begin
                        GLSetup.Get();
                        ItemLedgerEntries.Reset();
                        ItemLedgerEntries.SetRange("Entry Type", ItemLedgerEntries."Entry Type"::"Negative Adjmt.");
                        ItemLedgerEntries.SetFilter("Posting Date", '%1..', CalcDate('<CD+2D>', GLSetup."Allow Posting From"));
                        Page.Run(Page::"Item Ledger Entries", ItemLedgerEntries);
                    end;
                }
                field("Litige + Valeur"; KPIManagement.GetLitigePlusValue())
                {
                    Caption = 'Litige + (£)';
                    ApplicationArea = All;
                    trigger OnDrillDown()
                    var
                        BinContent: Record "Bin Content";
                    begin
                        InvSetup.Get();
                        BinContent.Reset();
                        BinContent.SetRange("Location Code", InvSetup."Magasin litige");
                        BinContent.SetRange("Bin Code", InvSetup."Emplacement Litige +");
                        BinContent.Setfilter(Quantity, '>0');
                        Page.Run(Page::"Item Bin Contents", BinContent);
                    end;
                }
                field("Litige - Valeur"; KPIManagement.GetLitigeMoinsValue())
                {
                    Caption = 'Litige - (£)';
                    ApplicationArea = All;
                    trigger OnDrillDown()
                    var
                        BinContent: Record "Bin Content";
                    begin
                        InvSetup.Get();
                        BinContent.Reset();
                        BinContent.SetRange("Location Code", InvSetup."Magasin litige");
                        BinContent.SetRange("Bin Code", InvSetup."Emplacement Litige -");
                        BinContent.Setfilter(Quantity, '>0');
                        Page.Run(Page::"Item Bin Contents", BinContent);
                    end;
                }
                field("Endommage Valeur"; KPIManagement.GetEndommageValue())
                {
                    Caption = 'Endommagé (£)';
                    ApplicationArea = All;
                    trigger OnDrillDown()
                    var
                        BinContent: Record "Bin Content";
                    begin
                        InvSetup.Get();
                        BinContent.Reset();
                        BinContent.SetRange("Location Code", InvSetup."Magasin litige");
                        BinContent.SetRange("Bin Code", InvSetup."Emplacement Endommagé");
                        BinContent.Setfilter(Quantity, '>0');
                        Page.Run(Page::"Item Bin Contents", BinContent);
                    end;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("Set Up Cues")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Set Up Cues';
                Image = Setup;
                ToolTip = 'Set up the cues (status tiles) related to the role.';
                trigger OnAction()
                var
                    CueRecordRef: RecordRef;
                begin
                    CueRecordRef.GetTable(Rec);
                    CuesAndKpis.OpenCustomizePageForCurrentUser(CueRecordRef.Number);
                end;
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    var
        RoleCenterNotificationMgt: Codeunit "Role Center Notification Mgt.";
    begin
        RoleCenterNotificationMgt.HideEvaluationNotificationAfterStartingTrial;
    end;

    trigger OnAfterGetRecord()
    var
        DocExchServiceSetup: Record "Doc. Exch. Service Setup";
    begin
        ShowDocumentsPendingDodExchService := false;
        if DocExchServiceSetup.Get then
            ShowDocumentsPendingDodExchService := DocExchServiceSetup.Enabled;
    end;

    trigger OnOpenPage()
    var
        RoleCenterNotificationMgt: Codeunit "Role Center Notification Mgt.";
        ConfPersonalizationMgt: Codeunit "Conf./Personalization Mgt.";
        RecentDate: Date;
        recSetupPurchase: Record "Purchases & Payables Setup";
        defaultVendor: code[20];
    begin
        Reset;
        if not Get then begin
            Init;
            Insert;
        end;

        SetRespCenterFilter;
        SetRange("Date Filter", 0D, WorkDate - 1);
        SetFilter("Date Filter2", '>=%1', WorkDate);
        SetFilter("User ID Filter", UserId);

        RoleCenterNotificationMgt.ShowNotifications;
        ConfPersonalizationMgt.RaiseOnOpenRoleCenterEvent;

        PurchSetup.Get();
        PurchSetup.TestField(PurchSetup."Nbr Days Item recently created");
        RecentDate := CalcDate('<CD-' + format(PurchSetup."Nbr Days Item recently created") + 'D>', Today);
        SetFilter("Date Filter 3", '%1..%2', RecentDate, Today());
        InvSetup.Get();
        SalesOrderFitlers();

        if B2BStatusArray[1] > 10 then EnAttente1 := 'Unfavorable';
        if B2BStatusArray[3] > 10 then EnAttente3 := 'Unfavorable';
        if B2BStatusArray[5] > 10 then EnAttente5 := 'Unfavorable';
        if B2BStatusArray[6] > 10 then EnAttente6 := 'Unfavorable';

        SetRange("Date Filter2", Today);
        CalcFields("Sales (LCY)");
        Vente1 := "Sales (LCY)";

        StartingDate := System.DMY2Date(1, System.Date2DMY(Today, 2), System.Date2DMY(Today, 3));
        SetRange("Date Filter2", StartingDate, WorkDate);
        CalcFields("Sales (LCY)");
        Vente2 := "Sales (LCY)";

        StartingDate := System.DMY2Date(1, 1, System.Date2DMY(Today, 3));
        Setfilter("Date Filter2", '%1..', StartingDate);
        CalcFields("Sales (LCY)");
        Vente3 := "Sales (LCY)";

        userSetup.SetFilter("User ID", UserId);
        if userSetup.FindFirst() then
            StatPurchaseCA := userSetup."Purchase Stat CA";

        recSetupPurchase.Reset();
        if recSetupPurchase.FindFirst() then
            defaultVendor := recSetupPurchase."Default Vendor";
        if "Default Vendor" <> defaultVendor then begin
            "Default Vendor" := defaultVendor;
            Modify();
        end;

        if "date jour" <> Today then begin
            "date jour" := Today;
            Modify();
        end;

        StartingDate2 := System.DMY2Date(1, 1, System.Date2DMY(Today, 3));
        Setfilter("Date Filter2", '%1..', StartingDate2);
        CalcFields("Sales (LCY)");
        Vente4 := "Sales (LCY)";

        debutMois := CalcDate('<-CM>', Today);
        FinMois := CalcDate('<CM>', Today);
        SetFilter("Date Filter Month", '%1..%2', debutMois, FinMois);
        CalcFields("Month Sum Purchase");
        achat := "Month Sum Purchase";
    end;

    // === VARIABLES GLOBALES (à garder) ===
    var
        KPIManagement: Codeunit "KPI Management";
        Vente4, achat : Decimal;
        StatPurchaseCA: Boolean;
        StartingDate2, debutMois, FinMois : Date;
        userSetup: Record "User Setup";
        B2BStatusArray: array[20] of integer;
        SalesOrders: Record "Sales Header";
        PurchSetup: Record "Purchases & Payables Setup";
        InvSetup: Record "Inventory Setup";
        Item: Record Item;
        ItemLedEnt: Record "Item Ledger Entry";
        GLSetup: Record "General Ledger Setup";
        [InDataSet]
        EnAttente1, EnAttente3, EnAttente5, EnAttente6 : Code[20];
        CountSSH: Integer;
        TempSalesShipmentHead: Record "Sales Shipment header" temporary;
        TempReturReceiptHeader: Record "Return Receipt Header" temporary;
        Vente1, Vente2, Vente3 : Decimal;
        StartingDate: Date;
        CuesAndKpis: Codeunit "Cues And KPIs";
        UserTaskManagement: Codeunit "User Task Management";
        ShowDocumentsPendingDodExchService: Boolean;
        IsAddInReady: Boolean;
        IsPageReady: Boolean;
        OpenSalesOrdersCnt: Integer;
        OpenSalesQuotesCnt: Integer;
        OpenReturnOrdersCnt: Integer;
        OpenCreditMemosCnt: Integer;


    local procedure SalesOrderFitlers()
    var
        UserMgt: Codeunit "User Setup Management";
    begin
        SalesOrders.Reset();
        SalesOrders.SetRange("Document Type", SalesOrders."Document Type"::Order);

        IF UserMgt.GetRespCenter(1, '') <> '' THEN BEGIN
            FILTERGROUP(2);
            SalesOrders.SETRANGE("Responsibility Center", UserMgt.GetServiceFilterEDMS);
            FILTERGROUP(0);
        END;

        SalesOrders.SetRange("Statut B2B", SalesOrders."Statut B2B"::"Commande en attente");
        B2BStatusArray[1] := SalesOrders.Count;
        SalesOrders.SetRange("Statut B2B", SalesOrders."Statut B2B"::"Commande lancée");
        B2BStatusArray[2] := SalesOrders.Count;
        SalesOrders.SetRange("Statut B2B", SalesOrders."Statut B2B"::"En cours de préparation");
        B2BStatusArray[3] := SalesOrders.Count;
        SalesOrders.SetRange("Statut B2B", SalesOrders."Statut B2B"::"Préparé");
        B2BStatusArray[4] := SalesOrders.Count;
        SalesOrders.SetRange("Statut B2B", SalesOrders."Statut B2B"::"En cours de pointage");
        B2BStatusArray[5] := SalesOrders.Count;
        SalesOrders.SetRange("Statut B2B", SalesOrders."Statut B2B"::"En attente de livraison");
        B2BStatusArray[6] := SalesOrders.Count;
        SalesOrders.SetRange("Statut B2B", SalesOrders."Statut B2B"::"Livré");
        B2BStatusArray[7] := SalesOrders.Count;
    end;

    local procedure FilterLitige(): Integer
    var
        BinContent: Record "Bin Content";
    begin
        InvSetup.Get();
        BinContent.Reset();
        BinContent.SetRange("Location Code", InvSetup."Magasin litige");
        BinContent.SetRange("Bin Code", InvSetup."Emplacement Litige +");
        BinContent.Setfilter(Quantity, '>0');
        exit(BinContent.Count);
    end;
}