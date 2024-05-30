page 50164 "BL Subform"
{
    Caption = 'Bon de Livraison';
    LinksAllowed = false;
    PageType = ListPart;
    SourceTable = "Sales Shipment Header";
    SourceTableView = WHERE(BS = FILTER(false));
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
                    Caption = 'N° Document';
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field("Montant Brut HT"; getMntBrutHT(rec))
                {
                    ApplicationArea = all;
                    Caption = 'Brut HT';
                }
                field("Line Amount HT"; "Line Amount HT")
                {
                    ApplicationArea = all;
                    Caption = 'Net HT';
                }
                field(RemiseMoyenne; RemiseMoyenne)
                {
                    ApplicationArea = all;
                    Caption = 'Rem. Moy.';
                }
                field("Line Amount"; "Line Amount")
                {
                    ApplicationArea = all;
                    Caption = 'Net TTC';
                }
                field("Montant reçu caisse"; "Montant reçu caisse")
                {
                    ApplicationArea = all;
                    trigger OnDrillDown()
                    begin
                        DoDrillDown;
                    end;
                }
                field("Montant Ouvert"; "Montant Ouvert")
                {
                    ApplicationArea = all;
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


    procedure getMntBrutHT(BlHeader: Record "Sales Shipment Header"): Decimal
    var
        LigneBL: Record "Sales Shipment Line";
        mntBrutHt: Decimal;
    begin
        mntBrutHt := 0;
        LigneBL.Reset();
        LigneBL.SetRange("Document No.", BlHeader."No.");
        if LigneBL.FindSet() then begin
            repeat
                mntBrutHt := mntBrutHt + LigneBL.Quantity * LigneBL."Unit Price";
            until LigneBL.Next() = 0;
        end;
        exit(mntBrutHt);
    end;

    procedure getMntNetHT(BlHeader: Record "Sales Shipment Header"): Decimal
    var
        LigneBL: Record "Sales Shipment Line";
        mntNetHt: Decimal;
    begin
        mntNetHt := 0;
        LigneBL.Reset();
        LigneBL.SetRange("Document No.", BlHeader."No.");
        if LigneBL.FindSet() then begin
            repeat
                mntNetHt := mntNetHt + LigneBL.Quantity * (LigneBL."Unit Price" * (1 - (LigneBL."% Discount" / 100)));
            until LigneBL.Next() = 0;
        end;
        exit(mntNetHt);
    end;


    procedure SetSoldeFilter(soldeFilter: Boolean)
    var
        recCompanyInformation: Record "Company Information";
    begin
        recCompanyInformation.get();


        if recCompanyInformation.BS = false then begin
            if soldeFilter = true then begin
                SetFilter(Solde, '');
                CurrPage.Update();
            end else begin
                SetFilter(Solde, '%1', false);
                CurrPage.Update();
            end;
        end else begin
            CalcFields("Montant Ouvert");
            if soldeFilter = true then begin
                setfilter("Montant Ouvert", '');
                CurrPage.Update();
            end else begin
                setfilter("Montant Ouvert", '<>%1', 0);
                CurrPage.Update();
            end;
        end;





    end;

}

