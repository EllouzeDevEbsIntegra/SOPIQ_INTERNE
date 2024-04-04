page 50156 "Ligne BS Subform"
{
    Caption = 'Lignes BS';
    LinksAllowed = false;
    PageType = ListPart;
    SourceTable = "Ligne archive BS";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                Editable = false;
                field("Document No."; "Document No.")
                {
                    ApplicationArea = All;
                }
                field("No."; "No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description of the record.';
                }
                field("Location Code"; "Location Code")
                {
                    Caption = 'Magasin';
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the location from where inventory items to the customer on the sales document are to be shipped by default.';
                }
                field("Bin Code"; "Bin Code")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Casier';
                    ToolTip = 'Specifies the bin where the items are picked or put away.';
                }
                field(Quantity; Quantity)
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    Caption = 'Qte';
                    ToolTip = 'Specifies the number of units of the item specified on the line.';
                }
                field("Unit of Measure Code"; "Unit of Measure Code")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Unité';
                    ToolTip = 'Specifies how each unit of the item or resource is measured, such as in pieces or hours. By default, the value in the Base Unit of Measure field on the item or resource card is inserted.';
                }
                field("Unit Price"; "Unit Price")
                {
                    ApplicationArea = All;
                    Caption = 'Prix';
                }
                field("Unit Cost"; "Unit Cost")
                {
                    ApplicationArea = All;
                    Visible = false;
                }
                field("VAT %"; "VAT %")
                {
                    ApplicationArea = All;
                    Visible = false;
                }
                field("Line Discount %"; "Line Discount %")
                {
                    ApplicationArea = All;
                    Visible = false;
                    DecimalPlaces = 2 : 2;
                }
                field("% Discount"; "% Discount")
                {
                    ApplicationArea = All;
                    DecimalPlaces = 2 : 2;
                    Caption = 'Rem%';
                }
                field("Line Amount HT"; "Line Amount HT")
                {
                    ApplicationArea = All;
                    Caption = 'Total HT';
                }
                field("Line Amount"; "Line Amount")
                {
                    ApplicationArea = All;
                    Style = Attention;
                    Caption = 'Total TTC';
                }
                field("Qty. Shipped Not Invoiced"; "Qty. Shipped Not Invoiced")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Visible = false;
                    ToolTip = 'Specifies the quantity of the shipped item that has been posted as shipped but that has not yet been posted as invoiced.';
                }
                field("Quantity Invoiced"; "Quantity Invoiced")
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    Caption = 'Qte Facturée';
                    ToolTip = 'Specifies how many units of the item on the line have been posted as invoiced.';
                }
                field("Related Invoice No. "; "Related Invoice No. ")
                {
                    ApplicationArea = All;
                    Caption = 'Fact. Liée';
                }

                field("No. BL"; "No. BL")
                {
                    ApplicationArea = All;
                    Caption = 'BL. Lié';
                }


            }
        }
    }

    // actions
    // {
    //     area(processing)
    //     {
    //         group("F&unctions")
    //         {
    //             Caption = 'F&unctions';
    //             Image = "Action";
    //             action("Order Tra&cking")
    //             {
    //                 ApplicationArea = Basic, Suite;
    //                 Caption = 'Order Tra&cking';
    //                 Image = OrderTracking;
    //                 ToolTip = 'Tracks the connection of a supply to its corresponding demand. This can help you find the original demand that created a specific production order or purchase order.';

    //                 trigger OnAction()
    //                 begin
    //                     ShowTracking;
    //                 end;
    //             }
    //             action(UndoShipment)
    //             {
    //                 ApplicationArea = Basic, Suite;
    //                 Caption = '&Undo Shipment';
    //                 Image = UndoShipment;
    //                 ToolTip = 'Withdraw the line from the shipment. This is useful for making corrections, because the line is not deleted. You can make changes and post it again.';

    //                 trigger OnAction()
    //                 begin
    //                     UndoShipmentPosting;
    //                 end;
    //             }
    //         }
    //         group("&Line")
    //         {
    //             Caption = '&Line';
    //             Image = Line;
    //             action(Dimensions)
    //             {
    //                 AccessByPermission = TableData Dimension = R;
    //                 ApplicationArea = Dimensions;
    //                 Caption = 'Dimensions';
    //                 Image = Dimensions;
    //                 ShortCutKey = 'Alt+D';
    //                 ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';

    //                 trigger OnAction()
    //                 begin
    //                     ShowDimensions;
    //                 end;
    //             }
    //             action(Comments)
    //             {
    //                 ApplicationArea = Comments;
    //                 Caption = 'Co&mments';
    //                 Image = ViewComments;
    //                 ToolTip = 'View or add comments for the record.';

    //                 // trigger OnAction()
    //                 // begin
    //                 //     ShowLineComments;
    //                 // end;
    //             }
    //             action(ItemTrackingEntries)
    //             {
    //                 ApplicationArea = ItemTracking;
    //                 Caption = 'Item &Tracking Entries';
    //                 Image = ItemTrackingLedger;
    //                 ToolTip = 'View serial or lot numbers that are assigned to items.';

    //                 trigger OnAction()
    //                 begin
    //                     ShowItemTrackingLines;
    //                 end;
    //             }
    //             action("Assemble-to-Order")
    //             {
    //                 AccessByPermission = TableData "BOM Component" = R;
    //                 ApplicationArea = Assembly;
    //                 Caption = 'Assemble-to-Order';
    //                 ToolTip = 'View the linked assembly order if the shipment was for an assemble-to-order sale.';

    //                 // trigger OnAction()
    //                 // begin
    //                 //     ShowAsmToOrder;
    //                 // end;
    //             }
    //             action(ItemInvoiceLines)
    //             {
    //                 ApplicationArea = Basic, Suite;
    //                 Caption = 'Item Invoice &Lines';
    //                 Image = ItemInvoice;
    //                 ToolTip = 'View posted sales invoice lines for the item.';

    //                 // trigger OnAction()
    //                 // begin
    //                 //     PageShowItemSalesInvLines;
    //                 // end;
    //             }
    //             action(DocumentLineTracking)
    //             {
    //                 ApplicationArea = Basic, Suite;
    //                 Caption = 'Document &Line Tracking';
    //                 Image = Navigate;
    //                 ToolTip = 'View related open, posted, or archived documents or document lines.';

    //                 trigger OnAction()
    //                 begin
    //                     ShowDocumentLineTracking;
    //                 end;
    //             }
    //         }
    //     }
    // }

    trigger OnAfterGetRecord()
    begin
        //   ShowShortcutDimCode(ShortcutDimCode);
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

    // local procedure PageShowItemSalesInvLines()
    // begin
    //     TestField(Type, Type::Item);
    //     ShowItemSalesInvLines;
    // end;

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
}

