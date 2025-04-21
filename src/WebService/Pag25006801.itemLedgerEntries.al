page 25006801 "itemLedgerEntries"
{
    PageType = API;
    Caption = 'Item Ledger Entries';
    APIPublisher = 'sopiq';
    APIGroup = 'interne';
    APIVersion = 'v1.0';
    EntityName = 'itemLedgerEntries';
    EntitySetName = 'itemLedgerEntries';
    SourceTable = "Item Ledger Entry";
    DelayedInsert = true;
    ODataKeyFields = SystemId;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(id; systemId)
                {
                    ApplicationArea = All;
                    Caption = 'id', Locked = true;
                    Editable = false;
                }
                field(PostingDate; "Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the posting date for the entry.';
                }
                field(EntryType; "Entry Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies which type of transaction that the entry is created from.';
                }
                field(DocumentType; "Document Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies what type of document was posted to create the item ledger entry.';
                }
                field(DocumentNo; "Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the document number on the entry. The document is the voucher that the entry was based on, for example, a receipt.';
                }
                field(ExternalDocumentNo; "External Document No.")
                {
                    ApplicationArea = Basic;
                    Visible = false;
                }
                field(DocumentLineNo; "Document Line No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the line on the posted document that corresponds to the item ledger entry.';
                    Visible = false;
                }
                field(ItemNo; "Item No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the item in the entry.';
                }
                field(VariantCode; "Variant Code")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the variant of the item on the line.';
                    Visible = false;
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description of the entry.';
                }
                field(ReturnReasonCode; "Return Reason Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the code explaining why the item was returned.';
                    Visible = false;
                }
                field(GlobalDimension1Code; "Global Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for the global dimension that is linked to the record or entry for analysis purposes. Two global dimensions, typically for the company''s most important activities, are available on all cards, documents, reports, and lists.';
                    Visible = false;
                }
                field(GlobalDimension2Code; "Global Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for the global dimension that is linked to the record or entry for analysis purposes. Two global dimensions, typically for the company''s most important activities, are available on all cards, documents, reports, and lists.';
                    Visible = false;
                }
                field(ExpirationDate; "Expiration Date")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the last date that the item on the line can be used.';
                    Visible = false;
                }
                field(SerialNo; "Serial No.")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies a serial number if the posted item carries such a number.';
                    Visible = false;

                    trigger OnDrillDown()
                    var
                        ItemTrackingManagement: Codeunit "Item Tracking Management";
                    begin
                        ItemTrackingManagement.LookupLotSerialNoInfo("Item No.", "Variant Code", 0, "Serial No.");
                    end;
                }
                field(VehicleAccountingCycleNo; "Vehicle Accounting Cycle No.")
                {
                    ApplicationArea = Basic;
                    Visible = false;
                }
                field(VehicleRegistrationNo; "Vehicle Registration No.")
                {
                    ApplicationArea = Basic;
                    Visible = false;
                }
                field(LotNo; "Lot No.")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies a lot number if the posted item carries such a number.';
                    Visible = false;

                    trigger OnDrillDown()
                    var
                        ItemTrackingManagement: Codeunit "Item Tracking Management";
                    begin
                        ItemTrackingManagement.LookupLotSerialNoInfo("Item No.", "Variant Code", 1, "Lot No.");
                    end;
                }
                field(LocationCode; "Location Code")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the code for the location that the entry is linked to.';
                }

                field(Quantity; Quantity)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of units of the item in the item entry.';
                }
                field(InvoicedQuantity; "Invoiced Quantity")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how many units of the item on the line have been invoiced.';
                    Visible = true;
                }
                field(RemainingQuantity; "Remaining Quantity")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the quantity in the Quantity field that remains to be processed.';
                    Visible = true;
                }
                field(ShippedQtyNotReturned; "Shipped Qty. Not Returned")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the quantity for this item ledger entry that was shipped and has not yet been returned.';
                    Visible = false;
                }
                field(ReservedQuantity; "Reserved Quantity")
                {
                    ApplicationArea = Reservation;
                    ToolTip = 'Specifies how many units of the item on the line have been reserved.';
                    Visible = false;
                }
                field(QtyperUnitofMeasure; "Qty. per Unit of Measure")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the quantity per item unit of measure.';
                    Visible = false;
                }
                field(SalesAmountExpected; "Sales Amount (Expected)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the expected sales amount, in LCY.';
                    Visible = false;
                }
                field(SalesAmountActual; "Sales Amount (Actual)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the sales amount, in LCY.';
                }
                field(CostAmountExpected; "Cost Amount (Expected)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the expected cost, in LCY, of the quantity posting.';
                    Visible = false;
                }
                field(CostAmountActual; "Cost Amount (Actual)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the adjusted cost, in LCY, of the quantity posting.';
                }
                field(CostAmountNonInvtbl; "Cost Amount (Non-Invtbl.)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the adjusted non-inventoriable cost, that is an item charge assigned to an outbound entry.';
                }
                field(CostAmountExpectedACY; "Cost Amount (Expected) (ACY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the expected cost, in ACY, of the quantity posting.';
                    Visible = false;
                }
                field(CostAmountActualACY; "Cost Amount (Actual) (ACY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the adjusted cost of the entry, in the additional reporting currency.';
                    Visible = false;
                }
                field(CostAmountNonInvtblACY; "Cost Amount (Non-Invtbl.)(ACY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the adjusted non-inventoriable cost, that is, an item charge assigned to an outbound entry in the additional reporting currency.';
                    Visible = false;
                }
                field(CompletelyInvoiced; "Completely Invoiced")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the entry has been fully invoiced or if more posted invoices are expected. Only completely invoiced entries can be revalued.';
                    Visible = false;
                }
                field(Open; Open)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether the entry has been fully applied to.';
                }
                field(DropShipment; "Drop Shipment")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if your vendor ships the items directly to your customer.';
                    Visible = false;
                }
                field(AssembletoOrder; "Assemble to Order")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies if the posting represents an assemble-to-order sale.';
                    Visible = false;
                }
                field(AppliedEntrytoAdjust; "Applied Entry to Adjust")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether there is one or more applied entries, which need to be adjusted.';
                    Visible = false;
                }
                field(OrderType; "Order Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies which type of order that the entry was created in.';
                }
                field(OrderNo; "Order No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the order that created the entry.';
                    Visible = false;
                }
                field(OrderLineNo; "Order Line No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the line number of the order that created the entry.';
                    Visible = false;
                }
                field(ProdOrderCompLineNo; "Prod. Order Comp. Line No.")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the line number of the production order component.';
                    Visible = false;
                }
                field(EntryNo; "Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the entry, as assigned from the specified number series when the entry was created.';
                }
                field(JobNo; "Job No.")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the number of the related job.';
                    Visible = false;
                }
                field(JobTaskNo; "Job Task No.")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the number of the related job task.';
                    Visible = false;
                }
                field(DimensionSetID; "Dimension Set ID")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies a reference to a combination of dimension values. The actual values are stored in the Dimension Set Entry table.';
                    Visible = false;
                }
                field(TransferSourceType; "Transfer Source Type")
                {
                    ApplicationArea = Basic;
                    Visible = false;
                }
                field(TransferSourceSubtype; "Transfer Source Subtype")
                {
                    ApplicationArea = Basic;
                    Visible = false;
                }
                field(TransferSourceNo; "Transfer Source No.")
                {
                    ApplicationArea = Basic;
                }
                field(VIN; VIN)
                {
                    ApplicationArea = Basic;
                    Visible = false;
                }
                field(SourceNo; "Source No.")
                {
                    ApplicationArea = Basic;
                    Visible = false;
                }
                field(SourceType; "Source Type")
                {
                    ApplicationArea = Basic;
                    Visible = false;
                }
                field(DealTypeCode; "Deal Type Code")
                {
                    ApplicationArea = Basic;
                }
            }
        }
    }

    actions
    {
    }

}

