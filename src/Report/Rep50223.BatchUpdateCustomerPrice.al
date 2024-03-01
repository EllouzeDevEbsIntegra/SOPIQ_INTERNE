report 50223 "Batch Update Customer Price"
{
    UsageCategory = ReportsAndAnalysis;
    ApplicationArea = All;
    Caption = 'Mise à jour prix clients en tenant compte des marges et remises exceptionnelles';
    Permissions = tabledata Item = r,
                  tabledata "Sales Price" = rimd,
                  tabledata "Customer Additional Profit" = rimd; // Permission pour l'utilsateur de lire / ecrire / modofier / inserer dans une table 'Artcle' dans ce cas
    ProcessingOnly = true;  // Pour dire que just c'est un traitement en arrière plan

    dataset
    {
        dataitem("Customer Additional Profit"; "Customer Additional Profit")
        {
            trigger OnPreDataItem()
            begin

            end;

            trigger OnPostDataItem()
            var

            begin

            end;

            trigger OnAfterGetRecord()
            var

                recItem: Record Item;
                recCustomer: Record Customer;
                recProfitAdd: Record "Customer Additional Profit";
                recSalesPrice: Record "Sales Price";
                recSalesDiscount: Record "Sales Line Discount";

            begin

                // Supprimer tous les prix dans table sales price sauf les client spéciaux

                recCustomer.Reset();
                recCustomer.SetRange("Is Special Vendor", false);
                if recCustomer.FindSet() then begin
                    repeat
                        recSalesPrice.Reset();
                        recSalesPrice.SetRange("Sales Code", recCustomer."No.");
                        if recSalesPrice.FindSet() then begin
                            repeat
                                recSalesPrice.Delete(true);
                            until recSalesPrice.Next() = 0;
                        end;

                        recSalesDiscount.Reset();
                        recSalesDiscount.SetRange("Sales Code", recCustomer."No.");
                        if recSalesDiscount.FindSet() then begin
                            repeat
                                recSalesDiscount.Delete(true);
                            until recSalesDiscount.Next() = 0;
                        end;
                    until recCustomer.Next() = 0;
                end;

                //Ajouter les prix spécifiques dans la table Sales Price et les remises spécifiques dans la table Sales Discount line
                recProfitAdd.Reset();
                if recProfitAdd.FindSet() then begin
                    repeat
                        recItem.reset();
                        if (recProfitAdd."Item Manufacturer" <> 'ALLFAB') THEN recitem.SetRange("Manufacturer Code", recProfitAdd."Item Manufacturer");
                        if (recProfitAdd."Item Group" <> 'PR') THEN recitem.SetRange("Item Product Code", recProfitAdd."Item Group");
                        if recItem.FindSet() then begin
                            repeat
                                recItem.CalcFields(Inventory);
                                if (recItem.Inventory > 0) then begin
                                    case recProfitAdd.Type of
                                        recProfitAdd.Type::"Marge Additionnelle":
                                            begin
                                                recSalesPrice.Init();
                                                recSalesPrice."Sales Type" := recSalesPrice."Sales Type"::Customer;
                                                recSalesPrice."Sales Code" := recProfitAdd.Customers;
                                                recSalesPrice."Item No." := recItem."No.";
                                                recSalesPrice."Starting Date" := Today;
                                                recSalesPrice."Ending Date" := CalcDate('<1M>', Today);
                                                recSalesPrice."Unit Price" := recItem."Unit Price" * (1 + recProfitAdd.Taux / 100);
                                                recSalesPrice."Minimum Quantity" := 1;
                                                recSalesPrice."Unit of Measure Code" := recItem."Sales Unit of Measure";
                                                recSalesPrice.Insert;
                                            end;
                                        recProfitAdd.Type::"Remise Exceptionnelle":
                                            begin
                                                //Message(recItem."No.");
                                                recSalesDiscount.Init();
                                                recSalesDiscount."Sales Type" := recSalesDiscount."Sales Type"::Customer;
                                                recSalesDiscount."Sales Code" := recProfitAdd.Customers;
                                                recSalesDiscount.Type := recSalesDiscount.Type::Item;
                                                recSalesDiscount."code" := recItem."No.";
                                                recSalesDiscount."Unit of Measure Code" := recItem."Sales Unit of Measure";
                                                recSalesDiscount."Minimum Quantity" := 1;
                                                recSalesDiscount."Line Discount %" := recProfitAdd.Taux;
                                                recSalesDiscount."Starting Date" := Today;
                                                recSalesDiscount."Ending Date" := CalcDate('<1M>', Today);
                                                recSalesDiscount.Insert;

                                            end;
                                    end;

                                end;


                            until recItem.Next = 0;
                        end

                    until recProfitAdd.Next() = 0;
                end;




            end;

        }
    }



    trigger OnInitReport()
    begin

    end;

    trigger OnPostReport()
    begin
        Message('Traitement terminé avec succès !');
    end;

    trigger OnPreReport()
    begin

    end;

    var
        myInt: Integer;
}