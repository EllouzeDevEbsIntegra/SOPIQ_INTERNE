page 50152 "Item Transaction"
{
    PageType = List;
    SourceTable = Item;
    SourceTableView = sorting("No.") where("No." = Filter('<> '''''));
    UsageCategory = Lists;
    ApplicationArea = all;
    ModifyAllowed = false;
    DeleteAllowed = false;
    InsertAllowed = false;
    Caption = 'Transactions Article Détaillées';
    Editable = true;
    DataCaptionExpression = GetCaption;
    layout
    {
        area(Content)
        {
            grid("Item Details")
            {
                Caption = 'Stat Article';
                field(selectedYear; selectedYear)
                {
                    Caption = 'Année';
                    ApplicationArea = all;
                    Editable = false;
                    Style = Favorable;
                }
                field(Ref; rec."No.")
                {
                    Caption = 'Réf';
                    ApplicationArea = all;
                    Editable = false;
                    Style = Strong;
                }
                field(Stock; rec."Available Inventory")
                {
                    Caption = 'Stock';
                    ApplicationArea = all;
                    Editable = false;
                    Style = Unfavorable;
                }
                field("Def. Bin"; rec."Default Bin")
                {
                    Caption = 'Casier';
                    ApplicationArea = all;
                    Editable = false;
                }
                field(stkDepart; getStockDepartSelectedYear(rec, FirstDaySelectedYear, LastDaySelectedYear))
                {
                    Caption = 'Stock Départ';
                    ApplicationArea = all;
                    Editable = false;
                }
                field(In; getStkInSelectedYear(rec, FirstDaySelectedYear, LastDaySelectedYear))
                {
                    Caption = 'Entrée';
                    ApplicationArea = all;
                    Editable = false;
                    Style = Favorable;
                }
                field(Out; -getStkOutSelectedYear(rec, FirstDaySelectedYear, LastDaySelectedYear))
                {
                    Caption = 'Sortie';
                    ApplicationArea = all;
                    Editable = false;
                    Style = Unfavorable;
                }
            }
            repeater("Search Item")
            {
                Caption = 'Recherche Article';

                field("No."; "No.")
                {
                    Caption = 'Référence';
                    Editable = false;
                    ApplicationArea = All;
                    Style = strong;

                }
                field("Description structurée"; "Description structurée")
                {
                    Caption = 'Description';
                    ApplicationArea = All;
                    Editable = false;
                    Style = strong;
                }
                field("Available Inventory"; "Available Inventory")
                {
                    Caption = 'Stock';
                    ApplicationArea = All;
                    //StyleExpr = FieldStyleQty;
                }

                field("Default Bin"; "Default Bin")
                {
                    Caption = 'Casier';
                    ApplicationArea = all;
                }
                field("Unit Price"; "Unit Price")
                {
                    Caption = 'PUHT';
                    ApplicationArea = All;
                    Editable = false;
                }
            }
            group(General)
            {
                Caption = 'Statistiques';
                grid("Stat")
                {
                    field(purchOrderCount; purchOrderCount)
                    {
                        Caption = 'Cmd Achat';
                        ApplicationArea = all;
                        Editable = false;
                        StyleExpr = FieldStylepurchOrder;
                    }
                    field(purchRcptCount; purchRcptCount)
                    {
                        Caption = 'Rcpt Achat';
                        ApplicationArea = all;
                        Editable = false;
                        StyleExpr = FieldStylepurchRcpt;
                    }

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
            part(PurchLines; "Purch. Order Subform")
            {
                ApplicationArea = Suite;
                Editable = false;
                SubPageLink = "No." = FIELD("No.");
                UpdatePropagation = Both;
                Visible = purchOrderVisible;
            }
            part(RcptLines; "Purch. Rcpt Line Subform")
            {
                ApplicationArea = Suite;
                Editable = false;
                SubPageLink = "No." = FIELD("No.");
                UpdatePropagation = Both;
                Visible = purchRcptVisible;
            }
            part(SalesLines; "Slaes Order Subform")
            {
                ApplicationArea = Suite;
                Editable = false;
                SubPageLink = "No." = FIELD("No.");
                UpdatePropagation = Both;
                Visible = SalesOrderVisible;
            }
            part(BsLines; "Ligne BS Subform")
            {
                ApplicationArea = Suite;
                Editable = false;
                SubPageLink = "No." = FIELD("No.");
                UpdatePropagation = Both;
                Visible = BsVisible;
            }
            part(RetBsLines; "Ligne Ret BS")
            {
                ApplicationArea = Suite;
                Editable = false;
                SubPageLink = "No." = FIELD("No.");
                UpdatePropagation = Both;
                Visible = RetBsVisible;
            }
            part(BLLines; "Ligne BL Subform")
            {
                ApplicationArea = Suite;
                Editable = false;
                SubPageLink = "No." = FIELD("No.");
                UpdatePropagation = Both;
                Visible = BlVisible;
            }
            part(RetBlLines; "Ligne Ret BL")
            {
                ApplicationArea = Suite;
                Editable = false;
                SubPageLink = "No." = FIELD("No.");
                UpdatePropagation = Both;
                Visible = RetBlVisible;
            }
            part(InvLines; "Ligne Invoice Subform")
            {
                ApplicationArea = Suite;
                Editable = false;
                SubPageLink = "No." = FIELD("No.");
                UpdatePropagation = Both;
                Visible = InvVisible;
            }
            part(CrMemoLines; "Ligne Cr.Memo Subform")
            {
                ApplicationArea = Suite;
                Editable = false;
                SubPageLink = "No." = FIELD("No.");
                UpdatePropagation = Both;
                Visible = CrMemoVisible;
            }

        }
    }

    actions
    {
        area(Processing)
        {
            action(LastYear)
            {
                ApplicationArea = All;
                ShortcutKey = F8;
                Caption = 'Année Précédente';
                Image = PreviousRecord;
                Promoted = true;
                trigger OnAction()
                begin
                    prevYear();
                end;
            }
            action(NextYear)
            {
                ApplicationArea = All;
                ShortcutKey = F9;
                Caption = 'Année Suivante';
                Image = NextRecord;
                Promoted = true;
                trigger OnAction()
                begin
                    nexYear();
                end;
            }
            action(ItemTransaction)
            {
                Caption = 'Transactions articles';
                RunObject = page "Specific Item Ledger Entry";
                RunPageLink = "Item No." = field("No.");
                Image = TransferOrder;
            }
        }
    }

    var
        stockDepart: Decimal;
        currentYear, selectedYear, decrementYear : Integer;
        LastDaySelectedYear, FirstDaySelectedYear : Date;
        purchOrderCount, purchRcptCount, salesOrderCount, bsCount, retBsCount, BlCount, RetBlCount, invoiceCount, crMemoCount : Integer;
        FieldStylepurchOrder, FieldStylepurchRcpt, FieldStylesalesOrder, FieldStyleBS, FieldStyleRetBS, FieldStyleBL, FieldStyleRetBL, FieldStyleInvoice, FieldStyleCrMemo : Text[50];

        purchOrderVisible, purchRcptVisible, SalesOrderVisible, BsVisible, RetBsVisible, BlVisible, RetBlVisible, InvVisible, CrMemoVisible : Boolean;

    trigger OnInit()
    begin
        decrementYear := 0;
        currentYear := System.Date2DMY(Today, 3);
        selectedYear := currentYear - decrementYear;
        FirstDaySelectedYear := System.DMY2Date(1, 1, System.Date2DMY(Today, 3) - decrementYear);
        LastDaySelectedYear := System.DMY2Date(31, 12, System.Date2DMY(Today, 3) - decrementYear);
        //Message('FirstDaySelectedYear %1 - LastDaySelectedYear %2 - decrementYear %3', FirstDaySelectedYear, LastDaySelectedYear, decrementYear);
        purchOrderCount := 0;
        purchRcptCount := 0;
        salesOrderCount := 0;
        bsCount := 0;
        RetBlCount := 0;
        BlCount := 0;
        RetBlCount := 0;
        invoiceCount := 0;
        crMemoCount := 0;
        purchOrderVisible := false;
        purchRcptVisible := false;
        SalesOrderVisible := false;
        BsVisible := false;
        RetBsVisible := false;
        BlVisible := false;
        RetBlVisible := false;
        InvVisible := false;
        CrMemoVisible := false;
    end;

    trigger OnOpenPage()
    begin


    end;

    trigger OnAfterGetCurrRecord()
    var
        PurchaseLine: Record "Purchase Line";
        SalesLine: Record "Sales Line";
        LignearchiveBS: Record "Ligne archive BS";
        SalesShipmentLine: Record "Sales Shipment Line";
        InvoiceLine: Record "Sales Invoice Line";
        CrMemoLine: Record "Sales Cr.Memo Line";
        ReturnReceiptLine: Record "Return Receipt Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        recItem: Record Item;

    begin
        // Calcul nombre de lignes Cmd Achat
        PurchaseLine.Reset();
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Order Date", FirstDaySelectedYear, LastDaySelectedYear);
        PurchaseLine.SetRange("No.", "No.");
        PurchaseLine.SetFilter("Qty. to Receive", '>%1', 0);
        purchOrderCount := PurchaseLine.Count;
        if purchOrderCount > 0 then purchOrderVisible := true else purchOrderVisible := false;


        // Calcul nombre de lignes Rcpt Achat
        PurchRcptLine.Reset();
        PurchRcptLine.SetRange("Posting Date", FirstDaySelectedYear, LastDaySelectedYear);
        PurchRcptLine.SetRange("No.", "No.");
        PurchRcptLine.SetFilter("Qty. Rcd. Not Invoiced", '>%1', 0);
        purchRcptCount := PurchRcptLine.Count;
        if purchRcptCount > 0 then purchRcptVisible := true else purchRcptVisible := false;


        // Calcul nombre de lignes Cmd Vente
        SalesLine.Reset();
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
        SalesLine.SetRange("Posting Date", FirstDaySelectedYear, LastDaySelectedYear);
        SalesLine.SetRange("No.", "No.");
        SalesLine.SetFilter("Qty. to Ship", '>%1', 0);
        salesOrderCount := SalesLine.Count;
        if salesOrderCount > 0 then SalesOrderVisible := true else SalesOrderVisible := false;

        // Calcul nombre lignes BS Archivé
        LignearchiveBS.Reset();
        LignearchiveBS.SetRange("Posting Date", FirstDaySelectedYear, LastDaySelectedYear);
        LignearchiveBS.SetRange("No.", "No.");
        bsCount := LignearchiveBS.Count;
        if bsCount > 0 then BsVisible := true else BsVisible := false;


        // Calcul nombre lignes retour BS 
        ReturnReceiptLine.Reset();
        ReturnReceiptLine.SetFilter(BS, '%1', true);
        ReturnReceiptLine.SetRange("Posting Date", FirstDaySelectedYear, LastDaySelectedYear);
        ReturnReceiptLine.SetRange("No.", "No.");
        retBsCount := ReturnReceiptLine.Count;
        if retBsCount > 0 then RetBsVisible := true else RetBsVisible := false;

        // Calcul nombre lignes BL
        SalesShipmentLine.Reset();
        SalesShipmentLine.SetFilter(BS, '%1', false);
        SalesShipmentLine.SetRange("Posting Date", FirstDaySelectedYear, LastDaySelectedYear);
        SalesShipmentLine.SetRange("No.", "No.");
        SalesShipmentLine.CalcFields(CustDivers);
        SalesShipmentLine.SetFilter(CustDivers, '%1', false);
        BlCount := SalesShipmentLine.Count;
        if BlCount > 0 then BlVisible := true else BlVisible := false;

        // Calcul nombre lignes retour BL
        ReturnReceiptLine.Reset();
        ReturnReceiptLine.SetFilter(BS, '%1', false);
        ReturnReceiptLine.SetRange("Posting Date", FirstDaySelectedYear, LastDaySelectedYear);
        ReturnReceiptLine.SetRange("No.", "No.");
        RetBlCount := ReturnReceiptLine.Count;
        if RetBlCount > 0 then RetBlVisible := true else RetBlVisible := false;


        // Calcul nombre lignes FACTURE
        InvoiceLine.Reset();
        InvoiceLine.SetRange("No.", "No.");
        InvoiceLine.SetRange("Posting Date", FirstDaySelectedYear, LastDaySelectedYear);
        invoiceCount := InvoiceLine.Count;
        if invoiceCount > 0 then InvVisible := true else InvVisible := false;

        // Calcul nombre lignes AVOIR
        CrMemoLine.Reset();
        CrMemoLine.SetRange("Posting Date", FirstDaySelectedYear, LastDaySelectedYear);
        CrMemoLine.SetRange("No.", "No.");
        crMemoCount := CrMemoLine.Count;
        if crMemoCount > 0 then CrMemoVisible := true else CrMemoVisible := false;

        //Filter Magasin Central & Calcul des Champs Flowfield de l'article
        rec.setMgPrincipalFilter(rec);
        rec.CalcFields("Available Inventory", "Default Bin");

        // Set Style 
        FieldStylepurchOrder := SetStyleQte(purchOrderCount);
        FieldStylesalesOrder := SetStyleQte(salesOrderCount);
        FieldStyleBS := SetStyleQte(bsCount);
        FieldStyleRetBS := SetStyleQte(retBsCount);
        FieldStyleBL := SetStyleQte(BlCount);
        FieldStyleRetBL := SetStyleQte(RetBlCount);
        FieldStyleInvoice := SetStyleQte(invoiceCount);
        FieldStyleCrMemo := SetStyleQte(crMemoCount);
        FieldStylepurchRcpt := SetStyleQte(purchRcptCount);
    end;

    procedure SetStyleQte(PDecimal: Decimal): Text[50]
    begin
        IF PDecimal <= 0 THEN exit('Standard') ELSE exit('Unfavorable');
    end;

    local procedure GetCaption(): Text

    begin
        Description := '';
        Description := StrSubstNo('Transaction article du %1 au %2', FirstDaySelectedYear, LastDaySelectedYear);
        exit(Description);
    end;

    local procedure prevYear()
    begin
        decrementYear := decrementYear + 1;
        FirstDaySelectedYear := System.DMY2Date(1, 1, System.Date2DMY(Today, 3) - decrementYear);
        LastDaySelectedYear := System.DMY2Date(31, 12, System.Date2DMY(Today, 3) - decrementYear);
        selectedYear := selectedYear - 1;
        CurrPage.Update();
        updatePartDate(FirstDaySelectedYear, LastDaySelectedYear);

    end;

    local procedure nexYear()
    begin
        decrementYear := decrementYear - 1;
        FirstDaySelectedYear := System.DMY2Date(1, 1, System.Date2DMY(Today, 3) - decrementYear);
        LastDaySelectedYear := System.DMY2Date(31, 12, System.Date2DMY(Today, 3) - decrementYear);
        selectedYear := selectedYear + 1;
        CurrPage.Update();
        updatePartDate(FirstDaySelectedYear, LastDaySelectedYear);
    end;

    local procedure updatePartDate(dateDebut: date; dateFin: date)
    begin
        CurrPage.BLLines.Page.setDate(dateDebut, dateFin);
        CurrPage.BsLines.Page.setDate(dateDebut, dateFin);
        CurrPage.CrMemoLines.Page.setDate(dateDebut, dateFin);
        CurrPage.InvLines.Page.setDate(dateDebut, dateFin);
        CurrPage.PurchLines.Page.setDate(dateDebut, dateFin);
        CurrPage.RcptLines.Page.setDate(dateDebut, dateFin);
        CurrPage.RetBlLines.Page.setDate(dateDebut, dateFin);
        CurrPage.RetBsLines.Page.setDate(dateDebut, dateFin);
        CurrPage.SalesLines.Page.setDate(dateDebut, dateFin);
    end;

    local procedure updateQtyByYear(recItem: Record Item; dateDebut: date; dateFin: date)
    begin

    end;

    local procedure getStockDepartSelectedYear(recItem: Record Item; dateDebut: date; dateFin: date): Decimal
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        stkDepart: Decimal;
    begin
        stkDepart := 0;
        ItemLedgerEntry.SetRange("Item No.", recItem."No.");
        ItemLedgerEntry.SetFilter("Posting Date", '..%1', dateDebut - 1);
        if ItemLedgerEntry.FindSet() then begin
            repeat
                stkDepart := stkDepart + ItemLedgerEntry.Quantity;
            until ItemLedgerEntry.Next() = 0;
        end;
        exit(stkDepart);
    end;

    local procedure getStkInSelectedYear(recItem: Record Item; dateDebut: date; dateFin: date): Decimal
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        stkIn: Decimal;
    begin
        stkIn := 0;
        ItemLedgerEntry.SetRange("Item No.", recItem."No.");
        ItemLedgerEntry.SetFilter("Posting Date", '%1..%2', dateDebut, dateFin);
        ItemLedgerEntry.SetFilter("Entry Type", 'Purchase|Positive Adjmt.');
        if ItemLedgerEntry.FindSet() then begin
            repeat
                stkIn := stkIn + ItemLedgerEntry.Quantity;
            until ItemLedgerEntry.Next() = 0;
        end;
        exit(stkIn);
    end;

    local procedure getStkOutSelectedYear(recItem: Record Item; dateDebut: date; dateFin: date): Decimal
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        stkOut: Decimal;
    begin
        stkOut := 0;
        ItemLedgerEntry.SetRange("Item No.", recItem."No.");
        ItemLedgerEntry.SetFilter("Posting Date", '%1..%2', dateDebut, dateFin);
        ItemLedgerEntry.SetFilter("Entry Type", 'Sale|Negative Adjmt.');
        if ItemLedgerEntry.FindSet() then begin
            repeat
                stkOut := stkOut + ItemLedgerEntry.Quantity;
            until ItemLedgerEntry.Next() = 0;
        end;
        exit(stkOut);
    end;

}