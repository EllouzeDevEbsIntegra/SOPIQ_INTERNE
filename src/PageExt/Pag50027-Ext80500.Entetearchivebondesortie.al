pageextension 80500 "Entete archive bon de sortie" extends "Entete archive bon de sortie" //50027
{
    layout
    {
        // Add changes to page layout here
        addbefore("Montant TTC")
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
        }
    }

    actions
    {
        // Add changes to page actions here
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
        SalesInvoiceHeader: Record "Recu Caisse Document";
    begin
        SalesInvoiceHeader.SetRange("Document No", rec."No.");
        PAGE.Run(PAGE::"Recu Document List", SalesInvoiceHeader);
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