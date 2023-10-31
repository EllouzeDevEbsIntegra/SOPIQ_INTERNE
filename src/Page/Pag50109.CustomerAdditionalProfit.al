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
                Caption = 'Appliquer les prix spécifiques';
                Image = PriceAdjustment;
                trigger OnAction();
                var
                    reportUpdateCustomerPrice: Report "Batch Update Customer Price";
                begin
                    reportUpdateCustomerPrice.run();
                end;

            }
        }
    }
}