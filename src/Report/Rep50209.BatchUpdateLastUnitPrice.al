report 50209 "Batch Update Last Unit Price"
{
    UsageCategory = ReportsAndAnalysis;
    ApplicationArea = All;
    Caption = 'Mise à jour des derniers prix achat calculé en Devise société';
    Permissions = tabledata Item = rimd; // Permission pour l'utilsateur de lire / ecrire / modofier / inserer dans une table 'Artcle' dans ce cas
    ProcessingOnly = true;  // Pour dire que just c'est un traitement en arrière plan
    dataset
    {
        dataitem(Item; Item)
        {
            trigger OnPreDataItem()
            begin

            end;

            trigger OnPostDataItem()
            begin

            end;

            trigger OnAfterGetRecord()
            var
                RecPurchPrice: Record "Purchase Price";
                recVendor: Record Vendor;
                lCurrExchRate: Record "Currency Exchange Rate";
                CurrencyFactor: Decimal;
                Coefficiant: Decimal;
                LastCostDS: Decimal;

            begin
                RecPurchPrice.Reset();
                LastCostDS := 0;



                RecPurchPrice.SetCurrentKey("Starting Date");
                RecPurchPrice.SetRange(RecPurchPrice."Item No.", "No.");
                RecPurchPrice.SetFilter("Unit of Measure Code", '%1|%2', "Purch. Unit of Measure", '');
                RecPurchPrice.Setrange(RecPurchPrice."Ending Date", 0D);
                if RecPurchPrice.FindFirst() then begin
                    repeat

                        recVendor.Reset();
                        Coefficiant := 0;
                        CurrencyFactor := 0;

                        if recVendor.get(RecPurchPrice."Vendor No.") then begin
                            Coefficiant := recVendor.Coefficient;
                            if recVendor."Currency Code" <> '' then begin

                                CurrencyFactor := lCurrExchRate.ExchangeRate(Today, recVendor."Currency Code");
                                if CurrencyFactor <> 0 then
                                    CurrencyFactor := 1 / CurrencyFactor
                                else
                                    CurrencyFactor := 1;
                            end;
                            // Calcul du Dernier prix de revient en devise société
                            if (LastCostDS = 0) then begin
                                LastCostDS := RecPurchPrice."Direct Unit Cost" * Coefficiant * CurrencyFactor;

                                // Message('Alternatif 01 -> Vendeur : %1  -  Article : %2 - start date : %3 - Prix devise : %4 - Dernier cout calculé DS : %5', RecPurchPrice."Vendor No.", RecPurchPrice."Item No.", RecPurchPrice."Starting Date", RecPurchPrice."Direct Unit Cost", LastCostDS);

                            end
                            else

                                if (LastCostDS > (RecPurchPrice."Direct Unit Cost" * Coefficiant * CurrencyFactor)) then begin
                                    LastCostDS := RecPurchPrice."Direct Unit Cost" * Coefficiant * CurrencyFactor;
                                    // Message('Alternatif 02 -> Vendeur : %1  -  Article : %2 - start date : %3 - Prix devise : %4 - Dernier cout calculé DS : %5', RecPurchPrice."Vendor No.", RecPurchPrice."Item No.", RecPurchPrice."Starting Date", RecPurchPrice."Direct Unit Cost", LastCostDS);

                                end;
                        end;





                    until RecPurchPrice.Next() = 0;
                end;



                "Last. Pursh. cost DS" := LastCostDS;
                Modify();

            end;

        }
    }



    trigger OnInitReport()
    begin

    end;

    trigger OnPostReport()
    begin


    end;

    trigger OnPreReport()
    begin

    end;
}