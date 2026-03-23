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
        ItemLedgEntry: Record "Item Ledger Entry";
        ItemDailyStats: Record "Item Daily Stats";
        ProcessedCount: Integer;
        ItemBatchSize: Integer;
        StatInsertBatchSize: Integer;
        TotalStatsInserted: Integer;
        CurrentDate: Date;
        StockLevel: Decimal;
        DailyNetChange: Decimal;
        DailySoldQty: Decimal;
        Window: Dialog;
    begin
        ItemBatchSize := 100; // Commit tous les 100 articles
        StatInsertBatchSize := 5000; // Commit toutes les 5000 statistiques insérées pour éviter les transactions trop longues
        ProcessedCount := 0;

        // Supprimer les données existantes pour la période
        ItemDailyStats.SetRange(Date, FromDate, ToDate);
        if not ItemDailyStats.IsEmpty() then
            ItemDailyStats.DeleteAll(true);

        // Traiter uniquement les articles ayant eu des ventes
        Item.SetFilter("Total Vendu", '>0');
        Item.SetCurrentKey("No.");

        if Item.FindSet() then begin
            Window.Open('Traitement des articles... Article #1##################');
            repeat
                Window.Update(1, Item."No.");

                // 1. Calculer le stock initial juste avant la période de début
                StockLevel := GetStockAsOfDate(Item."No.", FromDate - 1);

                CurrentDate := FromDate;
                while CurrentDate <= ToDate do begin
                    // 2. Obtenir les mouvements de la journée
                    ItemLedgEntry.Reset();
                    ItemLedgEntry.SetCurrentKey("Item No.", "Posting Date");
                    ItemLedgEntry.SetRange("Item No.", Item."No.");
                    ItemLedgEntry.SetRange("Posting Date", CurrentDate);
                    ItemLedgEntry.SetRange(isLocationExclu, false);

                    // 3. Calculer le changement net et les ventes du jour
                    DailyNetChange := 0;
                    DailySoldQty := 0;
                    if ItemLedgEntry.CalcSums(Quantity) then begin
                        DailyNetChange := ItemLedgEntry.Quantity;
                        ItemLedgEntry.SetRange("Entry Type", ItemLedgEntry."Entry Type"::Sale);
                        if ItemLedgEntry.CalcSums(Quantity) then
                            DailySoldQty := -ItemLedgEntry.Quantity;
                    end;

                    // 4. Mettre à jour le niveau de stock de manière incrémentale
                    StockLevel += DailyNetChange;

                    // 5. Insérer la statistique du jour
                    InsertDailyStat(Item."No.", CurrentDate, DailySoldQty, StockLevel);

                    TotalStatsInserted += 1;
                    // Commit partiel à l'intérieur de la boucle de date pour éviter les transactions trop longues
                    if TotalStatsInserted mod StatInsertBatchSize = 0 then begin
                        Commit();
                        Sleep(50); // Petite pause pour laisser les autres processus s'exécuter
                    end;

                    CurrentDate := CalcDate('<1D>', CurrentDate);
                end;

                ProcessedCount += 1;
                if ProcessedCount mod ItemBatchSize = 0 then begin
                    Commit();
                    Sleep(100); // Petite pause
                end;

            until Item.Next() = 0;
        end;
        Commit();
        Window.Close();
    end;

    local procedure InsertDailyStat(ItemNo: Code[20]; StatDate: Date; TotalSold: Decimal; StockLevel: Decimal)
    var
        ItemDailyStats: Record "Item Daily Stats";
    begin
        ItemDailyStats.Init();
        ItemDailyStats."Item No." := ItemNo;
        ItemDailyStats.Date := StatDate;
        ItemDailyStats."Total Sold" := TotalSold;
        ItemDailyStats."Stock Level" := StockLevel;
        ItemDailyStats."Has Positive Stock" := StockLevel > 0;
        ItemDailyStats.Year := Date2DMY(StatDate, 3);
        ItemDailyStats.Month := Date2DMY(StatDate, 2);

        ItemDailyStats.Insert();
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
