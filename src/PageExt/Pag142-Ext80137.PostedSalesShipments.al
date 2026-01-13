pageextension 80137 "Posted Sales Shipments" extends "Posted Sales Shipments"//142
{
    layout
    {
        addafter("Sell-to Customer Name")
        {
            field("Nom 2"; "Sell-to Customer Name 2")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the second name of the customer.';
            }
        }

        // Add changes to page layout here
        addafter("Line Amount")
        {
            field("Montant Ouvert"; "Montant Ouvert")
            {
                Caption = 'Montant ouvert';

            }
            field(solde; solde)
            {
                ApplicationArea = all;
            }

            field("Montant reçu caisse"; "Montant reçu caisse")
            {
                ApplicationArea = all;
                DrillDown = true;
                DrillDownPageId = "Recu Document List";
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
        CalcFields("Montant Ouvert", Acopmpte, "Montant reçu caisse");
    end;
}