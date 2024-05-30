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
                field(Name; rec.Name)
                {
                    Caption = 'Nom Client';
                    ApplicationArea = all;
                    Editable = false;
                    Style = Strong;
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
            group(General)
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
    begin
        recCompanyInformation.get();
        // Calcul nombre  Cmd Vente
        salesHeader.Reset();
        salesHeader.SetRange("Document Type", salesHeader."Document Type"::Order);
        salesHeader.SetRange("Bill-to Customer No.", "No.");
        salesHeader.CalcFields("Completely Shipped");
        salesHeader.SetFilter("Completely Shipped", '%1', false);
        salesOrderCount := salesHeader.Count;
        if salesOrderCount > 0 then SalesOrderVisible := true else SalesOrderVisible := false;

        // Calcul nombre  BS Archivé
        archiveBS.Reset();
        archiveBS.SetRange("Bill-to Customer No.", "No.");
        if soldeFilter = false then archiveBS.SetRange(Solde, false);
        bsCount := archiveBS.Count;
        if bsCount > 0 then BsVisible := true else BsVisible := false;


        // Calcul nombre retour BS 
        ReturnRcptHeader.Reset();
        ReturnRcptHeader.SetFilter(BS, '%1', true);
        ReturnRcptHeader.SetRange("Bill-to Customer No.", "No.");
        if soldeFilter = false then ReturnRcptHeader.SetRange(Solde, false);
        retBsCount := ReturnRcptHeader.Count;
        if retBsCount > 0 then RetBsVisible := true else RetBsVisible := false;

        // Calcul nombre BL
        SalesShipment.Reset();
        SalesShipment.SetFilter(BS, '%1', false);
        if recCompanyInformation.BS = false then begin
            if soldeFilter = false then SalesShipment.SetRange(Solde, false);
        end else begin
            SalesShipment.CalcFields("Montant Ouvert");
            if soldeFilter = false then SalesShipment.setfilter("Montant Ouvert", '<>%1', 0);
        end;

        SalesShipment.SetRange("Bill-to Customer No.", "No.");
        BlCount := SalesShipment.Count;
        if BlCount > 0 then BlVisible := true else BlVisible := false;

        // Calcul nombre retour BL
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
        if RetBlCount > 0 then RetBlVisible := true else RetBlVisible := false;


        // Calcul nombre FACTURE
        InvoiceHeader.Reset();
        InvoiceHeader.SetRange("Bill-to Customer No.", "No.");
        if soldeFilter = false then InvoiceHeader.SetRange(Solde, false);
        invoiceCount := InvoiceHeader.Count;
        if invoiceCount > 0 then InvVisible := true else InvVisible := false;

        // Calcul nombre AVOIR
        CrMemoHeader.Reset();
        CrMemoHeader.SetRange("Bill-to Customer No.", "No.");
        if soldeFilter = false then CrMemoHeader.SetRange(Solde, false);
        crMemoCount := CrMemoHeader.Count;
        if crMemoCount > 0 then CrMemoVisible := true else CrMemoVisible := false;


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