pageextension 80347 "General Ledger Setup" extends "General Ledger Setup" //118
{
    layout
    {
        // Add changes to page layout here
        addafter("Posting Allowed From")
        {
            field(AutoComment; AutoComment)
            {
                ApplicationArea = all;
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