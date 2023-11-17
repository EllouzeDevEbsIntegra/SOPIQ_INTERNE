pageextension 80137 "Posted Sales Shipments" extends "Posted Sales Shipments"//142
{
    layout
    {

        // Add changes to page layout here
        addafter("Line Amount")
        {
            field("Montant Ouvert"; "Montant Ouvert")
            {
                Caption = 'Montant ouvert';

            }

            field("Order No."; "Order No.")
            {
                Caption = 'N° Commande';
            }
        }
    }

    actions
    {
        // Add changes to page actions here
    }

    var
        myInt: Integer;

    trigger OnAfterGetRecord()
    begin
        CalcFields("Montant Ouvert");
    end;
}