pageextension 80125 "Purchase Lines" extends "Purchase Lines" //518
{
    layout
    {

        addafter(Quantity)
        {
            field("Order Date"; "Order Date")
            {
                ApplicationArea = All;
            }
            field("Dernier Date Reception"; "Last Receipt Date")
            {
                ApplicationArea = All;
            }
            field("Initial Vendor Price"; "Initial Vendor Price")
            {
                ApplicationArea = All;
            }
        }

        modify("Expected Receipt Date")
        {
            Editable = true;
        }
    }

    actions
    {
        // Add changes to page actions here
    }

    var
        myInt: Integer;

    trigger OnAfterGetRecord()
    begin
        CalcFields("Last Receipt Date")
    end;
}