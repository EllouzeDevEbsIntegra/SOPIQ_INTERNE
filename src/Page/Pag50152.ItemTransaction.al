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
    layout
    {
        area(Content)
        {
            grid("Item Details")
            {
                Caption = 'Stat Article';
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
                field(In; rec."Total Achete" + rec."Total Ajust+")
                {
                    Caption = 'Entrée';
                    ApplicationArea = all;
                    Editable = false;
                }
                field(Out; rec."Total Vendu" + rec."Total Ajust-")
                {
                    Caption = 'Sortie';
                    ApplicationArea = all;
                    Editable = false;
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
        purchOrderCount, salesOrderCount, bsCount, retBsCount, BlCount, RetBlCount, invoiceCount, crMemoCount : Integer;
        FieldStylepurchOrder, FieldStylesalesOrder, FieldStyleBS, FieldStyleRetBS, FieldStyleBL, FieldStyleRetBL, FieldStyleInvoice, FieldStyleCrMemo : Text[50];

        purchOrderVisible, SalesOrderVisible, BsVisible, RetBsVisible, BlVisible, RetBlVisible, InvVisible, CrMemoVisible : Boolean;

    trigger OnOpenPage()
    begin
        purchOrderCount := 0;
        salesOrderCount := 0;
        bsCount := 0;
        RetBlCount := 0;
        BlCount := 0;
        RetBlCount := 0;
        invoiceCount := 0;
        crMemoCount := 0;
        purchOrderVisible := false;
        SalesOrderVisible := false;
        BsVisible := false;
        RetBsVisible := false;
        BlVisible := false;
        RetBlVisible := false;
        InvVisible := false;
        CrMemoVisible := false;

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

    begin
        // Calcul nombre de lignes Cmd Achat
        PurchaseLine.Reset();
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("No.", "No.");
        purchOrderCount := PurchaseLine.Count;
        if purchOrderCount > 0 then purchOrderVisible := true else purchOrderVisible := false;

        // Calcul nombre de lignes Cmd Vente
        SalesLine.Reset();
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
        SalesLine.SetRange("No.", "No.");
        salesOrderCount := SalesLine.Count;
        if salesOrderCount > 0 then SalesOrderVisible := true else SalesOrderVisible := false;

        // Calcul nombre lignes BS Archivé
        LignearchiveBS.Reset();
        LignearchiveBS.SetRange("No.", "No.");
        bsCount := LignearchiveBS.Count;
        if bsCount > 0 then BsVisible := true else BsVisible := false;


        // Calcul nombre lignes retour BS 
        ReturnReceiptLine.Reset();
        ReturnReceiptLine.SetFilter(BS, '%1', true);
        ReturnReceiptLine.SetRange("No.", "No.");
        retBsCount := ReturnReceiptLine.Count;
        if retBsCount > 0 then RetBsVisible := true else RetBsVisible := false;

        // Calcul nombre lignes BL
        SalesShipmentLine.Reset();
        SalesShipmentLine.SetFilter(BS, '%1', false);
        SalesShipmentLine.SetRange("No.", "No.");
        SalesShipmentLine.CalcFields(CustDivers);
        SalesShipmentLine.SetFilter(CustDivers, '%1', false);
        BlCount := SalesShipmentLine.Count;
        if BlCount > 0 then BlVisible := true else BlVisible := false;

        // Calcul nombre lignes retour BL
        ReturnReceiptLine.Reset();
        ReturnReceiptLine.SetFilter(BS, '%1', false);
        ReturnReceiptLine.SetRange("No.", "No.");
        RetBlCount := ReturnReceiptLine.Count;
        if RetBlCount > 0 then RetBlVisible := true else RetBlVisible := false;


        // Calcul nombre lignes FACTURE
        InvoiceLine.Reset();
        InvoiceLine.SetRange("No.", "No.");
        invoiceCount := InvoiceLine.Count;
        if invoiceCount > 0 then InvVisible := true else InvVisible := false;

        // Calcul nombre lignes AVOIR
        CrMemoLine.Reset();
        CrMemoLine.SetRange("No.", "No.");
        crMemoCount := CrMemoLine.Count;
        if crMemoCount > 0 then CrMemoVisible := true else CrMemoVisible := false;

        //Filter Magasin Central & Calcul des Champs Flowfield de l'article
        rec.setMgPrincipalFilter(rec);
        rec.CalcFields("Available Inventory", "Total Achete", "Total Vendu", "Total Ajust+", "Total Ajust-", "Default Bin");

        // Set Style 
        FieldStylepurchOrder := SetStyleQte(purchOrderCount);
        FieldStylesalesOrder := SetStyleQte(salesOrderCount);
        FieldStyleBS := SetStyleQte(bsCount);
        FieldStyleRetBS := SetStyleQte(retBsCount);
        FieldStyleBL := SetStyleQte(BlCount);
        FieldStyleRetBL := SetStyleQte(RetBlCount);
        FieldStyleInvoice := SetStyleQte(invoiceCount);
        FieldStyleCrMemo := SetStyleQte(crMemoCount);
    end;

    procedure SetStyleQte(PDecimal: Decimal): Text[50]
    begin
        IF PDecimal <= 0 THEN exit('Standard') ELSE exit('Unfavorable');
    end;
}