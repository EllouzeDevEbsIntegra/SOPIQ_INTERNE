codeunit 50027 "Update Avg Daily Sales"
{
    trigger OnRun()
    begin
        UpdateAllItems();
        Message('Mise à jour terminée : %1 articles traités.', ItemCount);
    end;

    var
        ItemCount: Integer;

    local procedure UpdateAllItems()
    var
        Item: Record Item;
        PurchPaySetup: Record "Purchases & Payables Setup";
        YearN, YearN1, YearN2 : Integer;
        EndDateN: Date;
    begin
        PurchPaySetup.Get();
        YearN := PurchPaySetup."Current Year";
        YearN1 := PurchPaySetup."Last Year";
        YearN2 := PurchPaySetup."Last Year-1";

        EndDateN := WorkDate();
        ItemCount := 0;

        Item.SetFilter("Total Vendu", '>0');
        Item.SetCurrentKey("No.");

        if Item.FindSet(true) then
            repeat
                // Année N (2025) → du 01/01/2025 à aujourd'hui seulement
                Item."Avg Daily Sales N" := CalcAvgDailySales(Item."No.", YearN);
                Item."Days With Positive Stock N" := CountDaysWithPositiveStock(Item."No.", DMY2Date(1, 1, YearN), EndDateN);
                Item."Stock Rotation N" := CalcStockRotation(Item."No.", DMY2Date(1, 1, YearN), EndDateN);

                // Années N-1 et N-2 → année complète
                Item."Avg Daily Sales N-1" := CalcAvgDailySales(Item."No.", YearN1);
                Item."Days With Positive Stock N-1" := CountDaysWithPositiveStock(Item."No.", DMY2Date(1, 1, YearN1), DMY2Date(31, 12, YearN1));
                Item."Stock Rotation N-1" := CalcStockRotation(Item."No.", DMY2Date(1, 1, YearN1), DMY2Date(31, 12, YearN1));

                Item."Avg Daily Sales N-2" := CalcAvgDailySales(Item."No.", YearN2);
                Item."Days With Positive Stock N-2" := CountDaysWithPositiveStock(Item."No.", DMY2Date(1, 1, YearN2), DMY2Date(31, 12, YearN2));
                Item."Stock Rotation N-2" := CalcStockRotation(Item."No.", DMY2Date(1, 1, YearN2), DMY2Date(31, 12, YearN2));

                Item.Version := 'v3.0';
                Item.Modify();
                ItemCount += 1;

            until Item.Next() = 0;
    end;

    local procedure CalcAvgDailySales(ItemNo: Code[20]; Year: Integer): Decimal
    var
        ItemDailyStats: Record 25006658;
        TotalSold: Decimal;
        DaysWithStock: Integer;
    begin
        if Year = 0 then exit(0);

        // Utiliser la table pré-calculée pour les performances
        ItemDailyStats.SetRange("Item No.", ItemNo);
        ItemDailyStats.SetRange(Year, Year);
        ItemDailyStats.SetRange("Has Positive Stock", true);

        DaysWithStock := ItemDailyStats.Count;

        ItemDailyStats.SetRange("Has Positive Stock");
        if ItemDailyStats.FindSet() then begin
            repeat
                TotalSold += ItemDailyStats."Total Sold";
            until ItemDailyStats.Next() = 0;
        end;

        if (DaysWithStock > 0) and (TotalSold > 0) then
            exit(Round(TotalSold / DaysWithStock, 0.0001));

        exit(0);
    end;

    local procedure GetTotalSoldInPeriod(ItemNo: Code[20]; FromDate: Date; ToDate: Date): Decimal
    var
        ItemLedgEntry: Record "Item Ledger Entry";
    begin
        ItemLedgEntry.SetRange("Item No.", ItemNo);
        ItemLedgEntry.SetRange("Posting Date", FromDate, ToDate);
        ItemLedgEntry.SetRange("Entry Type", ItemLedgEntry."Entry Type"::Sale);
        if ItemLedgEntry.FindSet() then begin
            ItemLedgEntry.CalcSums(Quantity);
            exit(-ItemLedgEntry.Quantity);
        end;
        exit(0);
    end;

    local procedure CountDaysWithPositiveStock(ItemNo: Code[20]; FromDate: Date; ToDate: Date): Integer
    var
        ItemDailyStats: Record 25006658;
        DaysCount: Integer;
    begin
        // Utiliser la table pré-calculée pour les performances
        ItemDailyStats.SetRange("Item No.", ItemNo);
        ItemDailyStats.SetRange(Date, FromDate, ToDate);
        ItemDailyStats.SetRange("Has Positive Stock", true);

        DaysCount := ItemDailyStats.Count;

        exit(DaysCount);
    end;


    local procedure GetAvailableStockAsOfDate(ItemNo: Code[20]; AsOfDate: Date): Decimal
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        AvailableStock: Decimal;
    begin
        if AsOfDate = 0D then exit(0);

        AvailableStock := 0;

        ItemLedgEntry.SetCurrentKey("Item No.", "Posting Date");
        ItemLedgEntry.SetRange("Item No.", ItemNo);
        ItemLedgEntry.SetFilter("Posting Date", '..%1', AsOfDate);
        ItemLedgEntry.SetRange(isLocationExclu, false);  // Exclut les locations marquées

        if ItemLedgEntry.FindSet() then begin
            ItemLedgEntry.CalcSums(Quantity);
            AvailableStock := ItemLedgEntry.Quantity;
        end;

        exit(AvailableStock);
    end;

    procedure CalcStockRotation(ItemNo: Code[20]; FromDate: Date; ToDate: Date): Decimal
    var
        ItemDailyStats: Record 25006658;
        TotalSold: Decimal;
        TotalStock: Decimal;
        DaysCount: Integer;
    begin
        // Utiliser la table pré-calculée pour les performances
        ItemDailyStats.SetRange("Item No.", ItemNo);
        ItemDailyStats.SetRange(Date, FromDate, ToDate);

        if ItemDailyStats.FindSet() then begin
            repeat
                TotalSold += ItemDailyStats."Total Sold";
                TotalStock += ItemDailyStats."Stock Level";
                DaysCount += 1;
            until ItemDailyStats.Next() = 0;
        end;

        // Stock moyen pondéré
        if DaysCount > 0 then begin
            TotalStock := TotalStock / DaysCount;
            if TotalStock > 0 then
                exit(Round(TotalSold / TotalStock, 0.01))
            else
                exit(0);
        end;

        exit(0);
    end;

    procedure CalcWeightedStockRotation(ItemNo: Code[20]; FromDate: Date; ToDate: Date): Decimal
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        TotalSold: Decimal;
        WeightedStockSum: Decimal;
        DaysInPeriod: Integer;
        CurrentStock: Decimal;
        PrevDate: Date;
        DaysAtLevel: Integer;
    begin
        // Total des ventes
        TotalSold := GetTotalSoldInPeriod(ItemNo, FromDate, ToDate);

        // Calcul pondéré du stock moyen
        CurrentStock := GetAvailableStockAsOfDate(ItemNo, FromDate - 1);
        WeightedStockSum := 0;
        DaysInPeriod := ToDate - FromDate + 1;
        PrevDate := FromDate;

        ItemLedgEntry.SetCurrentKey("Item No.", "Posting Date");
        ItemLedgEntry.SetRange("Item No.", ItemNo);
        ItemLedgEntry.SetRange("Posting Date", FromDate, ToDate);
        ItemLedgEntry.SetRange(isLocationExclu, false);

        if ItemLedgEntry.FindSet() then
            repeat
                DaysAtLevel := ItemLedgEntry."Posting Date" - PrevDate;
                WeightedStockSum += Abs(CurrentStock) * DaysAtLevel;
                CurrentStock += ItemLedgEntry.Quantity;
                PrevDate := ItemLedgEntry."Posting Date";
            until ItemLedgEntry.Next() = 0;

        // Dernière période
        DaysAtLevel := ToDate - PrevDate + 1;
        WeightedStockSum += Abs(CurrentStock) * DaysAtLevel;

        // Stock moyen pondéré
        if DaysInPeriod > 0 then begin
            CurrentStock := WeightedStockSum / DaysInPeriod;
            if CurrentStock > 0 then
                exit(Round(TotalSold / CurrentStock, 0.01))
            else
                exit(0);
        end;

        exit(0);
    end;

}
