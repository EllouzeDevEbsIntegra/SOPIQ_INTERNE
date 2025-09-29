pageextension 80750 "Sales Invoice" extends "Sales Invoice" //43
{
    layout
    {
        // Add changes to page layout here
        addafter("Sell-to Customer Name")
        {
            field(custNameImprime; custNameImprime)
            {
                ApplicationArea = All;
                Caption = 'Nom Client Imprimé';
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