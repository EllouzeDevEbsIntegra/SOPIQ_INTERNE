page 50165 "Invoice Subform"
{
    Caption = 'Factures';
    LinksAllowed = false;
    PageType = ListPart;
    SourceTable = "Sales Invoice Header";
    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                Editable = false;
                field("Posting Date"; "Posting Date")
                {
                    ApplicationArea = all;
                    Caption = 'Date';
                }
                field("No."; "No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field("Montant Brut HT"; getMntBrutHT(rec))
                {
                    ApplicationArea = all;
                    Caption = 'Brut HT';
                }
                field(Amount; Amount)
                {
                    ApplicationArea = All;
                    Style = Attention;
                    Caption = 'NET HT';
                }

                field(RemiseMoyenne; RemiseMoyenne)
                {
                    ApplicationArea = all;
                    Caption = 'Rem. Moy.';
                }
                field("Amount Including VAT"; "Amount Including VAT")
                {
                    ApplicationArea = All;
                    Caption = 'NET TTC';
                }
                field("Remaining Amount"; "Remaining Amount")
                {
                    ApplicationArea = All;
                    Style = Attention;
                    Caption = 'Net à payer';
                }
                field("Cust Name Imprime"; custNameImprime)
                {
                    ApplicationArea = All;
                    Caption = 'Client Imprimé';
                }
                field("Montant reçu caisse"; "Montant reçu caisse")
                {
                    ApplicationArea = all;
                    trigger OnDrillDown()
                    begin
                        DoDrillDown;
                    end;
                }
                field(solde; solde)
                {
                    ApplicationArea = all;
                }



            }
        }
    }
    var
        RemiseMoyenne: Decimal;

    trigger OnAfterGetRecord()
    begin
        CalcFields("Amount Including VAT", Amount, "Remaining Amount");
        if (getMntBrutHT(rec) <> 0) then RemiseMoyenne := (1 - (getMntNetHT(rec) / getMntBrutHT(rec))) * 100;

    end;

    local procedure DoDrillDown()
    var
        recuCaisseDoc: Record "Recu Caisse Document";
    begin
        recuCaisseDoc.SetRange("Document No", rec."No.");
        PAGE.Run(PAGE::"Recu Document List", recuCaisseDoc);
    end;


    procedure getMntBrutHT(InvHeader: Record "Sales Invoice Header"): Decimal
    var
        LigneInv: Record "Sales Invoice Line";
        mntBrutHt: Decimal;
    begin
        mntBrutHt := 0;
        LigneInv.Reset();
        LigneInv.SetRange("Document No.", InvHeader."No.");
        if LigneInv.FindSet() then begin
            repeat
                mntBrutHt := mntBrutHt + LigneInv.Quantity * LigneInv."Unit Price";
            until LigneInv.Next() = 0;
        end;
        exit(mntBrutHt);
    end;

    procedure getMntNetHT(InvHeader: Record "Sales Invoice Header"): Decimal
    var
        LigneInv: Record "Sales Invoice Line";
        mntNetHt: Decimal;
    begin
        mntNetHt := 0;
        LigneInv.Reset();
        LigneInv.SetRange("Document No.", InvHeader."No.");
        if LigneInv.FindSet() then begin
            repeat
                mntNetHt := mntNetHt + LigneInv.Quantity * (LigneInv."Unit Price" * (1 - (LigneInv."Line Discount %" / 100)));
            until LigneInv.Next() = 0;
        end;
        exit(mntNetHt);
    end;

    procedure SetSoldeFilter(soldeFilter: Boolean)
    begin
        if soldeFilter = true then begin
            SetFilter(Solde, '');
            CurrPage.Update();
        end else begin
            SetFilter(Solde, '%1', false);
            CurrPage.Update();
        end;

    end;
}

