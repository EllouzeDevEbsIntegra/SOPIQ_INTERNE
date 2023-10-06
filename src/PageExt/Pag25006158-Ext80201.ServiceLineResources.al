pageextension 80201 "Service Line Resources" extends "Service Line Resources"//25006158
{
    layout
    {
        addfirst(Group)
        {
            field("date"; "date")
            {
                ApplicationArea = All;
                Caption = 'Date';
            }

        }
        // Add changes to page layout here
    }

    actions
    {
        // Add changes to page actions here
    }

    var
        myInt: Integer;
}