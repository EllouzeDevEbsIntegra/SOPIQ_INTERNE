pageextension 80134 "Accountant Role Center" extends "Accountant Role Center" // 9027
{
    layout
    {
        // Add changes to page layout here
    }

    actions
    {
        modify("General Ledger Accounts")
        {
            Visible = false;
        }
        // Add changes to page actions here
        addbefore("General Ledger Accounts")
        {
            action("General Ledger Accounts 2")
            {
                Caption = 'Grand Livre Comptes Généreaux';
                ApplicationArea = All;
                Visible = true;
                RunObject = report 50199;
            }

            action("Vendor GL")
            {
                Caption = 'Grand Livre Fournisseur 2';
                ApplicationArea = All;
                Visible = true;
                RunObject = report 50205;
            }

            action("Customer GL")
            {
                Caption = 'Grand Livre Client 2';
                ApplicationArea = All;
                Visible = true;
                RunObject = report 50206;
            }
        }

    }

    var
        myInt: Integer;
}