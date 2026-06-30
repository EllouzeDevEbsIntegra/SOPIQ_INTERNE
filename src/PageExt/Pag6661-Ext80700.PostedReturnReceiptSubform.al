pageextension 80700 "Posted Return Receipt Subform" extends "Posted Return Receipt Subform" // 6661
{
    layout
    {
        // Add changes to page layout here
        addafter("Amount Including VAT")
        {
            field(ItemUnitPrice; ItemUnitPrice)
            {
                ApplicationArea = all;
                Caption = 'Prix Vente Actuel';

            }
            field(itemLastPurchDate; itemLastPurchDate)
            {
                ApplicationArea = all;
                Caption = 'Dernier Date Achat';

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