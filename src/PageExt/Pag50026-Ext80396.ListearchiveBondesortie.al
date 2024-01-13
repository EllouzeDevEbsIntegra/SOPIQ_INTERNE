pageextension 80396 "Liste archive Bon de sortie" extends "Liste archive Bon de sortie" //50026
{
    layout
    {
        modify(Solde)
        {
            Editable = false;
        }
        // Add changes to page layout here
        addafter("Montant TTC")
        {
            field("Montant reçu caisse"; "Montant reçu caisse")
            {
                ApplicationArea = all;
                trigger OnDrillDown()
                begin
                    DoDrillDown;
                end;
            }

            // field("No reçu caisse"; "No reçu caisse")
            // {
            //     ApplicationArea = all;
            //     trigger OnDrillDown()
            //     var
            //         recuCaisse: Record "Recu Caisse";
            //     begin
            //         recuCaisse.SetRange("No", rec."No reçu caisse");
            //         PAGE.Run(PAGE::"Recu de caisse", recuCaisse);
            //     end;
            // }
        }
    }

    actions
    {
        // Add changes to page actions here
    }

    var

    trigger OnAfterGetRecord()
    begin
        rec.CalcFields("Montant reçu caisse");
    end;

    local procedure DoDrillDown()
    var
        SalesInvoiceHeader: Record "Recu Caisse Document";
    begin
        SalesInvoiceHeader.SetRange("Document No", rec."No.");
        PAGE.Run(PAGE::"Recu Document List", SalesInvoiceHeader);
    end;
}
