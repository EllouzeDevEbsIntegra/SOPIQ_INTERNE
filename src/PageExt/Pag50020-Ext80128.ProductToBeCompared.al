pageextension 80128 "Product To Be Compared" extends "Product To Be Compared"//50020
{
    layout
    {
        // Add changes to page layout here
        addafter("None Treated")
        {
            field("Count Master"; "Count Master")
            {
                ApplicationArea = All;
                Caption = 'Count Master';
                Editable = false;
            }
        }
    }

    actions
    {
        modify(Post)
        {
            trigger OnBeforeAction()
            var
                recPurchHeader: Record "Purchase Header";
                recPurchLine: Record "Purchase Line";
            begin

                recPurchHeader.Reset();
                recPurchHeader.SetRange("Compare Quote No.", "Compare Quote No.");
                if recPurchHeader.FindSet then
                    repeat
                        recPurchLine.Reset();
                        recPurchLine.SetRange("Document No.", recPurchHeader."No.");
                        recPurchLine.SetFilter("asking price", '> 0');
                        recPurchLine.SetRange("negotiated price", 0);

                        if recPurchLine.FindFirst() then begin
                            //Message('Succés : %1 - %2 - %3', recPurchLine."Document No.", recPurchLine."asking price", recPurchLine."negotiated price");
                            Error('Vérifier les prix négociés dans la demande de prix %1', recPurchHeader."No.");
                        end;
                    UNTIL recPurchHeader.NEXT = 0;

            end;
        }
        addafter(Post)
        {
            action("Update last. Purch. Cost. DS")
            {
                Caption = 'Mettre à jour les derniers prix consultés en devise scoiété';
                trigger OnAction()
                var
                    recItemTobeCompared: Record "Item To Be Compared";
                    recItem: Record Item;
                    RecPurchPrice: Record "purchase price";
                    recVendor: Record Vendor;
                    lCurrExchRate: Record "Currency Exchange Rate";
                    CurrencyFactor: Decimal;
                    Coefficiant: Decimal;
                    LastCostDS: Decimal;
                begin

                    recItemTobeCompared.SetRange("Compare Quote No.", "Compare Quote No.");
                    if recItemTobeCompared.FindFirst() then begin
                        repeat
                            recItem.Reset();
                            recItem.SetRange("Reference Origine Lié", recItemTobeCompared."No.");
                            if recItem.FindFirst() then begin
                                repeat

                                    // Message('test Master : %1 - No : %2', recItem."Reference Origine Lié", recItem."No.");
                                    RecPurchPrice.Reset();
                                    LastCostDS := 0;



                                    RecPurchPrice.SetCurrentKey("Starting Date");
                                    RecPurchPrice.SetRange(RecPurchPrice."Item No.", recItem."No.");
                                    RecPurchPrice.SetFilter("Unit of Measure Code", '%1|%2', recItem."Purch. Unit of Measure", '');
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



                                    recItem."Last. Pursh. cost DS" := LastCostDS;
                                    recItem.Modify();
                                until recItem.Next() = 0;
                            end
                        until recItemTobeCompared.Next() = 0;
                    end;
                    Message('Mise à jour effectué avec succés !');
                end;

            }

            action("Update Item Count")
            {
                Caption = 'Mettre à jour le count des articles';
                trigger OnAction()
                var
                    recItem, recMaster : Record Item;
                    countMaster: Integer;
                    API: Codeunit "OEM API Integration";
                    count: Integer;
                    ItemToBeCompared: Record "Item To Be Compared";
                begin
                    if Confirm('Voulez vous vraiment mettre à jour le count des articles OEM et Master ?', false) then begin
                        ItemToBeCompared.Reset();
                        ItemToBeCompared.SetRange("Compare Quote No.", "Compare Quote No.");
                        if ItemToBeCompared.FindSet() then begin
                            repeat
                                recMaster.Reset();
                                recMaster.SetRange("No.", ItemToBeCompared."No.");
                                if recMaster.FindSet() then begin
                                    repeat
                                        countMaster := 0;
                                        recItem.Reset();
                                        recItem.SetRange(Produit, false);
                                        recItem.SetRange("Reference Origine Lié", recMaster."No.");
                                        recItem.CalcFields(isOem);
                                        recItem.SetRange(isOem, true);
                                        if recItem.FindSet() then begin
                                            repeat
                                                // Upadate count in OEM
                                                Count := API.GetOEMCount(recItem."No.");
                                                //Message('Item: %1 - Count: %2', recItem."No.", Count);
                                                recItem."Count Item Manual " := Count;
                                                recItem.Modify();

                                                countMaster := countMaster + count;
                                            until recItem.Next() = 0;
                                        end;
                                        //Message('Master Item: %1 - Count: %2', item."No.", countMaster);
                                        // Update count in Master
                                        recMaster."Count Item Manual " := countMaster;
                                        recMaster.Modify();
                                    until recMaster.Next() = 0;
                                end;

                            until ItemToBeCompared.Next() = 0;
                            Message('Mise à jour effectué avec succés !');
                        end;
                    end;

                end;

            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        CalcFields("Count Master");
    end;

}