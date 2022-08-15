page 50100 "Sales line"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "Sales Line";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Document No"; "Document No.")
                {
                    ApplicationArea = Advanced;
                    Editable = false;

                }
                field("No."; "No.")
                {
                    ApplicationArea = Basic;
                    Editable = false;
                }

                field(Description; Description)
                {
                    ApplicationArea = Basic;
                    Editable = false;
                }

                field("Location Code"; "Location Code")
                {
                    ApplicationArea = Location;
                    Editable = false;
                }
                field("Bin Code"; "Bin Code")
                {
                    ApplicationArea = Warehouse;
                    Editable = false;
                    Visible = false;
                }

                field(Quantity; Quantity)
                {
                    ApplicationArea = Basic;
                    Editable = false;
                }
                field("Unit Cost (LCY)"; "Unit Cost (LCY)")
                {
                    ApplicationArea = Basic;
                    Visible = false;
                    Editable = false;
                }
                field(OrderingPriceTypeCode; "Ordering Price Type Code")
                {
                    ApplicationArea = Basic;
                    Visible = false;
                    Editable = false;
                }
                field("Unit Price"; "Unit Price")
                {
                    ApplicationArea = Basic;
                    BlankZero = true;
                    Editable = false;
                }
                field("Initial Price"; "Initial Unit Price")
                {
                    ApplicationArea = Basic;
                    Editable = false;
                }


                field("Tax Group Code"; "Tax Group Code")
                {
                    ApplicationArea = SalesTax;
                    Editable = false;

                }
                field("Line Discount %"; "Line Discount %")
                {
                    ApplicationArea = Basic;
                    BlankZero = true;
                    Editable = false;

                }
                field("Line Amount"; "Line Amount")
                {
                    ApplicationArea = Basic;
                    BlankZero = true;
                    Editable = false;

                }

                field("Line Discount Amount"; "Line Discount Amount")
                {
                    ApplicationArea = Basic;
                    ToolTip = 'Specifies the discount amount that is granted for the item on the line.';
                    Visible = false;
                    Editable = false;

                }

                field("Prepmt. Line Amount"; "Prepmt. Line Amount")
                {
                    ApplicationArea = Prepayments;
                    ToolTip = 'Specifies the prepayment amount of the line in the currency of the sales document if a prepayment percentage is specified for the sales line.';
                    Visible = false;
                    Editable = false;
                }
                field("Prepmt. Amt. Inv."; "Prepmt. Amt. Inv.")
                {
                    ApplicationArea = Prepayments;
                    ToolTip = 'Specifies the prepayment amount that has already been invoiced to the customer for this sales line.';
                    Visible = false;
                    Editable = false;
                }

                field("Quantity Shipped"; "Quantity Shipped")
                {
                    ApplicationArea = Basic;
                    BlankZero = true;
                    QuickEntry = false;
                    Editable = false;
                }
                field("Qty. to Invoice"; "Qty. to Invoice")
                {
                    ApplicationArea = Basic;
                    BlankZero = true;
                    Editable = false;
                }
                field("Quantity Invoiced"; "Quantity Invoiced")
                {
                    ApplicationArea = Basic;
                    BlankZero = true;
                    Editable = false;
                }
                field("Prepmt Amt Deducted"; "Prepmt Amt Deducted")
                {
                    ApplicationArea = Prepayments;
                    Editable = false;
                    Visible = false;
                }


                field("Shipment Date"; "Shipment Date")
                {
                    ApplicationArea = Basic;
                    QuickEntry = false;
                    Editable = false;

                }
                field("Shipping Agent Code"; "Shipping Agent Code")
                {
                    ApplicationArea = Suite;
                    Editable = false;
                    Visible = false;
                }
                field("Shipping Agent Service Code"; "Shipping Agent Service Code")
                {
                    ApplicationArea = Suite;
                    Editable = false;
                    Visible = false;
                }
                field("Shipping Time"; "Shipping Time")
                {
                    ApplicationArea = Basic;
                    Editable = false;
                    Visible = false;
                }
                field("Work Type Code"; "Work Type Code")
                {
                    ApplicationArea = Manufacturing;
                    Editable = false;
                    Visible = false;
                }
                field("Whse. Outstanding Qty."; "Whse. Outstanding Qty.")
                {
                    ApplicationArea = Warehouse;
                    Editable = false;
                    Visible = false;
                }
                field("Whse. Outstanding Qty. (Base)"; "Whse. Outstanding Qty. (Base)")
                {
                    ApplicationArea = Warehouse;
                    Editable = false;
                    Visible = false;
                }
                field("ATO Whse. Outstanding Qty."; "ATO Whse. Outstanding Qty.")
                {
                    ApplicationArea = Warehouse;
                    Editable = false;
                    Visible = false;
                }
                field("ATO Whse. Outstd. Qty. (Base)"; "ATO Whse. Outstd. Qty. (Base)")
                {
                    ApplicationArea = Warehouse;
                    Editable = false;
                    Visible = false;
                }
                field("Outbound Whse. Handling Time"; "Outbound Whse. Handling Time")
                {
                    ApplicationArea = Warehouse;
                    Editable = false;
                    Visible = false;
                }
                field("Blanket Order No."; "Blanket Order No.")
                {
                    ApplicationArea = Suite;
                    Editable = false;
                    Visible = false;
                }
                field("Blanket Order Line No."; "Blanket Order Line No.")
                {
                    ApplicationArea = Suite;
                    Editable = false;
                    Visible = false;
                }
                field("FA Posting Date"; "FA Posting Date")
                {
                    ApplicationArea = FixedAssets;
                    Editable = false;
                    Visible = false;
                }
                field("Depr. until FA Posting Date"; "Depr. until FA Posting Date")
                {
                    ApplicationArea = FixedAssets;
                    Editable = false;
                    Visible = false;
                }
                field("Depreciation Book Code"; "Depreciation Book Code")
                {
                    ApplicationArea = FixedAssets;
                    Editable = false;
                    Visible = false;
                }
                field("Use Duplication List"; "Use Duplication List")
                {
                    ApplicationArea = FixedAssets;
                    Editable = false;
                    Visible = false;
                }
                field("Duplicate in Depreciation Book"; "Duplicate in Depreciation Book")
                {
                    ApplicationArea = FixedAssets;
                    Editable = false;
                    Visible = false;
                }
                field("Appl.-from Item Entry"; "Appl.-from Item Entry")
                {
                    ApplicationArea = Basic;
                    Editable = false;
                    Visible = false;
                }
                field("Appl.-to Item Entry"; "Appl.-to Item Entry")
                {
                    ApplicationArea = Basic;
                    Editable = false;
                    Visible = false;
                }

                field("Line No."; "Line No.")
                {
                    ApplicationArea = Basic;
                    Editable = false;
                    ToolTip = 'Specifies the line number.';
                    Visible = false;
                }
                field("Ctrl Modified Price"; "Ctrl Modified Price")
                {


                }
            }
        }
    }
}