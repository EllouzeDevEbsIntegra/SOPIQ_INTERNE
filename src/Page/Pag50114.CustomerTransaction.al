page 50114 "Customer Transaction"
{
    PageType = List;
    SourceTable = Customer;
    SourceTableView = sorting("No.");
    UsageCategory = Lists;
    ApplicationArea = all;
    ModifyAllowed = false;
    DeleteAllowed = false;
    InsertAllowed = false;
    Caption = 'Transactions Client Détaillées';
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
            part(SalesLines; "Slaes Order Subform")
            {
                ApplicationArea = Suite;
                Editable = false;
                SubPageLink = "Bill-to Customer No." = FIELD("No.");
                UpdatePropagation = Both;
                Visible = SalesOrderVisible;
            }
            part(BsLines; "Ligne BS Subform")
            {
                ApplicationArea = Suite;
                Editable = false;
                SubPageLink = "Bill-to Customer No." = FIELD("No.");
                UpdatePropagation = Both;
                Visible = BsVisible;
            }
            part(RetBsLines; "Ligne Ret BS")
            {
                ApplicationArea = Suite;
                Editable = false;
                SubPageLink = "Bill-to Customer No." = FIELD("No.");
                UpdatePropagation = Both;
                Visible = RetBsVisible;
            }
            part(BLLines; "Ligne BL Subform")
            {
                ApplicationArea = Suite;
                Editable = false;
                SubPageLink = "Bill-to Customer No." = FIELD("No.");
                UpdatePropagation = Both;
                Visible = BlVisible;
            }
            part(RetBlLines; "Ligne Ret BL")
            {
                ApplicationArea = Suite;
                Editable = false;
                SubPageLink = "Bill-to Customer No." = FIELD("No.");
                UpdatePropagation = Both;
                Visible = RetBlVisible;
            }
            part(InvLines; "Ligne Invoice Subform")
            {
                ApplicationArea = Suite;
                Editable = false;
                SubPageLink = "Bill-to Customer No." = FIELD("No.");
                UpdatePropagation = Both;
                Visible = InvVisible;
            }
            part(CrMemoLines; "Ligne Cr.Memo Subform")
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

    end;

    trigger OnAfterGetCurrRecord()
    var
        SalesLine: Record "Sales Line";
        LignearchiveBS: Record "Ligne archive BS";
        SalesShipmentLine: Record "Sales Shipment Line";
        InvoiceLine: Record "Sales Invoice Line";
        CrMemoLine: Record "Sales Cr.Memo Line";
        ReturnReceiptLine: Record "Return Receipt Line";

    begin

        // Calcul nombre de lignes Cmd Vente
        SalesLine.Reset();
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
        SalesLine.SetRange("Bill-to Customer No.", "No.");
        salesOrderCount := SalesLine.Count;
        if salesOrderCount > 0 then SalesOrderVisible := true else SalesOrderVisible := false;

        // Calcul nombre lignes BS Archivé
        LignearchiveBS.Reset();
        LignearchiveBS.SetRange("Bill-to Customer No.", "No.");
        bsCount := LignearchiveBS.Count;
        if bsCount > 0 then BsVisible := true else BsVisible := false;


        // Calcul nombre lignes retour BS 
        ReturnReceiptLine.Reset();
        ReturnReceiptLine.SetFilter(BS, '%1', true);
        ReturnReceiptLine.SetRange("Bill-to Customer No.", "No.");
        retBsCount := ReturnReceiptLine.Count;
        if retBsCount > 0 then RetBsVisible := true else RetBsVisible := false;

        // Calcul nombre lignes BL
        SalesShipmentLine.Reset();
        SalesShipmentLine.SetFilter(BS, '%1', false);
        SalesShipmentLine.SetRange("Bill-to Customer No.", "No.");
        SalesShipmentLine.CalcFields(CustDivers);
        SalesShipmentLine.SetFilter(CustDivers, '%1', false);
        BlCount := SalesShipmentLine.Count;
        if BlCount > 0 then BlVisible := true else BlVisible := false;

        // Calcul nombre lignes retour BL
        ReturnReceiptLine.Reset();
        ReturnReceiptLine.SetFilter(BS, '%1', false);
        ReturnReceiptLine.SetRange("Bill-to Customer No.", "No.");
        RetBlCount := ReturnReceiptLine.Count;
        if RetBlCount > 0 then RetBlVisible := true else RetBlVisible := false;


        // Calcul nombre lignes FACTURE
        InvoiceLine.Reset();
        InvoiceLine.SetRange("Bill-to Customer No.", "No.");
        invoiceCount := InvoiceLine.Count;
        if invoiceCount > 0 then InvVisible := true else InvVisible := false;

        // Calcul nombre lignes AVOIR
        CrMemoLine.Reset();
        CrMemoLine.SetRange("Bill-to Customer No.", "No.");
        crMemoCount := CrMemoLine.Count;
        if crMemoCount > 0 then CrMemoVisible := true else CrMemoVisible := false;


        // Set Style 
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