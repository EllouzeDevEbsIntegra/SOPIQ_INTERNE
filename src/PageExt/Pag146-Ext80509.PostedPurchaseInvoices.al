pageextension 80509 "Posted Purchase Invoices" extends "Posted Purchase Invoices" //146
{
    layout
    {
        // Add changes to page layout here
        addafter("Amount Including VAT")
        {
            field(solde; solde)
            {
                ApplicationArea = all;
            }

            field("Montant reçu caisse"; "Montant reçu caisse")
            {
                ApplicationArea = all;
                trigger OnDrillDown()
                begin
                    DoDrillDown;
                end;
            }
        }


    }


    actions
    {
        // Add changes to page actions here
    }

    var
        myInt: Integer;

    local procedure DoDrillDown()
    var
        recuCaisseDoc: Record "Recu Caisse Document";
    begin
        recuCaisseDoc.SetRange("Document No", rec."No.");
        PAGE.Run(PAGE::"Recu Document List", recuCaisseDoc);
    end;
}