pageextension 80601 "Model Version List" extends "Model Version List" //25006054
{
    layout
    {
        addafter(Description)
        {
            field("Commercial Description"; "Commercial Description")
            {
                ApplicationArea = All;
                Caption = 'Description commerciale';
            }
        }
    }

    actions
    {
        // Add changes to page actions here
    }

    var
        myInt: Integer;
}