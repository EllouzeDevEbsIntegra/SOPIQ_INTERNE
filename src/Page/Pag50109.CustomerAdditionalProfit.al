page 50109 "Customer Additional Profit"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "Customer Additional Profit";
    Caption = 'Paramètre marge additionnel : client/fabricant/famille';

    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                field("Customers"; "Customers")
                {
                    ApplicationArea = All;

                }
                field("Item Manufacturer"; "Item Manufacturer")
                {
                    ApplicationArea = All;

                }
                field("Item Group"; "Item Group")
                {
                    ApplicationArea = All;

                }
                field(Type; Type)
                {
                    ApplicationArea = All;
                }
                field("Taux"; "Taux")
                {
                    ApplicationArea = All;
                    caption = 'Taux';

                }


            }
        }
        area(Factboxes)
        {

        }
    }

    actions
    {
        area(Processing)
        {
            action("Validate Profit")
            {
                ApplicationArea = All;
                Caption = 'Appliquer les marges';
                trigger OnAction();
                var
                    recItem: Record Item;
                    recCustomer: Record Customer;
                    recProfitAdd: Record "Customer Additional Profit";
                    recSalesPrice: Record "Sales Price";
                begin
                    recProfitAdd.Reset();
                    recProfitAdd.SetRange(Type, recProfitAdd.Type::"Marge Additionnelle");
                    if recProfitAdd.FindSet() then begin
                        repeat
                            recItem.Reset();
                            recItem.SetRange("Manufacturer Code", recProfitAdd."Item Manufacturer");
                            if (recProfitAdd."Item Group" <> 'PR') then recItem.SetRange("Item Product Code", recProfitAdd."Item Group");
                            if recItem.FindSet() then begin
                                repeat
                                    recItem.CalcFields(StockQty);
                                    recSalesPrice.Reset();
                                    recSalesPrice.SetRange("Sales Type", recSalesPrice."Sales Type"::Customer);
                                    recSalesPrice.SetRange("Sales Code", recProfitAdd.Customers);
                                    recSalesPrice.SetRange("Item No.", recItem."No.");
                                    if recSalesPrice.FindSet() then begin
                                        repeat
                                            recSalesPrice.Delete();
                                        until recSalesPrice.Next = 0;
                                    end;

                                    recSalesPrice.Init();
                                    recSalesPrice."Sales Type" := recSalesPrice."Sales Type"::Customer;
                                    recSalesPrice."Sales Code" := recProfitAdd.Customers;
                                    recSalesPrice."Item No." := recItem."No.";
                                    recSalesPrice."Starting Date" := Today;
                                    recSalesPrice."Unit Price" := recItem."Unit Price" * (1 + recProfitAdd.Taux / 100);
                                    recSalesPrice."Minimum Quantity" := 1;
                                    recSalesPrice."Unit of Measure Code" := recItem."Sales Unit of Measure";
                                    if (recItem.StockQty > 0) then recSalesPrice.Insert;

                                until recItem.Next = 0;
                            end

                        until recProfitAdd.next = 0;

                    end;
                    Message('Traitement terminé avec succès !');
                end;

            }
        }
    }
}