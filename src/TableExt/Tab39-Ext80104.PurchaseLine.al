tableextension 80104 "Purchase Line" extends "Purchase Line" //39
{
    fields
    {
        modify("No.")
        {
            trigger OnAfterValidate()
            var
                recItem: Record Item;
            begin
                if recItem.Get("No.") then Marge := recItem."Profit %";
            end;
        }


        field(80104; "asking price"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'Prix demandé';

            trigger OnValidate()
            begin


            end;

        }
        field(80103; "asking qty"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'Qté demandé';
            DecimalPlaces = 0 : 5;

        }

        field(80110; "negotiated price"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'Prix négocié';
            trigger OnValidate()
            begin
                if ("negotiated price" > 0) then begin

                    "Direct Unit Cost" := "negotiated price";
                    "Unit Cost" := "negotiated price";
                    Modify();
                end
            end;
        }

        field(80111; "negotiated qty"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'Qté négocié';
            DecimalPlaces = 0 : 5;
            trigger OnValidate()
            begin
                if ("negotiated qty" > 0) then begin

                    Quantity := "negotiated qty";
                    "Outstanding Quantity" := "negotiated qty";
                    "Quantity (Base)" := "negotiated qty";
                    "Outstanding Qty. (Base)" := "negotiated qty";
                    Modify();
                end
            end;
        }

        modify("Vendor Unit Cost")
        {
            trigger OnAfterValidate()
            var
                recItemVendor: Record "Item Vendor";
                recPurchasePrice: Record "Purchase Price";
                recPurchasePriceInsert: Record "Purchase Price";

            begin
                // recItemVendor.Reset();
                // recItemVendor.SetRange("Item No.", "No.");
                // recItemVendor.SetRange("Vendor No.", "Buy-from Vendor No.");
                // if recItemVendor.FindFirst() then begin
                //     recItemVendor."Last. Preferentiel" := Preferential;
                //     recItemVendor.Modify();
                // end;

                recPurchasePrice.SetRange("Vendor No.", "Buy-from Vendor No.");
                recPurchasePrice.SetRange("Item No.", "No.");
                recPurchasePrice.SetRange("Ending Date", 0D);
                if recPurchasePrice.FindFirst() then begin
                    repeat
                        if (recPurchasePrice."Starting Date" = Today) then begin
                            recPurchasePrice."Direct Unit Cost" := "Vendor Unit Cost";
                            recPurchasePrice.Modify();
                        end;


                    until recPurchasePrice.Next() = 0;
                end;

            end;

        }

        modify(Preferential)
        {
            trigger OnAfterValidate()
            var
                recItem: Record Item;
            begin
                recItem.Reset();
                recItem.SetRange("No.", "No.");
                if recItem.FindFirst() then begin
                    recItem."Last. Preferential" := Preferential;
                    recItem.Modify();
                end;
            end;
        }


        field(80105; "Marge"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'Marge à définir';
            Editable = true;
        }

    }

    var
        myInt: Integer;

    trigger OnAfterInsert()
    var
        recVendor: Record Vendor;
        recCurrExchRate: Record "Currency Exchange Rate";
        CurrencyFactor: Decimal;
        Coefficiant: Decimal;
        LastCostDS: Decimal;
    begin

        // CurrencyFactor := 0;
        // Coefficiant := 0;
        // recVendor.Reset();

        // if recVendor.get("Buy-from Vendor No.") then
        //     Coefficiant := recVendor.Coefficient;

        // // Calcul du Dernier prix de revient en devise société
        // if recVendor."Currency Code" <> '' then begin

        //     CurrencyFactor := recCurrExchRate.ExchangeRate(Today, recVendor."Currency Code");
        //     if CurrencyFactor <> 0 then
        //         CurrencyFactor := 1 / CurrencyFactor
        //     else
        //         CurrencyFactor := 1;

        // end;

        //LastCostDS := lastDevisePrice * Coefficiant * CurrencyFactor;

        // else
        //                             if (recPurchasePrice."Ending Date" = 0D) then begin
        //                                 // MAJ la date fin
        //                                 recPurchasePrice."Ending Date" := CalcDate('<CD-1D>');
        //                                 recPurchasePrice.Modify();

        //                                 // Insertion du nouvelle ligne
        //                                 recPurchasePriceInsert."Vendor No." := "Buy-from Vendor No.";
        //                                 recPurchasePriceInsert."Item No." := "No.";
        //                                 recPurchasePriceInsert."Direct Unit Cost" := "Vendor Unit Cost";
        //                                 recPurchasePriceInsert."Starting Date" := Today;
        //                                 recPurchasePrice."Currency Code" := recVendor."Currency Code";
        //                                 recPurchasePrice."Last. Price DS" := "Vendor Unit Cost" * Coefficiant * CurrencyFactor;


        //                                 Message('%1 - %2 - %3 - %4 - %5 - %6 - %7', recPurchasePriceInsert."Vendor No.", recPurchasePriceInsert."Item No.", recPurchasePriceInsert."Direct Unit Cost", recPurchasePriceInsert."Starting Date", "Currency Code", recPurchasePrice."Currency Code", recPurchasePrice."Last. Price DS");
        //                                 if recPurchasePriceInsert.Insert() then begin

        //                                     // recPurchasePriceInsert."Currency Code" := "Currency Code";
        //                                     // recPurchasePriceInsert.Modify();
        //                                     message('Succés %1', recPurchasePriceInsert."Currency Code");

        //                                 end

        //                                 else
        //                                     message('Failed');


        //                             end
    end;

}