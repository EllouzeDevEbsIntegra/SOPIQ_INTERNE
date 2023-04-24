report 50208 "Batch Update Item Class"
{
    UsageCategory = ReportsAndAnalysis;
    ApplicationArea = All;
    Caption = 'Mise à jour des classes articles';
    Permissions = tabledata Item = rimd, tabledata "Sales Price" = rimd;  // Permission pour l'utilsateur de lire / ecrire / modofier / inserer dans une table 'Artcle' dans ce cas
    ProcessingOnly = true;  // Pour dire que just c'est un traitement en arrière plan

    dataset
    {
        dataitem(Item; Item)
        {
            trigger OnPreDataItem()
            begin

            end;

            trigger OnPostDataItem()
            var
            // recItem: Record Item;
            // recCustomer: Record Customer;
            // recProfitAdd: Record "Customer Additional Profit";
            // recSalesPrice: Record "Sales Price";
            begin
                // recProfitAdd.Reset();
                // recProfitAdd.SetRange(Type, recProfitAdd.Type::"Marge Additionnelle");
                // if recProfitAdd.FindSet() then begin
                //     repeat
                //         Message('%1', recProfitAdd.Type);
                //         recItem.Reset();
                //         recItem.SetRange("Manufacturer Code", recProfitAdd."Item Manufacturer");
                //         recItem.CalcFields(StockQty);
                //         recItem.SetRange("No.", '0001802609');
                //         if (recProfitAdd."Item Group" <> 'PR') then recItem.SetRange("Item Product Code", recProfitAdd."Item Group");
                //         if recItem.FindSet() then begin
                //             repeat
                //                 Message('%1', recItem."No.");
                //                 recSalesPrice.Reset();
                //                 recSalesPrice.SetRange("Sales Type", recSalesPrice."Sales Type"::Customer);
                //                 recSalesPrice.SetRange("Sales Code", recProfitAdd.Customers);
                //                 recSalesPrice.SetRange("Item No.", recItem."No.");
                //                 if recSalesPrice.FindSet() then begin
                //                     repeat
                //                         Message('supression');
                //                         recSalesPrice.Delete();
                //                     until recSalesPrice.Next = 0;
                //                 end;

                //                 recSalesPrice.Init();
                //                 recSalesPrice."Sales Type" := recSalesPrice."Sales Type"::Customer;
                //                 recSalesPrice."Sales Code" := recProfitAdd.Customers;
                //                 recSalesPrice."Item No." := recItem."No.";
                //                 recSalesPrice."Starting Date" := Today;
                //                 recSalesPrice."Unit Price" := recItem."Unit Price" * (1 + recProfitAdd.Taux / 100);
                //                 recSalesPrice."Minimum Quantity" := 1;
                //                 recSalesPrice."Unit of Measure Code" := recItem."Sales Unit of Measure";
                //                 Message('%1 - %2', recItem."No.", recItem.StockQty);
                //                 if (recItem.StockQty > 0)
                //                 then begin
                //                     Message('%1 - %2', recItem."No.", recSalesPrice."Item No.");
                //                     recSalesPrice.Insert;
                //                 end

                //             until recItem.Next = 0;
                //         end

                //     until recProfitAdd.next = 0;

                // end;
                // Message('Traitement terminé avec succès !');
            end;

            trigger OnAfterGetRecord()
            var
                RecItemClass: Record "Item Class Setup";

            begin
                RecItemClass.SetRange(RecItemClass."Manufacturer Code", "Manufacturer Code");
                RecItemClass.SetRange(RecItemClass."Item Product Code", "Item Product Code");
                if RecItemClass.FindFirst() then begin
                    "Item Class" := RecItemClass."Item Class";
                    Modify();
                end;
                Message('Traitement terminé avec succès !');
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

    var
        myInt: Integer;
}