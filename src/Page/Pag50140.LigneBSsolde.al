page 50140 "Ligne BS solde"
{
    AutoSplitKey = true;
    Caption = 'Panier BS à facturer';
    Editable = true;
    LinksAllowed = false;
    PageType = List;
    UsageCategory = Lists;
    ApplicationArea = all;
    SourceTable = "Sales Shipment Line";
    SourceTableView = sorting("Document No.", "Line No.") where(BS = const(true), "Quantity Invoiced" = filter(= 0), solde = filter(true), "Qty BS To Invoice" = filter(> 0));
    Permissions = tabledata "Sales Shipment Line" = rm;

    layout
    {
        area(content)
        {
            group("Ligne bon de sortie")
            {
                repeater(Control1)
                {
                    ShowCaption = false;
                    field("Selected line"; "Selected line")
                    {
                        ApplicationArea = all;
                        Caption = '';
                    }
                    field(Type; Type)
                    {
                        ApplicationArea = Advanced;
                        ToolTip = 'Specifies the line type.';
                        Editable = false;
                    }
                    field("Document No."; "Document No.")
                    {
                        ApplicationArea = Basic, Suite;
                        Editable = false;
                    }
                    field("line No."; "line No.")
                    {
                        ApplicationArea = Basic, Suite;
                        Editable = false;
                    }
                    field("No."; "No.")
                    {
                        ApplicationArea = Basic, Suite;
                        Editable = false;
                        ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                    }
                    field("Cross-Reference No."; "Cross-Reference No.")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the cross-referenced item number. If you enter a cross reference between yours and your vendor''s or customer''s item number, then this number will override the standard item number when you enter the cross-reference number on a sales or purchase document.';
                        Visible = false;
                        Editable = false;
                    }
                    field("Variant Code"; "Variant Code")
                    {
                        ApplicationArea = Planning;
                        ToolTip = 'Specifies the variant of the item on the line.';
                        Visible = false;
                        Editable = false;
                    }
                    field(Description; Description)
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies a description of the record.';
                        Editable = false;
                    }
                    field("Return Reason Code"; "Return Reason Code")
                    {
                        ApplicationArea = Suite;
                        ToolTip = 'Specifies the code explaining why the item was returned.';
                        Visible = false;
                        Editable = false;
                    }
                    field("Location Code"; "Location Code")
                    {
                        ApplicationArea = Location;
                        Editable = false;
                        ToolTip = 'Specifies the location from where inventory items to the customer on the sales document are to be shipped by default.';
                    }
                    field("Bin Code"; "Bin Code")
                    {
                        ApplicationArea = Warehouse;
                        ToolTip = 'Specifies the bin where the items are picked or put away.';
                        Visible = false;
                        Editable = false;
                    }
                    field(Quantity; Quantity)
                    {
                        ApplicationArea = Basic, Suite;
                        BlankZero = true;
                        Editable = false;
                        ToolTip = 'Specifies the number of units of the item specified on the line.';
                    }
                    field("Unit of Measure Code"; "Unit of Measure Code")
                    {
                        ApplicationArea = Basic, Suite;
                        Editable = false;
                        ToolTip = 'Specifies how each unit of the item or resource is measured, such as in pieces or hours. By default, the value in the Base Unit of Measure field on the item or resource card is inserted.';
                    }
                    field("Unit of Measure"; "Unit of Measure")
                    {
                        ApplicationArea = Suite;
                        ToolTip = 'Specifies the name of the item or resource''s unit of measure, such as piece or hour.';
                        Visible = false;
                        Editable = false;
                    }
                    field("Quantity Order"; "Quantity Order")
                    {
                        ApplicationArea = All;
                        Style = Strong;
                        Editable = false;
                    }
                    field("Unit Price"; "Unit Price")
                    {
                        ApplicationArea = All;
                        Editable = false;
                    }
                    field("Unit Cost"; "Unit Cost")
                    {
                        ApplicationArea = All;
                        Style = Strong;
                        Editable = false;
                    }
                    field("Prix Vente 1"; "Prix Vente 1")
                    {
                        ApplicationArea = All;
                        Style = StrongAccent;
                        ToolTip = 'Prix Vente 1 (coût + 20%)';
                        Editable = false;
                    }
                    field("Prix Vente 2"; "Prix Vente 2")
                    {
                        ApplicationArea = All;
                        Style = Favorable;
                        ToolTip = 'Prix Vente remise (Prix Vente 1 - 10%)';
                        Editable = false;
                    }
                    field("Montant ligne HT BS"; "Montant ligne HT BS")
                    {
                        ApplicationArea = All;
                        Style = Strong;
                        Editable = false;
                    }
                    field("Montant ligne TTC BS"; "Montant ligne TTC BS")
                    {
                        ApplicationArea = All;
                        Style = Strong;
                        Editable = false;
                    }
                    // field("Line Amount Order"; "Line Amount Order")
                    // {
                    //     ApplicationArea = All;
                    //     Style = Strong;
                    // }
                    field("Line Amount HT"; "Line Amount HT")
                    {
                        ApplicationArea = All;
                        Editable = false;
                    }
                    field("Line Amount"; "Line Amount")
                    {
                        ApplicationArea = All;
                        Style = Attention;
                        Editable = false;
                    }

                    field(BS; BS)
                    {
                        ApplicationArea = All;
                        Editable = false;
                    }
                    field("Quantity Invoiced"; "Quantity Invoiced")
                    {
                        ApplicationArea = Basic, Suite;
                        BlankZero = true;
                        Editable = false;
                        ToolTip = 'Specifies how many units of the item on the line have been posted as invoiced.';
                    }
                    field("Qty. Shipped Not Invoiced"; "Qty. Shipped Not Invoiced")
                    {
                        ApplicationArea = Basic, Suite;
                        Editable = false;
                        ToolTip = 'Specifies the quantity of the shipped item that has been posted as shipped but that has not yet been posted as invoiced.';
                        Visible = false;
                    }
                    field("Requested Delivery Date"; "Requested Delivery Date")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the date that the customer has asked for the order to be delivered.';
                        Visible = false;
                        Editable = false;
                    }
                    field("Promised Delivery Date"; "Promised Delivery Date")
                    {
                        ApplicationArea = OrderPromising;
                        ToolTip = 'Specifies the date that you have promised to deliver the order, as a result of the Order Promising function.';
                        Visible = false;
                        Editable = false;
                    }
                    field("Planned Delivery Date"; "Planned Delivery Date")
                    {
                        ApplicationArea = Basic, Suite;
                        Editable = false;
                        ToolTip = 'Specifies the planned date that the shipment will be delivered at the customer''s address. If the customer requests a delivery date, the program calculates whether the items will be available for delivery on this date. If the items are available, the planned delivery date will be the same as the requested delivery date. If not, the program calculates the date that the items are available for delivery and enters this date in the Planned Delivery Date field.';
                    }
                    field("Planned Shipment Date"; "Planned Shipment Date")
                    {
                        ApplicationArea = Basic, Suite;
                        Editable = false;
                        ToolTip = 'Specifies the date that the shipment should ship from the warehouse. If the customer requests a delivery date, the program calculates the planned shipment date by subtracting the shipping time from the requested delivery date. If the customer does not request a delivery date or the requested delivery date cannot be met, the program calculates the content of this field by adding the shipment time to the shipping date.';
                    }
                    field("Shipment Date"; "Shipment Date")
                    {
                        ApplicationArea = Basic, Suite;
                        Editable = false;
                        ToolTip = 'Specifies when items on the document are shipped or were shipped. A shipment date is usually calculated from a requested delivery date plus lead time.';
                        Visible = true;
                    }
                    field("Shipping Time"; "Shipping Time")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies how long it takes from when the items are shipped from the warehouse to when they are delivered.';
                        Visible = false;
                        Editable = false;
                    }
                    field("Job No."; "Job No.")
                    {
                        ApplicationArea = Jobs;
                        ToolTip = 'Specifies the number of the related job.';
                        Visible = false;
                        Editable = false;
                    }
                    field("Job Task No."; "Job Task No.")
                    {
                        ApplicationArea = Jobs;
                        ToolTip = 'Specifies the number of the related job task.';
                        Visible = false;
                        Editable = false;
                    }
                    field("Outbound Whse. Handling Time"; "Outbound Whse. Handling Time")
                    {
                        ApplicationArea = Warehouse;
                        ToolTip = 'Specifies a date formula for the time it takes to get items ready to ship from this location. The time element is used in the calculation of the delivery date as follows: Shipment Date + Outbound Warehouse Handling Time = Planned Shipment Date + Shipping Time = Planned Delivery Date.';
                        Visible = false;
                        Editable = false;
                    }
                    field("Appl.-to Item Entry"; "Appl.-to Item Entry")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the number of the item ledger entry that the document or journal line is applied to.';
                        Visible = false;
                        Editable = false;
                    }
                    field(Correction; Correction)
                    {
                        ApplicationArea = Basic, Suite;
                        Editable = false;
                        ToolTip = 'Specifies that this sales shipment line has been posted as a corrective entry.';
                        Visible = false;
                    }
                    field("Keep Init. Prices"; "Keep Init. Prices")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Spécifie si on garde les prix initiaux ou non.';
                        Editable = false;
                    }

                }
            }
            group("Total Selected Line")
            {
                Caption = 'Total des lignes sélectionées';
                field(TotalHTSelctLine; TotalHTSelctLine)
                {
                    ApplicationArea = All;
                    Style = Strong;
                    Editable = false;
                }
                field(TotalTTCSelctLine; TotalTTCSelctLine)
                {
                    ApplicationArea = All;
                    Style = Strong;
                    Editable = false;
                }
            }
            group(Totalisation)
            {
                field(TotalHT; TotalHT)
                {
                    ApplicationArea = All;
                    Style = Strong;
                    Editable = false;
                }
                field(TotalTTC; TotalTTC)
                {
                    ApplicationArea = All;
                    Style = Strong;
                    Editable = false;
                }
            }

        }
    }

    actions
    {
        area(processing)
        {
            action(TransformtoBL)
            {
                AccessByPermission = TableData Dimension = R;
                ApplicationArea = Dimensions;
                Caption = 'Transformer en BL';
                Image = Dimensions;
                Promoted = true;
                // PromotedCategory = Category5;
                // PromotedIsBig = true;
                ToolTip = 'Transformer les bon de sortie en bon de livraison';

                trigger OnAction()
                var
                    PostSalesline: Record "Sales Shipment line";
                    txtmessage: label 'pas de bon sortie sélectionné';
                begin
                    CurrPage.SETSELECTIONFILTER(PostSalesline);
                    IF PostSalesline.FINDSET THEN begin

                        report.run(50003, TRUE, TRUE, PostSalesline);
                    end;
                end;
            }
            action("Liste des BL")
            {
                ApplicationArea = Suite;
                Caption = 'Liste des BL';
                Image = Statistics;
                Promoted = true;
                // PromotedCategory = Category5;
                // PromotedIsBig = true;
                RunObject = Page "Posted Sales Shipments";
            }
            action("Liste des BS")
            {
                ApplicationArea = Suite;
                Caption = 'Liste des BS';
                Image = Statistics;
                Promoted = true;
                // PromotedCategory = Category5;
                // PromotedIsBig = true;
                RunObject = Page "Liste bon de sortie";
            }
            action(Total)
            {
                Caption = 'Calculer total';
                Image = Totals;
                ApplicationArea = all;
                Promoted = true;
                PromotedCategory = New;
                PromotedIsBig = true;
                // PromotedOnly = true;
                trigger OnAction()
                begin
                    caltot := true;

                end;
            }
            action(keepInitPrices)
            {
                AccessByPermission = TableData "Sales Shipment Line" = Rm;
                ApplicationArea = Dimensions;
                Caption = 'Modifier garder prix initiaux';
                Image = UpdateDescription;
                Promoted = true;

                trigger OnAction()
                var
                    UserSetUp: Record "User Setup";
                begin

                    UserSetUp.Get(UserId);
                    UserSetUp.TestField("Allow Keep Init. Prics");
                    if Rec."Keep Init. Prices" then
                        Rec."Keep Init. Prices" := false
                    else
                        Rec."Keep Init. Prices" := true;
                    Rec.Modify();
                end;
            }
            action("Init Selected Line")
            {
                Caption = 'Initialiser les lignes sélectionnés';
                Image = FilterLines;
                trigger OnAction()
                var
                    SalesShipmentLine: Record "Sales Shipment Line";
                begin
                    SalesShipmentLine.Reset();
                    SalesShipmentLine.SetRange("Selected line", true);
                    if SalesShipmentLine.FindSet() then begin
                        repeat
                            SalesShipmentLine."Selected line" := false;
                            SalesShipmentLine.Modify();
                        until SalesShipmentLine.Next() = 0;
                    end
                end;
            }
            action("Calcul Selected Line")
            {
                Caption = 'Calculer les lignes sélectionnées';
                trigger OnAction()
                var
                    SalesShipLine: Record "Sales Shipment Line";
                begin
                    TotalHTSelctLine := 0;
                    TotalTTCSelctLine := 0;
                    SalesShipLine.Reset();

                    SalesShipLine.SetRange("Quantity Invoiced", 0);
                    SalesShipLine.SetRange(BS, true);
                    SalesShipLine.SetRange("Selected line", true);
                    IF SalesShipLine.FINDSET THEN begin
                        repeat
                            TotalHTSelctLine := TotalHTSelctLine + SalesShipLine."Montant ligne HT BS";
                            TotalTTCSelctLine := TotalTTCSelctLine + SalesShipLine."Montant ligne TTC BS";
                        UNTIL SalesShipLine.NEXT = 0;
                    end;
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        //  ShowShortcutDimCode(ShortcutDimCode);
        // calctotal();
        CalcFields(solde);
    end;

    trigger OnAfterGetCurrRecord()
    var
        myInt: Integer;
    begin
        calctotal();
    end;

    trigger OnClosePage()
    begin
        Shipmentline2.Reset();
        Shipmentline2.SetRange("Selected line", true);
        if Shipmentline2.FindSet() then begin
            repeat
                Shipmentline2."Selected line" := false;
                Shipmentline2.Modify();
            until Shipmentline2.Next() = 0;
        end
    end;

    trigger OnInit()
    var
        ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
    begin
        IsFoundation := ApplicationAreaMgmtFacade.IsFoundationEnabled;
    end;

    trigger OnOpenPage()
    begin
        SetDimensionsVisibility;
    end;

    var
        isSelected: Boolean;
        ShortcutDimCode: array[8] of Code[20];
        IsFoundation: Boolean;
        DimVisible1: Boolean;
        DimVisible2: Boolean;
        DimVisible3: Boolean;
        DimVisible4: Boolean;
        DimVisible5: Boolean;
        DimVisible6: Boolean;
        DimVisible7: Boolean;
        DimVisible8: Boolean;
        TotalTTC: Decimal;
        TotalHT: Decimal;
        TotalHTSelctLine, TotalTTCSelctLine : Decimal;
        Shipmentline, Shipmentline2 : Record "Sales Shipment Line";

    local procedure calctotal()

    begin

        SaleslShptLine.Reset();
        if caltot then begin
            SaleslShptLine.SetRange("Quantity Invoiced", 0);
            SaleslShptLine.SetRange(BS, true);
        end else
            CurrPage.SetSelectionFilter(SaleslShptLine);
        IF SaleslShptLine.FINDSET THEN begin
            TotalHT := 0;
            TotalTTC := 0;
            repeat
                TotalHT := TotalHT + SaleslShptLine."Montant ligne HT BS";
                TotalTTC := TotalTTC + SaleslShptLine."Montant ligne TTC BS";
            UNTIL SaleslShptLine.NEXT = 0;
        end;
        caltot := false;
    end;

    local procedure ShowTracking()
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        TempItemLedgEntry: Record "Item Ledger Entry" temporary;
        TrackingForm: Page "Order Tracking";
    begin
        TestField(Type, Type::Item);
        if "Item Shpt. Entry No." <> 0 then begin
            ItemLedgEntry.Get("Item Shpt. Entry No.");
            TrackingForm.SetItemLedgEntry(ItemLedgEntry);
        end else
            TrackingForm.SetMultipleItemLedgEntries(TempItemLedgEntry,
              DATABASE::"Sales Shipment Line", 0, "Document No.", '', 0, "Line No.");

        TrackingForm.RunModal;
    end;

    local procedure UndoShipmentPosting()
    var
        SalesShptLine: Record "Sales Shipment Line";
        IsHandled: Boolean;
    begin
        SalesShptLine.Copy(Rec);
        CurrPage.SetSelectionFilter(SalesShptLine);
        OnBeforeUndoShipmentPosting(SalesShptLine, IsHandled);
        if not IsHandled then
            CODEUNIT.Run(CODEUNIT::"Undo Sales Shipment Line", SalesShptLine);
    end;

    local procedure PageShowItemSalesInvLines()
    begin
        TestField(Type, Type::Item);
        ShowItemSalesInvLines;
    end;

    procedure ShowDocumentLineTracking()
    var
        DocumentLineTracking: Page "Document Line Tracking";
    begin
        Clear(DocumentLineTracking);
        DocumentLineTracking.SetDoc(
          4, "Document No.", "Line No.", "Blanket Order No.", "Blanket Order Line No.", "Order No.", "Order Line No.");
        DocumentLineTracking.RunModal;
    end;

    local procedure SetDimensionsVisibility()
    var
        DimMgt: Codeunit DimensionManagement;
    begin
        DimVisible1 := false;
        DimVisible2 := false;
        DimVisible3 := false;
        DimVisible4 := false;
        DimVisible5 := false;
        DimVisible6 := false;
        DimVisible7 := false;
        DimVisible8 := false;

        DimMgt.UseShortcutDims(
          DimVisible1, DimVisible2, DimVisible3, DimVisible4, DimVisible5, DimVisible6, DimVisible7, DimVisible8);

        Clear(DimMgt);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUndoShipmentPosting(SalesShipmentLine: Record "Sales Shipment Line"; var IsHandled: Boolean)
    begin
    end;

    var
        SaleslShptLine: Record "Sales Shipment Line";
        caltot: Boolean;
}

