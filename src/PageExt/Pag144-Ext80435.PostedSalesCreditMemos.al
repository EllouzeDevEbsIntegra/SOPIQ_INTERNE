pageextension 80435 "Posted Sales Credit Memos" extends "Posted Sales Credit Memos" //144
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
        addafter("Remaining Amount")
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
            field(solde; solde)
            {
                ApplicationArea = all;
                Caption = 'Soldé';
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
        SalesInvoiceHeader: Record "Recu Caisse Document";
    begin
        SalesInvoiceHeader.SetRange("Document No", rec."No.");
        PAGE.Run(PAGE::"Recu Document List", SalesInvoiceHeader);
    end;
}