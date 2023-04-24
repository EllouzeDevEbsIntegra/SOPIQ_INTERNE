page 50111 "Vehicle Parts List"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "Vehicle parts";

    layout
    {
        area(Content)
        {
            repeater("Parts List")
            {
                field(no; no)
                {
                    ApplicationArea = All;
                    Editable = false;

                }
                field(vsn; vsn)
                {
                    ApplicationArea = All;
                    // trigger OnLookup()
                    // var
                    //     text: text[100];
                    // begin
                    //     text := GetFilter(vsn);
                    //     Message(text);
                    // end;
                }
                field(vin; vin)
                {
                    ApplicationArea = All;

                }
                field(subgroup; subgroup)
                {
                    ApplicationArea = All;

                }
                field("Subgroup Description"; "subgroup Description")
                {

                }
                field(itemNo; itemNo)
                {
                    ApplicationArea = All;

                }
                field(Qty; Qty)
                {
                    ApplicationArea = All;
                    DecimalPlaces = 0 : 1;

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
                begin

                end;
            }
        }
    }

}