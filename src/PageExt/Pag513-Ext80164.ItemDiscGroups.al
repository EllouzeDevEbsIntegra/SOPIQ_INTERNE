pageextension 80164 "Item Disc. Groups" extends "Item Disc. Groups" //513
{
    layout
    {
        // Add changes to page layout here
        addafter(Description)
        {
            field("Code Group"; rec."Code Groupe")
            {
                ApplicationArea = All;
                Caption = 'Famille';
            }

            field("Code Fabricant"; rec."Code Fabricant")
            {
                ApplicationArea = All;
                Caption = 'Fabricant';
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