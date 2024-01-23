pageextension 80477 "Sales Return Order List" extends "Sales Return Order List" //9304
{
    layout
    {
        // Add changes to page layout here
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