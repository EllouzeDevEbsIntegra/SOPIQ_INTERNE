pageextension 80477 "Sales Return Order List" extends "Sales Return Order List" //9304
{
    layout
    {
        // Add changes to page layout here
        addafter("Sell-to Customer Name")
        {
            field("Nom 2"; "Sell-to Customer Name 2")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the second name of the customer.';
            }
        }
    }

    actions
    {
        // Add changes to page actions here
    }

    var
        myInt: Integer;

    trigger OnOpenPage()
    begin
        SetFilter(BS, '%1', false);
    end;
}