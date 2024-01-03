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

            field(Acopmpte; Acopmpte)
            {
                Caption = 'Acompte';
            }

            field(custNameImprime; custNameImprime)
            {

            }

            field(custAdresseImprime; custAdresseImprime)
            {

            }

            field(custMFImprime; custMFImprime)
            {

            }

            field(custVINImprime; custVINImprime)
            {

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
        CalcFields("Montant Ouvert", Acopmpte);
    end;
}