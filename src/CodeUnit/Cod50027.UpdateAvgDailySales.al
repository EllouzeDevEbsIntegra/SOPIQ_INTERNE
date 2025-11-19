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

        // ===> LA LIGNE QUI CHANGE TOUT <===
        EndDateN := WorkDate();   // Arrête à aujourd'hui pour l'année en cours

        ItemCount := 0;
        Item.SetFilter("Total Vendu", '>0');
        if Item.FindSet(true) then
            repeat
                // Année N (2025) → du 01/01/2025 à aujourd'hui seulement
                Item."Avg Daily Sales N" := CalcAvgDailySales(Item."No.", YearN);
                Item."Days With Positive Stock N" := CountDaysWithPositiveStock(Item."No.", DMY2Date(1, 1, YearN), EndDateN);
                Item."Stock Rotation N" := CalcWeightedStockRotation(Item."No.", DMY2Date(1, 1, YearN), EndDateN);

                // Années N-1 et N-2 → année complète
                Item."Avg Daily Sales N-1" := CalcAvgDailySales(Item."No.", YearN1);
                Item."Days With Positive Stock N-1" := CountDaysWithPositiveStock(Item."No.", DMY2Date(1, 1, YearN1), DMY2Date(31, 12, YearN1));
                Item."Stock Rotation N-1" := CalcWeightedStockRotation(Item."No.", DMY2Date(1, 1, YearN1), DMY2Date(31, 12, YearN1));

                Item."Avg Daily Sales N-2" := CalcAvgDailySales(Item."No.", YearN2);
                Item."Days With Positive Stock N-2" := CountDaysWithPositiveStock(Item."No.", DMY2Date(1, 1, YearN2), DMY2Date(31, 12, YearN2));
                Item."Stock Rotation N-2" := CalcWeightedStockRotation(Item."No.", DMY2Date(1, 1, YearN2), DMY2Date(31, 12, YearN2));
                Item.Version := 'v2.1';
                Item.Modify();
                ItemCount += 1;
            until Item.Next() = 0;
    end;

    local procedure CalcAvgDailySales(ItemNo: Code[20]; Year: Integer): Decimal
    var
        TotalSold: Decimal;
        DaysWithStock: Integer;
        StartDate, EndDate : Date;
    begin
        if Year = 0 then exit(0);

        StartDate := DMY2Date(1, 1, Year);
        EndDate := DMY2Date(31, 12, Year);

        TotalSold := GetTotalSoldInPeriod(ItemNo, StartDate, EndDate);
        DaysWithStock := CountDaysWithPositiveStock(ItemNo, StartDate, EndDate);

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
        ItemLedgEntry: Record "Item Ledger Entry";
        TempDate: Date;
        DailyStock: Decimal;
        DaysCount: Integer;
    begin
        DaysCount := 0;

        // Boucle sur chaque jour de la période
        TempDate := FromDate;
        while TempDate <= ToDate do begin
            // Calcule le stock disponible à la fin de la journée (avant minuit)
            DailyStock := GetAvailableStockAsOfDate(ItemNo, TempDate);

            if DailyStock > 0 then
                DaysCount += 1;

            TempDate := TempDate + 1;  // Jour suivant
        end;

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
        TotalSold: Decimal;
        AvgStock: Decimal;
        StockStart, StockEnd : Decimal;
    begin
        // Total des ventes sur la période
        TotalSold := GetTotalSoldInPeriod(ItemNo, FromDate, ToDate);

        // Stock moyen : (Stock début + Stock fin) / 2
        StockStart := GetAvailableStockAsOfDate(ItemNo, FromDate - 1);
        StockEnd := GetAvailableStockAsOfDate(ItemNo, ToDate);
        AvgStock := (StockStart + StockEnd) / 2;

        // Rotation = Total Vendu / Stock Moyen
        if AvgStock > 0 then
            exit(Round(TotalSold / AvgStock, 0.01))
        else
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
        DaysAtLevel := 0;

        ItemLedgEntry.SetCurrentKey("Item No.", "Posting Date");
        ItemLedgEntry.SetRange("Item No.", ItemNo);
        ItemLedgEntry.SetRange("Posting Date", FromDate, ToDate);
        ItemLedgEntry.SetRange(isLocationExclu, false);

        if ItemLedgEntry.FindSet() then
            repeat
                if ItemLedgEntry."Posting Date" <> PrevDate then begin
                    // Ajouter les jours au niveau précédent
                    WeightedStockSum += CurrentStock * DaysAtLevel;
                    DaysAtLevel := ItemLedgEntry."Posting Date" - PrevDate;
                    PrevDate := ItemLedgEntry."Posting Date";
                end;
                CurrentStock += ItemLedgEntry.Quantity;
            until ItemLedgEntry.Next() = 0;

        // Dernière période
        DaysAtLevel := ToDate - PrevDate + 1;
        WeightedStockSum += CurrentStock * DaysAtLevel;

        // Stock moyen pondéré
        if DaysInPeriod > 0 then begin
            CurrentStock := WeightedStockSum / DaysInPeriod;
            if CurrentStock > 0 then
                exit(Round(TotalSold / CurrentStock, 0.01));
        end;

        exit(0);
    end;

}
