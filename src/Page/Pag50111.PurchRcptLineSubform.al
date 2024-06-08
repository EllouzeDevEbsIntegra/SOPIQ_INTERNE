page 50111 "Purch. Rcpt Line Subform"
{
    Caption = 'Lignes Réception Achat';
    LinksAllowed = false;
    PageType = ListPart;
    SourceTable = "Purch. Rcpt. Line";
    SourceTableView = where("Qty. Rcd. Not Invoiced" = filter(> 0));
    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                Editable = false;
                field("Posting Date"; "Posting Date")
                {
                    ApplicationArea = all;
                    Caption = 'Date';
                }
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
                    Caption = 'Total TTC';
                    ToolTip = 'Specifies the net amount, excluding any invoice discount amount, that must be paid for products on the line.';
                }
                field("Line Amount HT"; "Line Amount HT")
                {
                    ApplicationArea = Suite;
                    BlankZero = true;
                    Editable = false;
                    Caption = 'Total HT';
                }

                field("Line Discount Amount"; "Line Discount %")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the discount amount that is granted for the item on the line.';
                    Visible = false;
                }

                field("Quantity Invoiced"; "Quantity Invoiced")
                {
                    ApplicationArea = Suite;
                    BlankZero = true;
                    Caption = 'Qte Facturée';
                    ToolTip = 'Specifies how many units of the item on the line have been posted as invoiced.';
                }
                field("Buy-from Vendor No."; "Buy-from Vendor No.")
                {
                    ApplicationArea = all;
                    Caption = 'N° Frs';
                }
            }

        }
    }
    procedure setDate(firstDay: date; lastDate: date)
    begin
        SetRange("Posting Date", firstDay, lastDate);
        CurrPage.Update();
    end;
}