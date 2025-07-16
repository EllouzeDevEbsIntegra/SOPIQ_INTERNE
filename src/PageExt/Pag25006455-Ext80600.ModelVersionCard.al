pageextension 80600 "Model Version Card" extends "Model Version Card" //25006455
{
    layout
    {
        // Add changes to page layout here
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