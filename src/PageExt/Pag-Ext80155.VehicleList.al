pageextension 80155 "Vehicle List" extends "Vehicle List"
{
    layout
    {
        // Add changes to page layout here
    }

    actions
    {
        // Add changes to page actions here
        addafter("<Action157>")
        {
            action("Parts List")
            {
                ApplicationArea = Basic;
                Caption = 'Liste des pièces';
                Image = Item;
                RunObject = Page "Vehicle Parts List";
                RunPageLink = vsn = field("Serial No.");
                // RunPageView = sorting("Contact Company No.", Date, "Contact No.", Closed);
            }
        }
    }

    var
        myInt: Integer;


}