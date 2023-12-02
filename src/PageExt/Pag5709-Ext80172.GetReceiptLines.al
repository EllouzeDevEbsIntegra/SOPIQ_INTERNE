pageextension 80172 "Get Receipt Lines" extends "Get Receipt Lines"//5709
{
    layout
    {
        addafter("Buy-from Vendor No.")
        {
            field("Vendor Doc No."; "Vendor Doc No.")
            {
                ApplicationArea = All;
                Caption = 'N° Doc Frs';
            }
        }
    }

    actions
    {
        // Add changes to page actions here
    }

}