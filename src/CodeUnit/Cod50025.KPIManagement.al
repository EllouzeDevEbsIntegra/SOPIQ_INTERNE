codeunit 50025 "KPI Management"
{
    Permissions = tabledata Item = rimd;

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
        CustLedEntry.SetAutoCalcFields("Remaining Amount");
        if CustLedEntry.FindSet() then
            repeat
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
        CustLedEntry.SetAutoCalcFields("Remaining Amount");
        if CustLedEntry.FindSet() then
            repeat
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
        SalesInvHeader.SetAutoCalcFields("Amount Including VAT", "Montant reçu caisse");
        if SalesInvHeader.FindSet() then
            repeat
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
        SalesCrMemo.SetAutoCalcFields("Amount Including VAT", "Montant reçu caisse");
        if SalesCrMemo.FindSet() then
            repeat
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
        SalesShipment.SetAutoCalcFields("Line Amount", "Montant reçu caisse");
        if SalesShipment.FindSet() then
            repeat
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
        ArchiveBS.SetAutoCalcFields("Montant TTC", "Montant reçu caisse");
        if ArchiveBS.FindSet() then
            repeat
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
        ReturnReceipt.SetAutoCalcFields("Line Amount", "Montant reçu caisse");
        if ReturnReceipt.FindSet() then
            repeat
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
        ReturnReceipt.SetAutoCalcFields("Line Amount", "Montant reçu caisse");
        if ReturnReceipt.FindSet() then
            repeat
                Total += ReturnReceipt."Line Amount" - ReturnReceipt."Montant reçu caisse";
            until ReturnReceipt.Next() = 0;
        exit(Total);
    end;

    local procedure ComputeTodaySales(): Decimal
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.Reset();
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
        SalesLine.SetRange("Shipment Date", WorkDate());
        SalesLine.CalcSums("Line Amount");
        exit(SalesLine."Line Amount");
    end;

    local procedure ComputeTodayReturns(): Decimal
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.Reset();
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::"Return Order");
        SalesLine.SetRange("Shipment Date", WorkDate());
        SalesLine.CalcSums("Line Amount");
        exit(SalesLine."Line Amount");
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
        ItemLedgEntry.SetAutoCalcFields("Cost Amount (Actual)");
        if ItemLedgEntry.FindSet() then
            repeat
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
        ItemLedgEntry.SetAutoCalcFields("Cost Amount (Actual)");
        if ItemLedgEntry.FindSet() then
            repeat
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
    begin
        PaymentLine.Reset();
        PaymentLine.SetRange("Type réglement", 'ENC_CHEQUE');
        PaymentLine.SetRange("Account Type", PaymentLine."Account Type"::Customer);
        PaymentLine.SetRange("Copied To No.", '');
        PaymentLine.SetRange("Status No.", 21000);
        PaymentLine.CalcSums("Amount (LCY)");
        exit(-PaymentLine."Amount (LCY)"); // Négatif comme dans FlowField
    end;

    local procedure ComputeChequeImpaye(): Decimal
    var
        PaymentLine: Record "Payment Line";
    begin
        PaymentLine.Reset();
        PaymentLine.SetRange("Type réglement", 'ENC_CHEQUE');
        PaymentLine.SetRange("Account Type", PaymentLine."Account Type"::Customer);
        PaymentLine.SetRange("Copied To No.", '');
        PaymentLine.SetRange("Status No.", 32000);
        PaymentLine.CalcSums("Amount (LCY)");
        exit(-PaymentLine."Amount (LCY)");
    end;

    local procedure ComputeTraiteEnCoffre(): Decimal
    var
        PaymentLine: Record "Payment Line";
    begin
        PaymentLine.Reset();
        PaymentLine.SetRange("Type réglement", 'ENC_TRAITE');
        PaymentLine.SetRange("Account Type", PaymentLine."Account Type"::Customer);
        PaymentLine.SetRange("Copied To No.", '');
        PaymentLine.SetRange("Status No.", 30000);
        PaymentLine.CalcSums("Amount (LCY)");
        exit(-PaymentLine."Amount (LCY)");
    end;

    local procedure ComputeTraiteEnEscompte(): Decimal
    var
        PaymentLine: Record "Payment Line";
    begin
        PaymentLine.Reset();
        PaymentLine.SetRange("Type réglement", 'ENC_TRAITE');
        PaymentLine.SetRange("Account Type", PaymentLine."Account Type"::Customer);
        PaymentLine.SetRange("Copied To No.", '');
        PaymentLine.SetRange("Status No.", 50030);
        PaymentLine.SetFilter("Due Date", '>%1', Today); // "Due Date > a" = futur
        PaymentLine.CalcSums("Amount (LCY)");
        exit(-PaymentLine."Amount (LCY)");
    end;

    local procedure ComputeTraiteImpayee(): Decimal
    var
        PaymentLine: Record "Payment Line";
    begin
        PaymentLine.Reset();
        PaymentLine.SetRange("Type réglement", 'ENC_TRAITE');
        PaymentLine.SetRange("Account Type", PaymentLine."Account Type"::Customer);
        PaymentLine.SetRange("Copied To No.", '');
        PaymentLine.SetFilter("Status No.", '40050|50070');
        PaymentLine.CalcSums("Amount (LCY)");
        exit(-PaymentLine."Amount (LCY)");
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
    // 5. ALERTES MAGASINS DE STOCKAGE
    // =============================================================
    // Recalcule les deux drapeaux stockes sur l'article :
    //   "Sous Min Mg Principal" : stock en Mg de stockage ET stock Mg principal < qte min
    //   "Mg STK Sans Qte Min"   : stock en Mg de stockage ET aucune qte min definie
    //
    // Le calcul passe par Inventory + "Location Filter" (cle N° article / Code magasin,
    // avec les totaux SIFT) et JAMAIS par StorageQty / MainQty : leur filtre
    // isStorageLocation / isMainLocation est un FlowField lookup sur Location, ce qui
    // interdit a SQL d'utiliser les index des ecritures article. Un filtre pose sur ces
    // champs a l'echelle de la table article fait tomber le service.
    procedure UpdateAlertesMgStk()
    var
        Item: Record Item;
        ItemAEffacer: Record Item;
        TempItemMgStk: Record Item temporary;
        TempAEffacer: Record Item temporary;
        StorageFilter: Text;
        MainFilter: Text;
        SansQteMin: Boolean;
        SousMin: Boolean;
    begin
        StorageFilter := GetLocationFilter(true);
        MainFilter := GetLocationFilter(false);

        // 1. articles ayant du stock dans les magasins de stockage
        //    (une seule requete ensembliste) + drapeau "sans qte min"
        if StorageFilter <> '' then begin
            Item.Reset();
            Item.SetRange(Type, Item.Type::Inventory);
            Item.SetRange(Blocked, false);
            Item.SetFilter("Location Filter", StorageFilter);
            Item.SetFilter(Inventory, '>0');
            if Item.FindSet() then
                repeat
                    TempItemMgStk.Init();
                    TempItemMgStk."No." := Item."No.";
                    TempItemMgStk.Insert();

                    SansQteMin := Item."Qte Min Mg Principal" = 0;
                    if Item."Mg STK Sans Qte Min" <> SansQteMin then begin
                        Item."Mg STK Sans Qte Min" := SansQteMin;
                        Item.Modify(false);
                    end;
                until Item.Next() = 0;
        end;

        // 2. articles a seuil dont le stock magasin principal est sous la qte min
        if MainFilter <> '' then begin
            Item.Reset();
            Item.SetRange(Type, Item.Type::Inventory);
            Item.SetRange(Blocked, false);
            Item.SetFilter("Qte Min Mg Principal", '>0');
            Item.SetFilter("Location Filter", MainFilter);
            Item.SetAutoCalcFields(Item.Inventory);
            if Item.FindSet() then
                repeat
                    SousMin := (Item.Inventory < Item."Qte Min Mg Principal") and
                               TempItemMgStk.Get(Item."No.");
                    if Item."Sous Min Mg Principal" <> SousMin then begin
                        Item."Sous Min Mg Principal" := SousMin;
                        Item.Modify(false);
                    end;
                until Item.Next() = 0;
        end;

        // 3. drapeaux devenus obsoletes (article sorti du perimetre des passes 1 et 2)
        //    on collecte avant d'ecrire : la boucle filtre sur le champ modifie
        TempAEffacer.Reset();
        TempAEffacer.DeleteAll();
        Item.Reset();
        Item.SetRange("Mg STK Sans Qte Min", true);
        if Item.FindSet() then
            repeat
                if (Item."Qte Min Mg Principal" <> 0) or Item.Blocked or
                   (Item.Type <> Item.Type::Inventory) or (not TempItemMgStk.Get(Item."No."))
                then begin
                    TempAEffacer.Init();
                    TempAEffacer."No." := Item."No.";
                    TempAEffacer.Insert();
                end;
            until Item.Next() = 0;
        if TempAEffacer.FindSet() then
            repeat
                if ItemAEffacer.Get(TempAEffacer."No.") then begin
                    ItemAEffacer."Mg STK Sans Qte Min" := false;
                    ItemAEffacer.Modify(false);
                end;
            until TempAEffacer.Next() = 0;

        TempAEffacer.Reset();
        TempAEffacer.DeleteAll();
        Item.Reset();
        Item.SetRange("Sous Min Mg Principal", true);
        if Item.FindSet() then
            repeat
                if (Item."Qte Min Mg Principal" <= 0) or Item.Blocked or
                   (Item.Type <> Item.Type::Inventory) or (not TempItemMgStk.Get(Item."No."))
                then begin
                    TempAEffacer.Init();
                    TempAEffacer."No." := Item."No.";
                    TempAEffacer.Insert();
                end;
            until Item.Next() = 0;
        if TempAEffacer.FindSet() then
            repeat
                if ItemAEffacer.Get(TempAEffacer."No.") then begin
                    ItemAEffacer."Sous Min Mg Principal" := false;
                    ItemAEffacer.Modify(false);
                end;
            until TempAEffacer.Next() = 0;
    end;

    // Liste des magasins a utiliser en "Location Filter" : 'MG1|MG2|...'
    local procedure GetLocationFilter(MagasinsDeStockage: Boolean): Text
    var
        Location: Record Location;
        LocFilter: Text;
    begin
        Location.Reset();
        if MagasinsDeStockage then
            Location.SetRange(isStorage, true)
        else
            Location.SetRange(isMain, true);
        if Location.FindSet() then
            repeat
                if LocFilter <> '' then
                    LocFilter += '|';
                LocFilter += Location.Code;
            until Location.Next() = 0;
        exit(LocFilter);
    end;

    procedure GetNbArtMgStkSousMin(): Integer
    var
        Item: Record Item;
    begin
        Item.Reset();
        Item.SetRange("Sous Min Mg Principal", true);
        exit(Item.Count);
    end;

    procedure GetNbArtMgStkSansQteMin(): Integer
    var
        Item: Record Item;
    begin
        Item.Reset();
        Item.SetRange("Mg STK Sans Qte Min", true);
        exit(Item.Count);
    end;

    // =============================================================
    // 6. NETTOYAGE
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