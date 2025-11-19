codeunit 50025 "KPI Management"
{
    Subtype = Normal;

    // =============================================================
    // 1. OBTENIR OU CRÉER LE CACHE DU JOUR
    // =============================================================
    local procedure GetOrCreateTodayCache(var KPICache: Record "KPI Cache"): Boolean
    var
        TodayDate: Date;
    begin
        TodayDate := Today;

        KPICache.Reset();
        KPICache.SetRange("Date", TodayDate);
        if KPICache.FindFirst() then
            exit(true);

        KPICache.Init();
        KPICache."Date" := TodayDate;
        KPICache.Insert(true);
        exit(true);
    end;

    // =============================================================
    // 2. CALCULS INDIVIDUELS
    // =============================================================

    local procedure ComputeTotalFacturesNonReglees(): Decimal
    var
        CustLedEntry: Record "Cust. Ledger Entry";
        Total: Decimal;
    begin
        Total := 0;
        CustLedEntry.Reset();
        CustLedEntry.SetRange("Document Type", CustLedEntry."Document Type"::Invoice);
        CustLedEntry.SetRange(Open, true);
        CustLedEntry.SetFilter("Customer Posting Group", '<>CLT-INT');
        if CustLedEntry.FindSet() then
            repeat
                CustLedEntry.CalcFields("Remaining Amount");
                Total += CustLedEntry."Remaining Amount";
            until CustLedEntry.Next() = 0;
        exit(Total);
    end;

    local procedure ComputeNbFacturesNonReglees(): Integer
    var
        CustLedEntry: Record "Cust. Ledger Entry";
    begin
        CustLedEntry.Reset();
        CustLedEntry.SetRange("Document Type", CustLedEntry."Document Type"::Invoice);
        CustLedEntry.SetRange(Open, true);
        CustLedEntry.SetFilter("Customer Posting Group", '<>CLT-INT');
        exit(CustLedEntry.Count);
    end;

    local procedure ComputeTotalAvoirsNonReglees(): Decimal
    var
        CustLedEntry: Record "Cust. Ledger Entry";
        Total: Decimal;
    begin
        Total := 0;
        CustLedEntry.Reset();
        CustLedEntry.SetRange("Document Type", CustLedEntry."Document Type"::"Credit Memo");
        CustLedEntry.SetRange(Open, true);
        CustLedEntry.SetFilter("Customer Posting Group", '<>CLT-INT');
        if CustLedEntry.FindSet() then
            repeat
                CustLedEntry.CalcFields("Remaining Amount");
                Total += CustLedEntry."Remaining Amount";
            until CustLedEntry.Next() = 0;
        exit(Total);
    end;

    local procedure ComputeNbAvoirsNonReglees(): Integer
    var
        CustLedEntry: Record "Cust. Ledger Entry";
    begin
        CustLedEntry.Reset();
        CustLedEntry.SetRange("Document Type", CustLedEntry."Document Type"::"Credit Memo");
        CustLedEntry.SetRange(Open, true);
        CustLedEntry.SetFilter("Customer Posting Group", '<>CLT-INT');
        exit(CustLedEntry.Count);
    end;

    local procedure ComputeTotalFactureNonRegleeRC(): Decimal
    var
        SalesInvHeader: Record "Sales Invoice Header";
        Total: Decimal;
    begin
        Total := 0;
        SalesInvHeader.Reset();
        SalesInvHeader.SetRange(solde, false);
        if SalesInvHeader.FindSet() then
            repeat
                SalesInvHeader.CalcFields("Amount Including VAT", "Montant reçu caisse");
                Total += SalesInvHeader."Amount Including VAT" + SalesInvHeader."STStamp Amount" - SalesInvHeader."Montant reçu caisse";
            until SalesInvHeader.Next() = 0;
        exit(Total);
    end;

    local procedure ComputeTotalAvoirNonRegleeRC(): Decimal
    var
        SalesCrMemo: Record "Sales Cr.Memo Header";
        Total: Decimal;
    begin
        Total := 0;
        SalesCrMemo.Reset();
        SalesCrMemo.SetRange(solde, false);
        if SalesCrMemo.FindSet() then
            repeat
                SalesCrMemo.CalcFields("Amount Including VAT", "Montant reçu caisse");
                Total += SalesCrMemo."Amount Including VAT" - SalesCrMemo."Montant reçu caisse";
            until SalesCrMemo.Next() = 0;
        exit(Total);
    end;

    local procedure ComputeTotalBLNonRegleeRC(): Decimal
    var
        SalesShipment: Record "Sales Shipment Header";
        Total: Decimal;
    begin
        Total := 0;
        SalesShipment.Reset();
        SalesShipment.SetRange(solde, false);
        SalesShipment.SetRange(BS, false);
        if SalesShipment.FindSet() then
            repeat
                SalesShipment.CalcFields("Line Amount", "Montant reçu caisse");
                Total += SalesShipment."Line Amount" - SalesShipment."Montant reçu caisse";
            until SalesShipment.Next() = 0;
        exit(Total);
    end;

    local procedure ComputeTotalBSNonRegleeRC(): Decimal
    var
        ArchiveBS: Record "Entete archive BS";
        Total: Decimal;
    begin
        Total := 0;
        ArchiveBS.Reset();
        ArchiveBS.SetRange(solde, false);
        if ArchiveBS.FindSet() then
            repeat
                ArchiveBS.CalcFields("Montant TTC", "Montant reçu caisse");
                Total += ArchiveBS."Montant TTC" - ArchiveBS."Montant reçu caisse";
            until ArchiveBS.Next() = 0;
        exit(Total);
    end;

    local procedure ComputeTotalRetourBLNonRegleeRC(): Decimal
    var
        ReturnReceipt: Record "Return Receipt Header";
        Total: Decimal;
    begin
        Total := 0;
        ReturnReceipt.Reset();
        ReturnReceipt.SetRange(solde, false);
        ReturnReceipt.SetRange(BS, false);
        if ReturnReceipt.FindSet() then
            repeat
                ReturnReceipt.CalcFields("Line Amount", "Montant reçu caisse");
                Total += ReturnReceipt."Line Amount" - ReturnReceipt."Montant reçu caisse";
            until ReturnReceipt.Next() = 0;
        exit(Total);
    end;

    local procedure ComputeTotalRetourBSNonRegleeRC(): Decimal
    var
        ReturnReceipt: Record "Return Receipt Header";
        Total: Decimal;
    begin
        Total := 0;
        ReturnReceipt.Reset();
        ReturnReceipt.SetRange(solde, false);
        ReturnReceipt.SetRange(BS, true);
        if ReturnReceipt.FindSet() then
            repeat
                ReturnReceipt.CalcFields("Line Amount", "Montant reçu caisse");
                Total += ReturnReceipt."Line Amount" - ReturnReceipt."Montant reçu caisse";
            until ReturnReceipt.Next() = 0;
        exit(Total);
    end;

    local procedure ComputeTodaySales(): Decimal
    var
        SalesLine: Record "Sales Line";
        Total: Decimal;
    begin
        Total := 0;
        SalesLine.Reset();
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
        SalesLine.SetRange("Shipment Date", WorkDate());
        if SalesLine.FindSet() then
            repeat
                Total += SalesLine."Line Amount";
            until SalesLine.Next() = 0;
        exit(Total);
    end;

    local procedure ComputeTodayReturns(): Decimal
    var
        SalesLine: Record "Sales Line";
        Total: Decimal;
    begin
        Total := 0;
        SalesLine.Reset();
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::"Return Order");
        SalesLine.SetRange("Shipment Date", WorkDate());
        if SalesLine.FindSet() then
            repeat
                Total += SalesLine."Line Amount";
            until SalesLine.Next() = 0;
        exit(Total);
    end;

    local procedure ComputeLitigePlusValue(): Decimal
    var
        BinContent: Record "Bin Content";
        Item: Record Item;
        Total: Decimal;
        InvSetup: Record "Inventory Setup";
    begin
        Total := 0;
        InvSetup.Get();
        BinContent.Reset();
        BinContent.SetRange("Location Code", InvSetup."Magasin litige");
        BinContent.SetRange("Bin Code", InvSetup."Emplacement Litige +");
        BinContent.SetFilter(Quantity, '>0');
        if BinContent.FindSet() then
            repeat
                if Item.Get(BinContent."Item No.") then
                    Total += Item."Unit Cost" * BinContent.CalcQtyUOM;
            until BinContent.Next() = 0;
        exit(Total);
    end;

    local procedure ComputeLitigeMoinsValue(): Decimal
    var
        BinContent: Record "Bin Content";
        Item: Record Item;
        Total: Decimal;
        InvSetup: Record "Inventory Setup";
    begin
        Total := 0;
        InvSetup.Get();
        BinContent.Reset();
        BinContent.SetRange("Location Code", InvSetup."Magasin litige");
        BinContent.SetRange("Bin Code", InvSetup."Emplacement Litige -");
        BinContent.SetFilter(Quantity, '>0');
        if BinContent.FindSet() then
            repeat
                if Item.Get(BinContent."Item No.") then
                    Total += Item."Unit Cost" * BinContent.CalcQtyUOM;
            until BinContent.Next() = 0;
        exit(Total);
    end;

    local procedure ComputeEndommageValue(): Decimal
    var
        BinContent: Record "Bin Content";
        Item: Record Item;
        Total: Decimal;
        InvSetup: Record "Inventory Setup";
    begin
        Total := 0;
        InvSetup.Get();
        BinContent.Reset();
        BinContent.SetRange("Location Code", InvSetup."Magasin litige");
        BinContent.SetRange("Bin Code", InvSetup."Emplacement Endommagé");
        BinContent.SetFilter(Quantity, '>0');
        if BinContent.FindSet() then
            repeat
                if Item.Get(BinContent."Item No.") then
                    Total += Item."Unit Cost" * BinContent.CalcQtyUOM;
            until BinContent.Next() = 0;
        exit(Total);
    end;

    local procedure ComputeAjustementPositif(): Decimal
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        Total: Decimal;
        GLSetup: Record "General Ledger Setup";
    begin
        Total := 0;
        GLSetup.Get();
        ItemLedgEntry.Reset();
        ItemLedgEntry.SetRange("Entry Type", ItemLedgEntry."Entry Type"::"Positive Adjmt.");
        ItemLedgEntry.SetFilter("Posting Date", '%1..%2', DMY2Date(3, 1, Date2DMY(Today, 3)), WorkDate());
        ItemLedgEntry.SetFilter("Remaining Quantity", '<>0');
        if ItemLedgEntry.FindSet() then
            repeat
                ItemLedgEntry.CalcFields("Cost Amount (Actual)");
                Total += (ItemLedgEntry."Cost Amount (Actual)" / ItemLedgEntry.Quantity) * ItemLedgEntry."Remaining Quantity";
            until ItemLedgEntry.Next() = 0;
        exit(Total);
    end;

    local procedure ComputeAjustementNegatif(): Decimal
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        Total: Decimal;
        GLSetup: Record "General Ledger Setup";
    begin
        Total := 0;
        GLSetup.Get();
        ItemLedgEntry.Reset();
        ItemLedgEntry.SetRange("Entry Type", ItemLedgEntry."Entry Type"::"Negative Adjmt.");
        ItemLedgEntry.SetFilter("Posting Date", '%1..', CalcDate('<CD+2D>', GLSetup."Allow Posting From"));
        if ItemLedgEntry.FindSet() then
            repeat
                ItemLedgEntry.CalcFields("Cost Amount (Actual)");
                Total += ItemLedgEntry."Cost Amount (Actual)";
            until ItemLedgEntry.Next() = 0;
        exit(Total);
    end;

    // =============================================================
    // CHÈQUES & TRAITES — 100% CONFORME AUX FLOWFIELDS
    // =============================================================

    local procedure ComputeChequeEnCoffre(): Decimal
    var
        PaymentLine: Record "Payment Line";
        Total: Decimal;
    begin
        Total := 0;
        PaymentLine.Reset();
        PaymentLine.SetRange("Type réglement", 'ENC_CHEQUE');
        PaymentLine.SetRange("Account Type", PaymentLine."Account Type"::Customer);
        PaymentLine.SetRange("Copied To No.", '');
        PaymentLine.SetRange("Status No.", 21000);
        if PaymentLine.FindSet() then
            repeat
                Total += PaymentLine."Amount (LCY)";
            until PaymentLine.Next() = 0;
        exit(-Total); // Négatif comme dans FlowField
    end;

    local procedure ComputeChequeImpaye(): Decimal
    var
        PaymentLine: Record "Payment Line";
        Total: Decimal;
    begin
        Total := 0;
        PaymentLine.Reset();
        PaymentLine.SetRange("Type réglement", 'ENC_CHEQUE');
        PaymentLine.SetRange("Account Type", PaymentLine."Account Type"::Customer);
        PaymentLine.SetRange("Copied To No.", '');
        PaymentLine.SetRange("Status No.", 32000);
        if PaymentLine.FindSet() then
            repeat
                Total += PaymentLine."Amount (LCY)";
            until PaymentLine.Next() = 0;
        exit(-Total);
    end;

    local procedure ComputeTraiteEnCoffre(): Decimal
    var
        PaymentLine: Record "Payment Line";
        Total: Decimal;
    begin
        Total := 0;
        PaymentLine.Reset();
        PaymentLine.SetRange("Type réglement", 'ENC_TRAITE');
        PaymentLine.SetRange("Account Type", PaymentLine."Account Type"::Customer);
        PaymentLine.SetRange("Copied To No.", '');
        PaymentLine.SetRange("Status No.", 30000);
        if PaymentLine.FindSet() then
            repeat
                Total += PaymentLine."Amount (LCY)";
            until PaymentLine.Next() = 0;
        exit(-Total);
    end;

    local procedure ComputeTraiteEnEscompte(): Decimal
    var
        PaymentLine: Record "Payment Line";
        Total: Decimal;
    begin
        Total := 0;
        PaymentLine.Reset();
        PaymentLine.SetRange("Type réglement", 'ENC_TRAITE');
        PaymentLine.SetRange("Account Type", PaymentLine."Account Type"::Customer);
        PaymentLine.SetRange("Copied To No.", '');
        PaymentLine.SetRange("Status No.", 50030);
        PaymentLine.SetFilter("Due Date", '>%1', Today); // "Due Date > a" = futur
        if PaymentLine.FindSet() then
            repeat
                Total += PaymentLine."Amount (LCY)";
            until PaymentLine.Next() = 0;
        exit(-Total);
    end;

    local procedure ComputeTraiteImpayee(): Decimal
    var
        PaymentLine: Record "Payment Line";
        Total: Decimal;
    begin
        Total := 0;
        PaymentLine.Reset();
        PaymentLine.SetRange("Type réglement", 'ENC_TRAITE');
        PaymentLine.SetRange("Account Type", PaymentLine."Account Type"::Customer);
        PaymentLine.SetRange("Copied To No.", '');
        PaymentLine.SetFilter("Status No.", '40050|50070');
        if PaymentLine.FindSet() then
            repeat
                Total += PaymentLine."Amount (LCY)";
            until PaymentLine.Next() = 0;
        exit(-Total);
    end;

    // =============================================================
    // 3. MISE À JOUR COMPLÈTE DU CACHE
    // =============================================================
    procedure UpdateAllKPICache()
    var
        KPICache: Record "KPI Cache";
    begin
        if not GetOrCreateTodayCache(KPICache) then
            exit;

        KPICache."Total Factures Non Réglées" := ComputeTotalFacturesNonReglees();
        KPICache."Nb Factures Non Réglées" := ComputeNbFacturesNonReglees();
        KPICache."Total Avoirs Non Réglés" := ComputeTotalAvoirsNonReglees();
        KPICache."Nb Avoirs Non Réglés" := ComputeNbAvoirsNonReglees();

        KPICache."Total Fact RC Non Réglées" := ComputeTotalFactureNonRegleeRC();
        KPICache."Total Avoir RC Non Réglés" := ComputeTotalAvoirNonRegleeRC();
        KPICache."Total BL Non Réglés RC" := ComputeTotalBLNonRegleeRC();
        KPICache."Total BS Non Réglés RC" := ComputeTotalBSNonRegleeRC();
        KPICache."Total Retour BL RC" := ComputeTotalRetourBLNonRegleeRC();
        KPICache."Total Retour BS RC" := ComputeTotalRetourBSNonRegleeRC();

        KPICache."Ventes du Jour" := ComputeTodaySales();
        KPICache."Retours du Jour" := ComputeTodayReturns();

        KPICache."Valeur Litige +" := ComputeLitigePlusValue();
        KPICache."Valeur Litige -" := ComputeLitigeMoinsValue();
        KPICache."Valeur Endommagé" := ComputeEndommageValue();

        KPICache."Ajustement Positif" := ComputeAjustementPositif();
        KPICache."Ajustement Négatif" := ComputeAjustementNegatif();

        KPICache."Chèques en Coffre" := ComputeChequeEnCoffre();
        KPICache."Chèques Impayés" := ComputeChequeImpaye();
        KPICache."Traites en Coffre" := ComputeTraiteEnCoffre();
        KPICache."Traites Escompte" := ComputeTraiteEnEscompte();
        KPICache."Traites Impayées" := ComputeTraiteImpayee();

        KPICache.Modify(true);
    end;

    // =============================================================
    // 4. LECTURE RAPIDE
    // =============================================================
    procedure GetTotalFacturesNonReglees(): Decimal
    var
        KPICache: Record "KPI Cache";
    begin
        if GetOrCreateTodayCache(KPICache) then
            exit(KPICache."Total Factures Non Réglées");
        exit(0);
    end;

    procedure GetNbFacturesNonReglees(): Integer
    var
        KPICache: Record "KPI Cache";
    begin
        if GetOrCreateTodayCache(KPICache) then
            exit(KPICache."Nb Factures Non Réglées");
        exit(0);
    end;

    procedure GetTotalAvoirsNonReglees(): Decimal
    var
        KPICache: Record "KPI Cache";
    begin
        if GetOrCreateTodayCache(KPICache) then
            exit(KPICache."Total Avoirs Non Réglés");
        exit(0);
    end;

    procedure GetNbAvoirsNonReglees(): Integer
    var
        KPICache: Record "KPI Cache";
    begin
        if GetOrCreateTodayCache(KPICache) then
            exit(KPICache."Nb Avoirs Non Réglés");
        exit(0);
    end;

    procedure GetTotalFactureNonRegleeRC(): Decimal
    var
        KPICache: Record "KPI Cache";
    begin
        if GetOrCreateTodayCache(KPICache) then
            exit(KPICache."Total Fact RC Non Réglées");
        exit(0);
    end;

    procedure GetTotalAvoirNonRegleeRC(): Decimal
    var
        KPICache: Record "KPI Cache";
    begin
        if GetOrCreateTodayCache(KPICache) then
            exit(KPICache."Total Avoir RC Non Réglés");
        exit(0);
    end;

    procedure GetTotalBLNonRegleeRC(): Decimal
    var
        KPICache: Record "KPI Cache";
    begin
        if GetOrCreateTodayCache(KPICache) then
            exit(KPICache."Total BL Non Réglés RC");
        exit(0);
    end;

    procedure GetTotalBSNonRegleeRC(): Decimal
    var
        KPICache: Record "KPI Cache";
    begin
        if GetOrCreateTodayCache(KPICache) then
            exit(KPICache."Total BS Non Réglés RC");
        exit(0);
    end;

    procedure GetTotalRetourBLNonRegleeRC(): Decimal
    var
        KPICache: Record "KPI Cache";
    begin
        if GetOrCreateTodayCache(KPICache) then
            exit(KPICache."Total Retour BL RC");
        exit(0);
    end;

    procedure GetTotalRetourBSNonRegleeRC(): Decimal
    var
        KPICache: Record "KPI Cache";
    begin
        if GetOrCreateTodayCache(KPICache) then
            exit(KPICache."Total Retour BS RC");
        exit(0);
    end;

    procedure GetTodaySales(): Decimal
    var
        KPICache: Record "KPI Cache";
    begin
        if GetOrCreateTodayCache(KPICache) then
            exit(KPICache."Ventes du Jour");
        exit(0);
    end;

    procedure GetTodayReturns(): Decimal
    var
        KPICache: Record "KPI Cache";
    begin
        if GetOrCreateTodayCache(KPICache) then
            exit(KPICache."Retours du Jour");
        exit(0);
    end;

    procedure GetLitigePlusValue(): Decimal
    var
        KPICache: Record "KPI Cache";
    begin
        if GetOrCreateTodayCache(KPICache) then
            exit(KPICache."Valeur Litige +");
        exit(0);
    end;

    procedure GetLitigeMoinsValue(): Decimal
    var
        KPICache: Record "KPI Cache";
    begin
        if GetOrCreateTodayCache(KPICache) then
            exit(KPICache."Valeur Litige -");
        exit(0);
    end;

    procedure GetEndommageValue(): Decimal
    var
        KPICache: Record "KPI Cache";
    begin
        if GetOrCreateTodayCache(KPICache) then
            exit(KPICache."Valeur Endommagé");
        exit(0);
    end;

    procedure GetAjustementPositif(): Decimal
    var
        KPICache: Record "KPI Cache";
    begin
        if GetOrCreateTodayCache(KPICache) then
            exit(KPICache."Ajustement Positif");
        exit(0);
    end;

    procedure GetAjustementNegatif(): Decimal
    var
        KPICache: Record "KPI Cache";
    begin
        if GetOrCreateTodayCache(KPICache) then
            exit(KPICache."Ajustement Négatif");
        exit(0);
    end;

    procedure GetChequeEnCoffre(): Decimal
    var
        KPICache: Record "KPI Cache";
    begin
        if GetOrCreateTodayCache(KPICache) then
            exit(KPICache."Chèques en Coffre");
        exit(0);
    end;

    procedure GetChequeImpaye(): Decimal
    var
        KPICache: Record "KPI Cache";
    begin
        if GetOrCreateTodayCache(KPICache) then
            exit(KPICache."Chèques Impayés");
        exit(0);
    end;

    procedure GetTraiteEnCoffre(): Decimal
    var
        KPICache: Record "KPI Cache";
    begin
        if GetOrCreateTodayCache(KPICache) then
            exit(KPICache."Traites en Coffre");
        exit(0);
    end;

    procedure GetTraiteEscompte(): Decimal
    var
        KPICache: Record "KPI Cache";
    begin
        if GetOrCreateTodayCache(KPICache) then
            exit(KPICache."Traites Escompte");
        exit(0);
    end;

    procedure GetTraiteImpayee(): Decimal
    var
        KPICache: Record "KPI Cache";
    begin
        if GetOrCreateTodayCache(KPICache) then
            exit(KPICache."Traites Impayées");
        exit(0);
    end;

    // =============================================================
    // 5. NETTOYAGE
    // =============================================================
    procedure CleanupOldCache(DaysToKeep: Integer)
    var
        KPICache: Record "KPI Cache";
        CutoffDate: Date;
    begin
        CutoffDate := CalcDate('<-' + Format(DaysToKeep) + 'D>', Today);
        KPICache.SetFilter("Date", '<%1', CutoffDate);
        if not KPICache.IsEmpty then
            KPICache.DeleteAll();
    end;
}