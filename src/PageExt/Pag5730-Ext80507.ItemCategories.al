pageextension 80507 "Item Categories" extends "Item Categories" //5730
{
    layout
    {
        // Add changes to page layout here
        addafter(Description)
        {
            field("Category BI"; "Category BI")
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