page 25006874 "Specific Item Ledger Entry API"
{
    PageType = API;
    Caption = 'Item Ledger Entries';
    APIPublisher = 'sopiq';
    APIGroup = 'interne';
    APIVersion = 'v1.0';
    EntityName = 'specificItemLedgerEntrie';
    EntitySetName = 'specificItemLedgerEntries';
    SourceTable = "specific item ledger entry";
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

                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description of the entry.';
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
                field(UnitofMeasureCode; "Unit of Measure Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the unit of measure for the item in the entry.';
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

                field(EntryNo; "Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the entry, as assigned from the specified number series when the entry was created.';
                }

                field(SourceType; "Source Type")
                {
                    ApplicationArea = Basic;
                    Visible = false;
                }

                field(SourceNo; "Source No.")
                {
                    ApplicationArea = Basic;
                    Visible = false;
                }

                field(SourceName; SourceName)
                {
                    ApplicationArea = Basic;
                    Caption = 'Source Name';
                    ToolTip = 'Specifies the name of the source, based on the Source Type and Source No. fields.';
                    Visible = false;
                }


            }
        }
    }

    actions
    {
    }

    var
        SourceName: Text[250];
        recCustomor: Record Customer;
        recvendor: Record Vendor;
        recItem: Record Item;

    trigger OnAfterGetRecord()
    begin

        Clear(SourceName);
        recCustomor.Reset();
        recvendor.Reset();
        recItem.Reset();

        case rec."Source Type" of
            rec."Source Type"::Customer:
                if recCustomor.GET(rec."Source No.") then
                    SourceName := recCustomor.Name;
            rec."Source Type"::Vendor:
                if recvendor.GET(rec."Source No.") then
                    SourceName := recvendor.Name;
            rec."Source Type"::Item:
                if recItem.GET(rec."Source No.") then
                    SourceName := recItem.Description;
        end;


    end;

}

