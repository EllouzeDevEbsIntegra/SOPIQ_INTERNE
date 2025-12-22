codeunit 50028 "Populate Item Daily Stats"
{
    Permissions = tabledata 25006658 = rimd,
                  tabledata Item = r,
                  tabledata "Item Ledger Entry" = r;

    // Permissions élevées pour tous les utilisateurs
    Access = Public;

    trigger OnRun()
    begin
        // Alimenter depuis le 31/12/2022 jusqu'à aujourd'hui
        PopulateDailyStats(DMY2Date(31, 12, 2022), WorkDate());
        Message('Alimentation terminée.');
    end;

    procedure PopulateDailyStats(FromDate: Date; ToDate: Date)
    var
        Item: Record Item;
        CurrentDate: Date;
        ItemDailyStats: Record "Item Daily Stats";
        ProcessedCount: Integer;
        BatchSize: Integer;
    begin
        BatchSize := 100; // Traiter par lots pour éviter les blocages
        ProcessedCount := 0;

        // Supprimer les données existantes pour la période (optionnel)
        ItemDailyStats.SetRange(Date, FromDate, ToDate);
        ItemDailyStats.DeleteAll();

        // Traiter uniquement les articles ayant eu des ventes
        Item.SetFilter("Total Vendu", '>0');
        Item.SetCurrentKey("No.");

        if Item.FindSet() then
            repeat
                CurrentDate := FromDate;
                while CurrentDate <= ToDate do begin
                    InsertDailyStat(Item."No.", CurrentDate);
                    CurrentDate := CurrentDate + 1;
                end;

                ProcessedCount += 1;

                // Commit tous les 100 articles
                if ProcessedCount mod BatchSize = 0 then begin
                    Commit();
                    Sleep(100); // Petite pause
                end;

            until Item.Next() = 0;

        Commit();
    end;

    local procedure InsertDailyStat(ItemNo: Code[20]; StatDate: Date)
    var
        ItemDailyStats: Record 25006658;
        TotalSold: Decimal;
        StockLevel: Decimal;
    begin
        // Calculer le total vendu pour la journée
        TotalSold := GetTotalSoldOnDate(ItemNo, StatDate);

        // Calculer le niveau de stock à la fin de la journée
        StockLevel := GetStockAsOfDate(ItemNo, StatDate);

        // Insérer ou mettre à jour l'enregistrement
        ItemDailyStats.Init();
        ItemDailyStats."Item No." := ItemNo;
        ItemDailyStats.Date := StatDate;
        ItemDailyStats."Total Sold" := TotalSold;
        ItemDailyStats."Stock Level" := StockLevel;
        ItemDailyStats."Has Positive Stock" := StockLevel > 0;
        ItemDailyStats.Year := Date2DMY(StatDate, 3);
        ItemDailyStats.Month := Date2DMY(StatDate, 2);

        if not ItemDailyStats.Insert() then
            ItemDailyStats.Modify();
    end;

    local procedure GetTotalSoldOnDate(ItemNo: Code[20]; OnDate: Date): Decimal
    var
        ItemLedgEntry: Record "Item Ledger Entry";
    begin
        ItemLedgEntry.SetRange("Item No.", ItemNo);
        ItemLedgEntry.SetRange("Posting Date", OnDate);
        ItemLedgEntry.SetRange("Entry Type", ItemLedgEntry."Entry Type"::Sale);
        ItemLedgEntry.SetRange(isLocationExclu, false);

        if ItemLedgEntry.FindSet() then begin
            ItemLedgEntry.CalcSums(Quantity);
            exit(-ItemLedgEntry.Quantity); // Les ventes sont négatives
        end;

        exit(0);
    end;

    local procedure GetStockAsOfDate(ItemNo: Code[20]; AsOfDate: Date): Decimal
    var
        ItemLedgEntry: Record "Item Ledger Entry";
    begin
        if AsOfDate = 0D then exit(0);

        ItemLedgEntry.SetRange("Item No.", ItemNo);
        ItemLedgEntry.SetFilter("Posting Date", '..%1', AsOfDate);
        ItemLedgEntry.SetRange(isLocationExclu, false);

        if ItemLedgEntry.FindSet() then begin
            ItemLedgEntry.CalcSums(Quantity);
            exit(ItemLedgEntry.Quantity);
        end;

        exit(0);
    end;
}
