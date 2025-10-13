pageextension 80520 "Posted Sales Invoices (Serv.)" extends "Posted Sales Invoices (Serv.)"//25006189
{
    layout
    {
        // Add changes to page layout here
        addafter(LocationCode)
        {
            field("Remaining Amount"; "Remaining Amount")
            {
                ApplicationArea = all;
                Caption = 'Montant Ouvert';
            }
            field(Initiateur; Initiateur)
            {
                ApplicationArea = all;
                Caption = 'Code Initiateur';
            }
            field("Phone No."; "Phone No.")
            {
                ApplicationArea = all;
                Caption = 'N° Téléphone';
            }
        }
        addlast(Control1)
        {

            field("Montant reçu caisse"; "Montant reçu caisse")
            {
                ApplicationArea = all;
                Caption = 'Montant reçu caisse';
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
        // addafter(Print)
        // {

        // }
    }

    var
        myInt: Integer;

    trigger OnAfterGetRecord()
    begin
        CalcFields(Initiateur, "Remaining Amount", "Montant reçu caisse");
    end;

    local procedure DoDrillDown()
    var
        recuCaisseDoc: Record "Recu Caisse Document";
    begin
        recuCaisseDoc.SetRange("Document No", rec."No.");
        PAGE.Run(PAGE::"Recu Document List", recuCaisseDoc);
    end;
}