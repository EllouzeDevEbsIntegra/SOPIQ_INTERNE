page 50163 "Bon Sortie Subform"
{
    Caption = 'Bon Sortie';
    LinksAllowed = false;
    PageType = ListPart;
    SourceTable = "Entete archive BS";

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
                    Caption = 'N° Document';
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field("Montant Brut HT"; getMntBrutHT(rec))
                {
                    ApplicationArea = all;
                    Caption = 'Brut HT';
                }

                field("Montant Net HT"; getMntNetHT(rec))
                {
                    ApplicationArea = all;
                    Caption = 'Net HT';
                }

                field("Remise Moyenne"; RemiseMoyenne)
                {
                    ApplicationArea = all;
                    Caption = 'Rem. Moy.';
                }
                field("Montant TTC"; "Montant TTC")
                {
                    ApplicationArea = all;
                    Caption = 'Net TTC';
                }

                field(custNameImprime; custNameImprime)
                {
                    ApplicationArea = all;
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
                field(Solde; Solde)
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

