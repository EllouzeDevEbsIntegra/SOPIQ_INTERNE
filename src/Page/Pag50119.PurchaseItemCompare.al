page 50119 PurchaseItemCompare
{
    PageType = List;
    SourceTable = "Purchase Price";
    Caption = 'Comparateur de prix d''achat fournisseurs';
    SourceTableView = where("Ending Date" = FILTER(''));


    layout
    {
        area(Content)
        {
            // group(General)
            // {
            //     field(VendNoFilterCtrl; VendNoFilter)
            //     {
            //         ApplicationArea = Basic, Suite;
            //         Caption = 'Vendor No. Filter';
            //         ToolTip = 'Specifies a filter for which purchase prices display.';

            //         trigger OnLookup(var Text: Text): Boolean
            //         var
            //             VendList: Page "Vendor List";
            //         begin
            //             VendList.LookupMode := true;
            //             if VendList.RunModal = ACTION::LookupOK then
            //                 Text := VendList.GetSelectionFilter
            //             else
            //                 exit(false);

            //             exit(true);
            //         end;

            //         trigger OnValidate()
            //         begin
            //             VendNoFilterOnAfterValidate;
            //         end;
            //     }

            //     field(StartingDateFilter; StartingDateFilter)
            //     {
            //         ApplicationArea = Basic, Suite;
            //         Caption = 'Starting Date Filter';
            //         ToolTip = 'Specifies a filter for which purchase prices to display.';

            //         trigger OnValidate()
            //         var
            //             FilterTokens: Codeunit "Filter Tokens";
            //         begin
            //             FilterTokens.MakeDateFilter(StartingDateFilter);
            //             StartingDateFilterOnAfterValid;
            //         end;
            //     }

            // }
            repeater(Control1)
            {
                ShowCaption = false;
                field(frs; frs)
                {
                    caption = 'Frs';

                }
                field("No."; "No.")
                {

                }

                field(Description; Description)
                {

                }

                field(Famille; Famille)
                {

                }

                field("Sous Famille"; "Sous Famille")
                {

                }

                field("Frs 1 Sales Qty Y"; ItemStk2."Sales Qty 'Year'")
                {

                }
                field("Frs 1 Sales Qty Y-1"; ItemStk2."Sales Qty 'Year-1'")
                {

                }

                field("Item PU Devise"; "Last Curr. Price.")
                {

                }

                field("Item Last Date"; "Last Date")
                {

                }
                field("Vendor No."; "Vendor No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("item No."; "item No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Frs 2 Sales Qty Y"; ItemStk."Sales Qty 'Year'")
                {

                }
                field("Frs 2 Sales Qty Y-1"; ItemStk."Sales Qty 'Year-1'")
                {

                }
                field("Direct Unit Cost"; "Direct Unit Cost")
                {

                }
                field("Last Date"; "Starting Date")
                {

                }

                field(master; master)
                {

                }





            }
        }

    }

    actions
    {
        area(Processing)
        {
            action("Verif Filtre")
            {
                ApplicationArea = All;

                trigger OnAction();
                begin
                    // if ItemStk.get("Item No.") Then begin
                    //     ItemStk.SetFilter("Date filter 'Year'", '010123..311223');
                    //     ItemStk.SetFilter("Date filter 'Year-1'", '010122..311222');
                    //     Message('%1 - %2 - %3 - %4', "Item No.", ItemStk."No.", ItemStk."Date filter 'Year'", ItemStk."Date filter 'Year-1'");
                    // end;
                end;
            }
        }
    }

    trigger OnAfterGetRecord()

    begin
        // CurrYearStartingDate := 01/01/23;
        // if ItemStk.get("Item No.") Then begin
        //     ItemStk.SetFilter("Date filter 'Year'", '010123..311223');
        //     ItemStk.SetFilter("Date filter 'Year-1'", '010122..311222');
        //     ItemStk.CalcFields("Sales Qty 'Year'", "Sales Qty 'Year-1'");

        // end;

        // if ItemStk2.get("No.") then
        //     ItemStk2.SetFilter("Date filter 'Year'", '010123..311223');
        // ItemStk2.SetFilter("Date filter 'Year-1'", '010122..311222');
        // ItemStk2.CalcFields("Sales Qty 'Year'", "Sales Qty 'Year-1'");
    end;

    var
        ItemStk, ItemStk2 : Record Item;
        CurrYearStartingDate, CurrYearEndingDate, LastYearStartingDate, LastYearEndingDate : Date;

    // trigger OnOpenPage()
    // begin
    //     GetRecFilters;
    //     SetRecFilters;
    //     IsLookupMode := CurrPage.LookupMode;
    // end;

    // var
    //     Vend: Record Vendor;
    //     VendNoFilter: Text;
    //     StartingDateFilter: Text[30];
    //     NoDataWithinFilterErr: Label 'There is no %1 within the filter %2.', Comment = '%1: Field(Code), %2: GetFilter(Code)';
    //     IsLookupMode: Boolean;
    //     MultipleVendorsSelectedErr: Label 'More than one vendor uses these purchase prices. To copy prices, the Vendor No. Filter field must contain one vendor only.';

    // local procedure GetRecFilters()
    // begin
    //     if GetFilters <> '' then begin
    //         VendNoFilter := GetFilter("frs");
    //         Evaluate(StartingDateFilter, GetFilter("Starting Date"));
    //     end;
    // end;

    // procedure SetRecFilters()
    // begin
    //     if VendNoFilter <> '' then
    //         SetFilter("frs", VendNoFilter)
    //     else
    //         SetRange("frs");

    //     if StartingDateFilter <> '' then
    //         SetFilter("Starting Date", StartingDateFilter)
    //     else
    //         SetRange("Starting Date");


    //     CheckFilters(DATABASE::Vendor, VendNoFilter);

    //     CurrPage.Update(false);
    // end;



    // local procedure VendNoFilterOnAfterValidate()
    // var
    //     Item: Record Item;
    // begin
    //     if Item.Get("item No.") then
    //         CurrPage.SaveRecord;
    //     SetRecFilters;
    // end;

    // local procedure StartingDateFilterOnAfterValid()
    // begin
    //     CurrPage.SaveRecord;
    //     SetRecFilters;
    // end;

    // local procedure ItemNoFilterOnAfterValidate()
    // begin
    //     CurrPage.SaveRecord;
    //     SetRecFilters;
    // end;

    // procedure CheckFilters(TableNo: Integer; FilterTxt: Text)
    // var
    //     FilterRecordRef: RecordRef;
    //     FilterFieldRef: FieldRef;
    // begin
    //     if FilterTxt = '' then
    //         exit;
    //     Clear(FilterRecordRef);
    //     Clear(FilterFieldRef);
    //     FilterRecordRef.Open(TableNo);
    //     FilterFieldRef := FilterRecordRef.Field(1);
    //     FilterFieldRef.SetFilter(FilterTxt);
    //     if FilterRecordRef.IsEmpty then
    //         Error(NoDataWithinFilterErr, FilterRecordRef.Caption, FilterTxt);
    // end;



    // procedure GetSelectionFilter(var PurchasePrice: Record "Purchase Price")
    // begin
    //     CurrPage.SetSelectionFilter(PurchasePrice);
    // end;

}