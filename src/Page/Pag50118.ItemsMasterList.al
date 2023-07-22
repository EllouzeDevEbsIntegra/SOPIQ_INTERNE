page 50118 "Items Master List"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "items Master";
    SourceTableView = where(Verified = filter(false));

    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                field(No; No)
                {
                    ApplicationArea = All;

                }

                field(Famille; Famille)
                {
                    ApplicationArea = All;

                }

                field(Company; Company)
                {
                    ApplicationArea = All;

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
            action(ActionName)
            {
                ApplicationArea = All;

                trigger OnAction();
                var
                    Item: Record Item;
                begin

                end;
            }
        }
    }
}