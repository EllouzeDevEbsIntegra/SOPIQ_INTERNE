pageextension 80128 "Product To Be Compared" extends "Product To Be Compared"//50020
{
    layout
    {
        // Add changes to page layout here
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
    }

    var
        myInt: Integer;

    trigger OnAfterGetRecord()

    var
        lItem: Record Item;
        lPurchasePrice: Record "purchase price";
        Vendor: Record Vendor;
        lCurrExchRate: Record "Currency Exchange Rate";
        CurrencyFactor: Decimal;
        Coefficiant: Decimal;
        LastCostDS: Decimal;
        lastDevisePrice: Decimal;
        test: Text[50];

    begin
        lItem.SetRange("Reference Origine Lié", "No.");
        if lItem.FindFirst() then begin
            repeat
                lastDevisePrice := 0;
                LastCostDS := 0;
                CurrencyFactor := 0;
                Coefficiant := 0;
                lPurchasePrice.Reset();

                // récupérer dernier prix en devise 
                lPurchasePrice.SetCurrentKey("Starting Date");
                lPurchasePrice.SetRange("Vendor No.", lItem."Vendor No.");
                lPurchasePrice.SetRange("Item No.", lItem."No.");
                lPurchasePrice.SetFilter("Unit of Measure Code", '%1|%2', lItem."Purch. Unit of Measure", '');
                if lPurchasePrice.FindLast() then begin
                    lastDevisePrice := lPurchasePrice."Direct Unit Cost";
                end;

                //Mise à jour du champ dernier prix de revient en devise société calculé dans la fiche article
                if Vendor.get(lItem."Vendor No.") then
                    Coefficiant := Vendor.Coefficient;

                // Calcul du Dernier prix de revient en devise société
                if Vendor."Currency Code" <> '' then begin

                    CurrencyFactor := lCurrExchRate.ExchangeRate(Today, Vendor."Currency Code");
                    if CurrencyFactor <> 0 then
                        CurrencyFactor := 1 / CurrencyFactor
                    else
                        CurrencyFactor := 1;

                    LastCostDS := lastDevisePrice * Coefficiant * CurrencyFactor;
                end
                else
                    LastCostDS := lastDevisePrice * Coefficiant * CurrencyFactor;

                lItem."Last. Pursh. cost DS" := LastCostDS;
                lItem.Modify();
            until lItem.Next() = 0;
        end

    end;

}