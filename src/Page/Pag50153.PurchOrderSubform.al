page 50153 "Purch. Order Subform"
{
    Caption = 'Lignes Cmd Achat';
    LinksAllowed = false;
    PageType = ListPart;
    SourceTable = "Purchase Line";
    SourceTableView = WHERE("Document Type" = FILTER(Order));

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
                    ApplicationArea = Suite;
                    Editable = false;
                    ToolTip = 'Specifies the document number.';
                }
                field("No."; "No.")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the number of a general ledger account, item, additional cost, or fixed asset, depending on what you selected in the Type field.';
                }
                field("Description"; "Description")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies a description of the entry of the product to be purchased. To add a non-transactional text line, fill in the Description field only.';

                }
                field("Location Code"; "Location Code")
                {
                    Caption = 'Magasin';
                    ApplicationArea = Location;
                    Editable = false;
                    ToolTip = 'Specifies a code for the location where you want the items to be placed when they are received.';
                }
                field("Bin Code"; "Bin Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the bin where the items are picked or put away.';
                    Visible = true;
                    Caption = 'Casier';
                }
                field(Quantity; Quantity)
                {
                    ApplicationArea = Suite;
                    BlankZero = true;
                    Editable = false;
                    Caption = 'Qte';
                    ToolTip = 'Specifies the number of units of the item specified on the line.';
                }
                field("Unit of Measure Code"; "Unit of Measure Code")
                {
                    Caption = 'Unité';
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies how each unit of the item or resource is measured, such as in pieces or hours. By default, the value in the Base Unit of Measure field on the item or resource card is inserted.';
                }
                field("Unit of Measure"; "Unit of Measure")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the unit of measure.';
                    Visible = false;
                }
                field("Direct Unit Cost"; "Direct Unit Cost")
                {
                    ApplicationArea = Suite;
                    BlankZero = true;
                    Editable = false;
                    Caption = 'Prix';
                    ToolTip = 'Specifies the cost of one unit of the selected item or resource.';
                }
                field("Indirect Cost %"; "Indirect Cost %")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the percentage of the item''s last purchase cost that includes indirect costs, such as freight that is associated with the purchase of the item.';
                    Visible = false;
                }
                field("Unit Cost (LCY)"; "Unit Cost (LCY)")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the unit cost of the item on the line.';
                    Visible = false;
                }
                field("Unit Price (LCY)"; "Unit Price (LCY)")
                {
                    ApplicationArea = Suite;
                    BlankZero = true;
                    ToolTip = 'Specifies the price, in LCY, for one unit of the item.';
                    Visible = false;
                }
                field("Line Discount %"; "Line Discount %")
                {
                    ApplicationArea = Suite;
                    BlankZero = true;
                    Editable = false;
                    Caption = 'Rem%';
                    DecimalPlaces = 2 : 2;
                    ToolTip = 'Specifies the discount percentage that is granted for the item on the line.';
                }
                field("Line Amount"; "Line Amount")
                {
                    ApplicationArea = Suite;
                    BlankZero = true;
                    Editable = false;
                    Caption = 'Total HT';
                    ToolTip = 'Specifies the net amount, excluding any invoice discount amount, that must be paid for products on the line.';
                }
                field("Amount Including VAT"; "Amount Including VAT")
                {
                    ApplicationArea = Suite;
                    BlankZero = true;
                    Editable = false;
                    Style = Attention;
                    Caption = 'Total TTC';
                }
                field("Line Discount Amount"; "Line Discount Amount")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the discount amount that is granted for the item on the line.';
                    Visible = false;
                }
                field("Qty. to Receive"; "Qty. to Receive")
                {
                    ApplicationArea = Suite;
                    BlankZero = true;
                    ToolTip = 'Specifies the quantity of items that remains to be received.';
                    Caption = 'Qte à Reçevoir';
                }
                field("Quantity Received"; "Quantity Received")
                {
                    ApplicationArea = Suite;
                    BlankZero = true;
                    Caption = 'Qte Reçue';
                    ToolTip = 'Specifies how many units of the item on the line have been posted as received.';
                }

                field("Quantity Invoiced"; "Quantity Invoiced")
                {
                    ApplicationArea = Suite;
                    BlankZero = true;
                    Caption = 'Qte Facturée';
                    ToolTip = 'Specifies how many units of the item on the line have been posted as invoiced.';
                }
            }

        }
    }

}