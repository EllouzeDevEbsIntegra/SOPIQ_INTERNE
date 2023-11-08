page 50125 "Special Purchase Line"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "Purchase Line";
    SourceTableView = where("Special Order" = filter(true));
    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Document No"; "Document No.")
                {
                    ApplicationArea = Basic;
                    Editable = false;
                    trigger OnDrillDown()
                    var
                        PurchPage: Page "Purchase Order";
                        PurchTable: Record "Purchase Header";
                    begin
                        PurchTable.Reset();
                        PurchTable.SetRange("No.", rec."Document No.");
                        PurchPage.SetTableView(PurchTable);
                        PurchPage.Run();
                    end;

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

                field("Buy-from Vendor No."; "Buy-from Vendor No.")
                {
                    ApplicationArea = Basic;
                    Editable = false;
                }

                field("Location Code"; "Location Code")
                {
                    ApplicationArea = Location;
                    Editable = false;
                    Visible = false;
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
                field("Direct Unit Cost"; "Direct Unit Cost")
                {
                    ApplicationArea = Basic;
                    BlankZero = true;
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
                field("Qty. to Receive"; "Qty. to Receive")
                {
                    ApplicationArea = Basic;
                    BlankZero = true;
                    QuickEntry = false;
                    Editable = false;
                }
                field("Qty. Received"; "Qty. Received (Base)")
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

                field("Planned Receipt Date"; "Planned Receipt Date")
                {
                    ApplicationArea = Basic;
                    QuickEntry = false;
                    Editable = false;

                }




                field("Special Order Sales No."; "Special Order Sales No.")
                {
                    ApplicationArea = Basic;
                    Editable = false;
                    Visible = true;
                    trigger OnDrillDown()
                    var
                        SalesPage: Page "Sales Order";
                        SalesTable: Record "Sales Header";
                    begin
                        SalesTable.Reset();
                        SalesTable.SetRange("No.", rec."Special Order Sales No.");
                        SalesPage.SetTableView(SalesTable);
                        SalesPage.Run();
                    end;
                }
                field("Special Order Sales Line No."; "Special Order Sales Line No.")
                {
                    ApplicationArea = Basic;
                    Editable = false;
                    Visible = true;
                }

                field("Special Order Service No."; "Special Order Service No.")
                {
                    ApplicationArea = Basic;
                    Editable = false;
                    Visible = true;
                }
                field("Special Order Service Line No."; "Special Order Service Line No.")
                {
                    ApplicationArea = Basic;
                    Editable = false;
                    Visible = true;
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

            }
        }
    }

}