page 50160 "BS Paiement"
{

    PageType = List;
    SourceTable = "Entete archive BS";
    SourceTableView = sorting("No.") where(Solde = filter(false));
    UsageCategory = Lists;
    ApplicationArea = all;
    Caption = 'Réglement Bon Srotie';
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = false;
    Editable = true;
    Permissions = tabledata "Recu Caisse" = rimd,
                  tabledata "Recu Caisse Document" = rimd;
    layout
    {
        area(Content)
        {
            group("Filter")
            {
                Caption = 'Filtre';
                field(customerNoFilter; customerNoFilter)
                {
                    TableRelation = Customer;

                    // trigger OnDrillDown()
                    // var
                    //     reccustomer: Record Customer;

                    // begin
                    //     Page.Run(Page::"Customer List", reccustomer);

                    // end;
                    trigger OnValidate()
                    var
                        recBS: Record "Entete archive BS";
                    begin
                        recBS.Init();
                        recBS.SetRange("Bill-to Customer No.", customerNoFilter);
                        CurrPage.SetTableView(recBS);
                        totalTTC := getTotalTTC(customerNoFilter);
                        CurrPage.Update();
                    end;
                }
                field(totalTTC; totalTTC)
                {
                    Caption = 'Total BS Non Soldé';
                    ApplicationArea = all;
                    Editable = false;
                }
                field(totalSelectedBS; totalSelectedBS)
                {
                    Caption = 'Total BS Sélectionnés';
                    ApplicationArea = all;
                    Editable = false;
                }
                field(totalRegSelectedBS; totalRegSelectedBS)
                {
                    Caption = 'Montant à régler BS Sélectionnés';
                    ApplicationArea = all;
                    Editable = false;
                    Style = Unfavorable;
                }


            }
            repeater("Liste Bon Sortie")
            {
                Caption = 'Liste Bon Sortie';
                field("Posting Date"; "Posting Date")
                {
                    ApplicationArea = all;
                    Editable = false;
                }
                field("No."; "No.")
                {
                    Editable = false;
                    ApplicationArea = All;
                    Style = strong;
                }

                field("Bill-to Name"; "Bill-to Name")
                {
                    ApplicationArea = all;
                    Editable = false;
                }
                field("Montant TTC"; "Montant TTC")
                {
                    ApplicationArea = all;
                    Editable = false;
                }
                field("Montant reçu caisse"; "Montant reçu caisse")
                {
                    ApplicationArea = all;
                    Editable = false;
                    trigger OnDrillDown()
                    begin
                        DoDrillDown;
                    end;

                }

                field("Montant Brut HT"; getMntBrutHT(rec))
                {
                    ApplicationArea = all;
                    Caption = 'Mnt Brut HT';
                    Editable = false;
                }

                field("Montant Net HT"; getMntNetHT(rec))
                {
                    ApplicationArea = all;
                    Caption = 'Mnt Net HT';
                    Editable = false;
                }

                field("Remise Moyenne"; RemiseMoyenne)
                {
                    ApplicationArea = all;
                    Caption = 'Rem. Moy.';
                    Editable = false;
                }

                field(custNameImprime; custNameImprime)
                {
                    ApplicationArea = all;
                    Caption = 'Client Imprimé';
                    Editable = false;
                }

            }
            group(General)
            {

            }

        }
    }

    actions
    {
        area(Processing)
        {
            action("Update Totaux")
            {
                Caption = 'Update Totaux';
                ApplicationArea = All;
                ShortcutKey = F8;
                Image = NewSum;
                Promoted = true;
                PromotedIsBig = true;
                PromotedCategory = Process;
                trigger OnAction()
                var
                    bsArchive: Record "Entete archive BS";
                    totalSelected, totalMntReglement : Decimal;

                begin
                    totalSelected := 0;
                    totalMntReglement := 0;
                    CurrPage.SetSelectionFilter(bsArchive);
                    if bsArchive.FindSet() then begin
                        repeat
                            bsArchive.CalcFields("Montant TTC", "Montant reçu caisse");
                            totalSelected := totalSelected + bsArchive."Montant TTC";
                            totalMntReglement := totalMntReglement + bsArchive."Montant TTC" - bsArchive."Montant reçu caisse";
                        until bsArchive.Next() = 0;
                    end;
                    totalSelectedBS := totalSelected;
                    totalRegSelectedBS := totalMntReglement;
                    CurrPage.Update();
                end;
            }

            action("Create Recu Caisse")
            {
                Caption = 'Créer Reçu Caisse';
                ApplicationArea = All;
                Image = PostedPayment;
                Promoted = true;
                PromotedIsBig = true;
                PromotedCategory = Process;
                trigger OnAction()
                var
                    recSalesSetup: Record "Sales & Receivables Setup";
                    bsArchive: Record "Entete archive BS";
                    recuCaisse, recRecu : Record "Recu Caisse";
                    recuDoc: Record "Recu Caisse Document";
                    serieNoMgt: Codeunit NoSeriesManagement;
                    recCust: Record Customer;
                    pageRecu: Page "Recu Caisse Card";
                    recuInserted, recuDocInserted : Boolean;

                begin

                    recuInserted := false;
                    recuDocInserted := false;
                    recCust.Reset();
                    recCust.SetRange("No.", customerNoFilter);
                    if recCust.FindFirst() then begin
                        if totalRegSelectedBS > 0 then begin
                            if Confirm('Voulez vous créer un reçu de caisse pour le client %1 - %2 avec un montant à régler %3 du total documents %4 ?', false, recCust."No.", recCust.Name, totalRegSelectedBS, totalSelectedBS) then begin
                                // Insertion Entête Reçu de Caisse
                                recSalesSetup.Get;
                                recuCaisse.Reset();
                                recuCaisse.dateTime := System.CurrentDateTime;
                                recuCaisse.dateRecu := System.Today;
                                recuCaisse.No := serieNoMgt.GetNextNo(recSalesSetup."Reçu Caisse Serie", System.Today, true);
                                recuCaisse."Customer No" := recCust."No.";
                                recuCaisse.custName := recCust.Name;
                                recuCaisse.Insert();



                                // Insertion document à régler reçu de caisse
                                recuDoc.Reset();
                                CurrPage.SetSelectionFilter(bsArchive);
                                if bsArchive.FindSet() then begin
                                    repeat
                                        bsArchive.CalcFields("Montant reçu caisse", "Montant TTC");
                                        recuDoc."No Recu" := recuCaisse.No;
                                        recuDoc."Line No" := recuDoc.incrementNo(recuCaisse.No);
                                        recuDoc.type := recuDoc.type::BS;
                                        recuDoc."Customer No" := recCust."No.";
                                        recuDoc."Document No" := bsArchive."No.";
                                        recuDoc."Total TTC" := bsArchive."Montant TTC";
                                        recuDoc."Montant Reglement" := bsArchive."Montant TTC" - bsArchive."Montant reçu caisse";
                                        recuDoc.Insert(true);
                                    until bsArchive.Next() = 0;
                                end;




                                // Ouvrir le reçu de caisse 

                                if Confirm('Reçu N° %1 créé avec succés ! Voulez vous ouvrir le document?', true, recuCaisse.No) then begin
                                    recRecu.Reset();
                                    recRecu.SetRange(No, recuCaisse.No);
                                    pageRecu.SetTableView(recRecu);
                                    pageRecu.Run();
                                end;

                            end;
                        end
                        else
                            Error('Montant de réglement égal à 0, veuillez vérifier les documents à règler !');

                    end
                    else
                        Error('vous devez sélectionner un client !');
                end;
            }
        }
    }

    var
        customerNoFilter: Text;
        RemiseMoyenne: Decimal;
        totalTTC, totalSelectedBS, totalRegSelectedBS : Decimal;

    procedure SetStyleQte(PDecimal: Decimal): Text[50]
    begin
        IF PDecimal <= 0 THEN exit('Standard') ELSE exit('Unfavorable');
    end;

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

    procedure getTotalTTC(customerNo: code[20]): Decimal
    var
        mntTotalTTC: Decimal;
        bsHeader: Record "Entete archive BS";
    begin
        mntTotalTTC := 0;
        bsHeader.SetRange("Bill-to Customer No.", customerNo);
        if bsHeader.FindSet() then begin
            repeat
                bsHeader.CalcFields("Montant TTC");
                mntTotalTTC := mntTotalTTC + bsHeader."Montant TTC";
            until bsHeader.Next() = 0;
        end;
        exit(mntTotalTTC);
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