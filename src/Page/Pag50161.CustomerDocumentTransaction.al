page 50161 "Customer Document Transaction"
{
    PageType = List;
    SourceTable = Customer;
    SourceTableView = sorting("No.");
    UsageCategory = Lists;
    ApplicationArea = all;
    ModifyAllowed = false;
    DeleteAllowed = false;
    InsertAllowed = false;
    Caption = 'Transactions Client : Liste Documents';
    Editable = true;
    layout
    {
        area(Content)
        {
            grid("Customer Details")
            {
                field(Code; rec."No.")
                {
                    Caption = 'Code Client';
                    ApplicationArea = all;
                    Editable = false;
                    Style = Strong;
                }
                field(Name; rec."Name")
                {
                    Caption = 'Nom Client';
                    ApplicationArea = all;
                    Editable = false;
                    Style = Strong;
                }
                field(totalSolde; totalSolde)
                {
                    Caption = 'Total Solde Ouvert';
                    ApplicationArea = all;
                    Editable = false;
                    Style = Favorable;
                }
                field(coffreTotal; coffreTotal)
                {
                    Caption = 'Total en Coffre';
                    ApplicationArea = all;
                    Editable = false;
                    Style = StrongAccent;
                    DrillDown = true;
                    trigger OnDrillDown()
                    var
                        RecuCaissePaiement: Record "Recu Caisse Paiement";
                        RecuCaissePaiementList: page "Liste Paiement Caisse";
                    begin
                        RecuCaissePaiement.Reset();
                        RecuCaissePaiement.SetRange("N° Client", "No.");
                        RecuCaissePaiement.SetFilter(type, '%1|%2', RecuCaissePaiement.type::Cheque, RecuCaissePaiement.type::Traite);
                        RecuCaissePaiement.SetFilter(Echeance, '>a');
                        RecuCaissePaiementList.SetTableView(RecuCaissePaiement);
                        PAGE.RUN(PAGE::"Liste Paiement Caisse", RecuCaissePaiement);
                    end;
                }
                field(impTotal; impTotal)
                {
                    Caption = 'Total Impayé';
                    ApplicationArea = all;
                    Editable = false;
                    Style = Unfavorable;
                    DrillDown = true;
                    trigger OnDrillDown()
                    var
                        PayImpaye: Record "Recu Caisse Paiement";
                        RecuCaissePaiementList: page "Liste Paiement Caisse";
                    begin
                        PayImpaye.Reset();
                        PayImpaye.SetRange("N° Client", "No.");
                        PayImpaye.SetRange(Impaye, true);
                        PayImpaye.SetRange(solde, false);
                        RecuCaissePaiementList.SetTableView(PayImpaye);
                        PAGE.RUN(PAGE::"Liste Paiement Caisse", PayImpaye);
                    end;
                }
                field(global; global)
                {
                    ApplicationArea = all;
                    Caption = 'Afficher tous les documents';
                    trigger OnValidate()
                    var
                        archiveBS: Record "Entete archive BS";
                    begin
                        calcStatDoc(global);
                    end;
                }


            }
            repeater("Customer")
            {
                Caption = 'Recherche Client';

                field("No."; "No.")
                {
                    Caption = 'Code';
                    Editable = false;
                    ApplicationArea = All;
                    Style = strong;

                }
                field(CustomerName; Name)
                {
                    Caption = 'Nom';
                    Editable = false;
                    ApplicationArea = All;
                    Style = strong;
                }
                field("Name 2"; "Name 2")
                {
                    Caption = 'Nom 2';
                    Editable = false;
                    ApplicationArea = All;
                }

                field("Phone No."; "Phone No.")
                {
                    Caption = 'Tél';
                    Editable = false;
                    ApplicationArea = All;
                }

                field(Address; Address)
                {
                    Caption = 'Adresse';
                    Editable = false;
                    ApplicationArea = All;
                }
            }
            group(Statistique)
            {
                Caption = 'Statistiques';
                grid("Stat")
                {
                    field(salesOrderCount; salesOrderCount)
                    {
                        Caption = 'Cmd Vente';
                        ApplicationArea = all;
                        Editable = false;
                        StyleExpr = FieldStylesalesOrder;
                    }
                    field(bsCount; bsCount)
                    {
                        Caption = 'BS';
                        ApplicationArea = all;
                        Editable = false;
                        StyleExpr = FieldStyleBS;
                    }
                    field(retBsCount; retBsCount)
                    {
                        Caption = 'Ret BS';
                        ApplicationArea = all;
                        Editable = false;
                        StyleExpr = FieldStyleRetBS;
                    }
                    field(BlCount; BlCount)
                    {
                        Caption = 'BL';
                        ApplicationArea = all;
                        Editable = false;
                        StyleExpr = FieldStyleBL;
                    }
                    field(RetBlCount; RetBlCount)
                    {
                        Caption = 'Ret BL';
                        ApplicationArea = all;
                        Editable = false;
                        StyleExpr = FieldStyleRetBL;
                    }
                    field(invoiceCount; invoiceCount)
                    {
                        Caption = 'Facture';
                        ApplicationArea = all;
                        Editable = false;
                        StyleExpr = FieldStyleInvoice;
                    }
                    field(crMemoCount; crMemoCount)
                    {
                        Caption = 'Avoir';
                        ApplicationArea = all;
                        Editable = false;
                        StyleExpr = FieldStyleCrMemo;
                    }
                }
            }
            group(Totaux)
            {
                Caption = 'Totaux Soldes Ouverts';
                grid("Total")
                {
                    field(CmdTotal; CmdTotal)
                    {
                        Caption = 'Total Cmd';
                        ApplicationArea = all;
                        Editable = false;
                    }
                    field(bsTotal; bsTotal)
                    {
                        Caption = 'Total BS';
                        ApplicationArea = all;
                        Editable = false;
                    }
                    field(retBsTotal; retBsTotal)
                    {
                        Caption = 'Total Ret BS';
                        ApplicationArea = all;
                        Editable = false;
                    }
                    field(blTotal; blTotal)
                    {
                        Caption = 'Total BL';
                        ApplicationArea = all;
                        Editable = false;
                    }
                    field(retBlTotal; retBlTotal)
                    {
                        Caption = 'Total Ret BL';
                        ApplicationArea = all;
                        Editable = false;
                    }
                    field(invoiceTotal; invoiceTotal)
                    {
                        Caption = 'Total Facture';
                        ApplicationArea = all;
                        Editable = false;
                    }
                    field(crMemoTotal; crMemoTotal)
                    {
                        Caption = 'Total Avoir';
                        ApplicationArea = all;
                        Editable = false;
                    }
                }
            }
            part(SalesHeaders; "Slaes Header Subform")
            {
                ApplicationArea = Suite;
                Editable = false;
                SubPageLink = "Bill-to Customer No." = FIELD("No.");
                UpdatePropagation = Both;
                Visible = SalesOrderVisible;
            }
            part(BsEntete; "Bon Sortie Subform")
            {
                ApplicationArea = Suite;
                Editable = false;
                SubPageLink = "Bill-to Customer No." = FIELD("No.");
                UpdatePropagation = Both;
                Visible = BsVisible;
            }
            part(RetBs; "Ret BS")
            {
                ApplicationArea = Suite;
                Editable = false;
                SubPageLink = "Bill-to Customer No." = FIELD("No.");
                UpdatePropagation = Both;
                Visible = RetBsVisible;
            }
            part(BL; "BL Subform")
            {
                ApplicationArea = Suite;
                Editable = false;
                SubPageLink = "Bill-to Customer No." = FIELD("No.");
                UpdatePropagation = Both;
                Visible = BlVisible;
            }
            part(RetBL; "Ret BL")
            {
                ApplicationArea = Suite;
                Editable = false;
                SubPageLink = "Bill-to Customer No." = FIELD("No.");
                UpdatePropagation = Both;
                Visible = RetBlVisible;
            }
            part(Invoice; "Invoice Subform")
            {
                ApplicationArea = Suite;
                Editable = false;
                SubPageLink = "Bill-to Customer No." = FIELD("No.");
                UpdatePropagation = Both;
                Visible = InvVisible;
            }
            part(CrMemo; "Cr Memo Subform")
            {
                ApplicationArea = Suite;
                Editable = false;
                SubPageLink = "Bill-to Customer No." = FIELD("No.");
                UpdatePropagation = Both;
                Visible = CrMemoVisible;
            }

        }
    }

    actions
    {
        area(Processing)
        {
            // action(ActionName)
            // {
            //     ApplicationArea = All;

            //     trigger OnAction()
            //     begin

            //     end;
            // }
        }
    }

    var
        salesOrderCount, bsCount, retBsCount, BlCount, RetBlCount, invoiceCount, crMemoCount : Integer;
        CmdTotal, bsTotal, retBsTotal, blTotal, retBlTotal, invoiceTotal, crMemoTotal, totalSolde, coffreTotal, impTotal : Decimal;
        FieldStylesalesOrder, FieldStyleBS, FieldStyleRetBS, FieldStyleBL, FieldStyleRetBL, FieldStyleInvoice, FieldStyleCrMemo : Text[50];
        global: Boolean;
        SalesOrderVisible, BsVisible, RetBsVisible, BlVisible, RetBlVisible, InvVisible, CrMemoVisible : Boolean;

    trigger OnOpenPage()
    begin
        salesOrderCount := 0;
        bsCount := 0;
        RetBlCount := 0;
        BlCount := 0;
        RetBlCount := 0;
        invoiceCount := 0;
        crMemoCount := 0;
        CmdTotal := 0;
        bsTotal := 0;
        retBsTotal := 0;
        blTotal := 0;
        retBlTotal := 0;
        invoiceTotal := 0;
        crMemoTotal := 0;
        SalesOrderVisible := false;
        BsVisible := false;
        RetBsVisible := false;
        BlVisible := false;
        RetBlVisible := false;
        InvVisible := false;
        CrMemoVisible := false;
        global := false;

    end;

    trigger OnAfterGetCurrRecord()
    var
        salesHeader: Record "Sales Header";
        archiveBS: Record "Entete archive BS";
        SalesShipment: Record "Sales Shipment Line";
        InvoiceHeader: Record "Sales Invoice Line";
        CrMemoHeader: Record "Sales Cr.Memo Line";
        ReturnRcptHeader: Record "Return Receipt Line";

    begin

        calcStatDoc(global);


    end;

    procedure SetStyleQte(PDecimal: Decimal): Text[50]
    begin
        IF PDecimal <= 0 THEN exit('Standard') ELSE exit('Unfavorable');
    end;

    procedure calcStatDoc(soldeFilter: Boolean)
    var
        salesHeader: Record "Sales Header";
        archiveBS: Record "Entete archive BS";
        SalesShipment: Record "Sales Shipment Header";
        InvoiceHeader: Record "Sales Invoice Header";
        CrMemoHeader: Record "Sales Cr.Memo Header";
        ReturnRcptHeader: Record "Return Receipt Header";
        recCompanyInformation: Record "Company Information";
        recRecuPay, recPayImpaye : Record "Recu Caisse Paiement";
    begin
        recCompanyInformation.get();
        // Calcul nombre  Cmd Vente + Total Cmd
        CmdTotal := 0;
        salesHeader.Reset();
        salesHeader.SetRange("Document Type", salesHeader."Document Type"::Order);
        salesHeader.SetRange("Bill-to Customer No.", "No.");
        salesHeader.CalcFields("Completely Shipped");
        salesHeader.SetFilter("Completely Shipped", '%1', false);
        salesHeader.SetRange("Statut B2B", salesHeader."Statut B2B"::"Commande en attente");
        salesOrderCount := salesHeader.Count;
        if salesHeader.FindSet() then begin
            repeat
                salesHeader.CalcFields("Amount Including VAT");
                CmdTotal += salesHeader."Amount Including VAT";
            until salesHeader.Next() = 0;
        end;
        if salesOrderCount > 0 then SalesOrderVisible := true else SalesOrderVisible := false;

        // Calcul nombre  BS Archivé + Total BS
        bsTotal := 0;
        archiveBS.Reset();
        archiveBS.SetRange("Bill-to Customer No.", "No.");
        if soldeFilter = false then archiveBS.SetRange(Solde, false);
        bsCount := archiveBS.Count;
        archiveBS.SetRange(Solde, false); // Set Solde to false for archive BS
        if archiveBS.FindSet() then begin
            repeat
                archiveBS.CalcFields("Montant TTC", "Montant reçu caisse");
                bsTotal += (archiveBS."Montant TTC" - archiveBS."Montant reçu caisse");
            until archiveBS.Next() = 0;
        end;
        if bsCount > 0 then BsVisible := true else BsVisible := false;


        // Calcul nombre retour BS + Total retour BS
        retBsTotal := 0;
        ReturnRcptHeader.Reset();
        ReturnRcptHeader.SetFilter(BS, '%1', true);
        ReturnRcptHeader.SetRange("Bill-to Customer No.", "No.");
        if soldeFilter = false then ReturnRcptHeader.SetRange(Solde, false);
        retBsCount := ReturnRcptHeader.Count;
        ReturnRcptHeader.SetRange(Solde, false); // Set Solde to false for return BS
        if ReturnRcptHeader.FindSet() then begin
            repeat
                ReturnRcptHeader.CalcFields("Line Amount", "Montant reçu caisse");
                retBsTotal += (ReturnRcptHeader."Line Amount" - ReturnRcptHeader."Montant reçu caisse");
            until ReturnRcptHeader.Next() = 0;
        end;
        if retBsCount > 0 then RetBsVisible := true else RetBsVisible := false;

        // Calcul nombre BL + Total BL
        blTotal := 0;
        SalesShipment.Reset();
        SalesShipment.SetFilter(BS, '%1', false);
        if recCompanyInformation.BS = false then begin
            if soldeFilter = false then SalesShipment.SetRange(Solde, false);
        end else begin
            SalesShipment.CalcFields("Montant Ouvert", "Montant reçu caisse");
            if soldeFilter = false then SalesShipment.setfilter("Montant Ouvert", '<>%1', 0);
        end;

        SalesShipment.SetRange("Bill-to Customer No.", "No.");
        BlCount := SalesShipment.Count;
        IF recCompanyInformation.BS = FALSE THEN
            SalesShipment.SetRange(Solde, false); // Set Solde to false for Sales Shipment
        if SalesShipment.FindSet() then begin
            repeat
                if recCompanyInformation.BS = true then begin
                    SalesShipment.CalcFields("Montant Ouvert");
                    blTotal += SalesShipment."Montant Ouvert";
                end else begin
                    SalesShipment.CalcFields("Line Amount", "Montant reçu caisse");
                    blTotal += (SalesShipment."Line Amount" - SalesShipment."Montant reçu caisse");
                end;
            until SalesShipment.Next() = 0;
        end;
        if BlCount > 0 then BlVisible := true else BlVisible := false;

        // Calcul nombre retour BL + Total retour BL
        retBlTotal := 0;
        ReturnRcptHeader.Reset();
        ReturnRcptHeader.SetFilter(BS, '%1', false);
        if recCompanyInformation.BS = false then begin
            if soldeFilter = false then ReturnRcptHeader.SetRange(Solde, false);
        end else begin
            ReturnRcptHeader.CalcFields("Montant Ouvert");
            if soldeFilter = false then ReturnRcptHeader.setfilter("Montant Ouvert", '<>%1', 0);
        end;
        ReturnRcptHeader.SetRange("Bill-to Customer No.", "No.");
        RetBlCount := ReturnRcptHeader.Count;
        if recCompanyInformation.BS = false then
            ReturnRcptHeader.SetRange(Solde, false); // Set Solde to false for Return Receipt Header
        if ReturnRcptHeader.FindSet() then begin
            repeat

                if recCompanyInformation.BS = true then begin
                    ReturnRcptHeader.CalcFields("Montant Ouvert");
                    retBlTotal += ReturnRcptHeader."Montant Ouvert";
                end else begin
                    ReturnRcptHeader.CalcFields("Line Amount", "Montant reçu caisse");
                    retBlTotal += (ReturnRcptHeader."Line Amount" - ReturnRcptHeader."Montant reçu caisse");
                end;
            until ReturnRcptHeader.Next() = 0;
        end;
        if RetBlCount > 0 then RetBlVisible := true else RetBlVisible := false;


        // Calcul nombre FACTURE + Total Facture
        invoiceTotal := 0;
        InvoiceHeader.Reset();
        InvoiceHeader.SetRange("Bill-to Customer No.", "No.");
        if soldeFilter = false then InvoiceHeader.SetRange(Solde, false);
        invoiceCount := InvoiceHeader.Count;
        InvoiceHeader.SetRange(Solde, false); // Set Solde to false for Invoice Header
        if InvoiceHeader.FindSet() then begin
            repeat
                InvoiceHeader.CalcFields("Amount Including VAT", "Montant reçu caisse");
                invoiceTotal += (InvoiceHeader."Amount Including VAT" - InvoiceHeader."Montant reçu caisse");
            until InvoiceHeader.Next() = 0;
        end;
        if invoiceCount > 0 then InvVisible := true else InvVisible := false;

        // Calcul nombre AVOIR + Total Avoir
        crMemoTotal := 0;
        CrMemoHeader.Reset();
        CrMemoHeader.SetRange("Bill-to Customer No.", "No.");
        if soldeFilter = false then CrMemoHeader.SetRange(Solde, false);
        crMemoCount := CrMemoHeader.Count;
        CrMemoHeader.SetRange(Solde, false); // Set Solde to false for Cr Memo Header
        if CrMemoHeader.FindSet() then begin
            repeat
                CrMemoHeader.CalcFields("Amount Including VAT", "Montant reçu caisse");
                crMemoTotal += (CrMemoHeader."Amount Including VAT" - CrMemoHeader."Montant reçu caisse");
            until CrMemoHeader.Next() = 0;
        end;
        if crMemoCount > 0 then CrMemoVisible := true else CrMemoVisible := false;

        // Calcul encours Coffre
        coffreTotal := 0;
        recRecuPay.Reset();
        recRecuPay.SetRange("N° Client", "No.");
        recRecuPay.SetFilter(type, '%1|%2', recRecuPay.type::Cheque, recRecuPay.type::Traite);
        recRecuPay.SetFilter(Echeance, '>a');
        if recRecuPay.FindSet() then begin
            repeat
                coffreTotal += recRecuPay.Montant;
            until recRecuPay.Next() = 0;
        end;

        // Calcul Impayé
        impTotal := 0;
        recPayImpaye.Reset();
        recPayImpaye.SetRange("N° Client", "No.");
        recPayImpaye.SetRange(Impaye, true);
        recPayImpaye.SetRange(solde, false);
        if recPayImpaye.FindSet() then begin
            repeat
                recPayImpaye.CalcFields("Montant reçu caisse");
                impTotal += recPayImpaye.Montant - recPayImpaye."Montant reçu caisse";
            until recPayImpaye.Next() = 0;
        end;

        // Calcul Total Solde
        totalSolde := CmdTotal + bsTotal - retBsTotal + blTotal - retBlTotal + invoiceTotal - crMemoTotal;

        // Set Style 
        FieldStylesalesOrder := SetStyleQte(salesOrderCount);
        FieldStyleBS := SetStyleQte(bsCount);
        FieldStyleRetBS := SetStyleQte(retBsCount);
        FieldStyleBL := SetStyleQte(BlCount);
        FieldStyleRetBL := SetStyleQte(RetBlCount);
        FieldStyleInvoice := SetStyleQte(invoiceCount);
        FieldStyleCrMemo := SetStyleQte(crMemoCount);


        CurrPage.BsEntete.Page.SetSoldeFilter(soldeFilter);
        CurrPage.BL.Page.SetSoldeFilter(soldeFilter);
        CurrPage.Invoice.Page.SetSoldeFilter(soldeFilter);
        CurrPage.CrMemo.Page.SetSoldeFilter(soldeFilter);
        CurrPage.RetBL.Page.SetSoldeFilter(soldeFilter);
        CurrPage.RetBs.Page.SetSoldeFilter(soldeFilter);
    end;

}