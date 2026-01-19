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
        addlast(Processing)
        {
            action("Transporter Shipment List")
            {
                ApplicationArea = All;
                Caption = 'Créer Expéditions Transporteur';
                Image = TransferReceipt;
                Promoted = true;
                PromotedCategory = Process;
                RunObject = Page "Transporter Shipment List";
                ToolTip = 'Ouvre la liste des BL et créer une expédition Transporteur.';
            }
            action("Liste des Expéditions Transporteur")
            {
                ApplicationArea = All;
                Caption = 'Liste des Expéditions Transporteur';
                Image = Shipment;
                Promoted = true;
                PromotedCategory = Process;
                RunObject = page "Transporter Orders List";
                RunPageLink = "Order ID" = field("N° récépissé");
            }
        }
    }

    var
        myInt: Integer;

    trigger OnAfterGetRecord()
    begin
        CalcFields("Montant Ouvert", Acopmpte, "Montant reçu caisse");
    end;
}