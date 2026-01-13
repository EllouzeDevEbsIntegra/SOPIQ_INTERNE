pageextension 80396 "Liste archive Bon de sortie" extends "Liste archive Bon de sortie" //50026
{
    layout
    {
        modify(Solde)
        {
            Editable = false;
        }

        addafter("Sell-to Customer Name")
        {
            field("Nom 2"; "Sell-to Customer Name 2")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Spécifie le deuxième nom du client.';
            }
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

            field("Montant Brut HT"; getMntBrutHT(rec))
            {
                ApplicationArea = all;
                Caption = 'Mnt Brut HT';
            }

            field("Montant Net HT"; getMntNetHT(rec))
            {
                ApplicationArea = all;
                Caption = 'Mnt Net HT';
            }

            field("Remise Moyenne"; RemiseMoyenne)
            {
                ApplicationArea = all;
                Caption = 'Rem. Moy.';
            }

            field(custNameImprime; custNameImprime)
            {
                ApplicationArea = all;
                Caption = 'Client Imprimé';
            }



        }
    }

    actions
    {
        // Add changes to page actions here
        addafter(Remboursement)
        {
            action(ModifyCustomer)
            {
                ApplicationArea = all;
                Caption = 'Modifier Client';
                Image = EditCustomer;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                Visible = true;
                trigger OnAction()
                var
                    recBsArchive: Record "Entete archive BS";
                    txtmessage: label 'Pas de BS sélectionné';
                begin
                    CurrPage.SETSELECTIONFILTER(recBsArchive);
                    IF recBsArchive.FINDSET THEN begin
                        report.run(25006130, TRUE, TRUE, recBsArchive);
                    end;
                end;
            }
        }
    }

    var
        RemiseMoyenne: Decimal;

    trigger OnAfterGetRecord()
    begin
        rec.CalcFields("Montant reçu caisse");
        if (getMntBrutHT(rec) <> 0) then RemiseMoyenne := (1 - (getMntNetHT(rec) / getMntBrutHT(rec))) * 100;
    end;

    local procedure DoDrillDown()
    var
        recuCaisseDoc: Record "Recu Caisse Document";
    begin
        recuCaisseDoc.SetRange("Document No", rec."No.");
        PAGE.Run(PAGE::"Recu Document List", recuCaisseDoc);
    end;

    procedure getMntBrutHT(BsHeader: Record "Entete archive BS"): Decimal
    var
        LigneArchiveBS: Record "Ligne archive BS";
        mntBrutHt: Decimal;
    begin
        mntBrutHt := 0;
        LigneArchiveBS.Reset();
        LigneArchiveBS.SetRange("Document No.", BsHeader."No.");
        if LigneArchiveBS.FindSet() then begin
            repeat
                mntBrutHt := mntBrutHt + LigneArchiveBS.Quantity * LigneArchiveBS."Unit Price";
            until LigneArchiveBS.Next() = 0;
        end;
        exit(mntBrutHt);
    end;

    procedure getMntNetHT(BsHeader: Record "Entete archive BS"): Decimal
    var
        LigneArchiveBS: Record "Ligne archive BS";
        mntNetHt: Decimal;
    begin
        mntNetHt := 0;
        LigneArchiveBS.Reset();
        LigneArchiveBS.SetRange("Document No.", BsHeader."No.");
        if LigneArchiveBS.FindSet() then begin
            repeat
                mntNetHt := mntNetHt + LigneArchiveBS.Quantity * (LigneArchiveBS."Unit Price" * (1 - (LigneArchiveBS."% Discount" / 100)));
            until LigneArchiveBS.Next() = 0;
        end;
        exit(mntNetHt);
    end;


}
