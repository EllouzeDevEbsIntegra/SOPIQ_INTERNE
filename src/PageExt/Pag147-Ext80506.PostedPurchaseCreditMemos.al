pageextension 80506 "Posted Purchase Credit Memos" extends "Posted Purchase Credit Memos" //147
{
    layout
    {
        // Add changes to page layout here
        addafter(Paid)
        {
            field("Vendor Cr. Memo No."; "Vendor Cr. Memo No.")
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