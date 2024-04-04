page 50155 "Slaes Order Subform"
{
    Caption = 'Lignes Cmd Vente';
    LinksAllowed = false;
    PageType = ListPart;
    SourceTable = "Sales Line";
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
                field("Description"; Description)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies a description of the entry of the product to be purchased. To add a non-transactional text line, fill in the Description field only.';

                }
                field("Location Code"; "Location Code")
                {
                    ApplicationArea = Location;
                    Editable = false;
                    Caption = 'Magasin';
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
                    Caption = 'Qte';
                    Editable = false;
                    ToolTip = 'Specifies the number of units of the item specified on the line.';
                }
                field("Unit of Measure Code"; "Unit of Measure Code")
                {
                    ApplicationArea = Suite;
                    Caption = 'Unité';
                    ToolTip = 'Specifies how each unit of the item or resource is measured, such as in pieces or hours. By default, the value in the Base Unit of Measure field on the item or resource card is inserted.';
                }

                field("Unit Price"; "Unit Price")
                {
                    ApplicationArea = Suite;
                    BlankZero = true;
                    Editable = false;
                    Caption = 'Prix';
                    ToolTip = 'Specifies the cost of one unit of the selected item or resource.';
                }
                field("Line Discount %"; "Line Discount %")
                {
                    ApplicationArea = Suite;
                    BlankZero = true;
                    Editable = false;
                    DecimalPlaces = 2 : 2;
                    Caption = 'Rem%';
                    ToolTip = 'Specifies the discount percentage that is granted for the item on the line.';
                }
                field("Line Amount"; "Line Amount")
                {
                    ApplicationArea = Suite;
                    BlankZero = true;
                    Caption = 'Total HT';
                    Editable = false;
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
                field("Qty. to Ship"; "Qty. to Ship")
                {
                    ApplicationArea = Suite;
                    BlankZero = true;
                    ToolTip = 'Specifies the quantity of items that remains to be received.';
                    Caption = 'Qte à Livrer';
                }
                field("Qty. Shipped Not Invoiced"; "Qty. Shipped Not Invoiced")
                {
                    ApplicationArea = Suite;
                    BlankZero = true;
                    Caption = 'Qte Liv. Non Fact.';
                    ToolTip = 'Qte Livrée Non Facturée';
                }

                field("Quantity Invoiced"; "Quantity Invoiced")
                {
                    ApplicationArea = Suite;
                    BlankZero = true;
                    ToolTip = 'Specifies how many units of the item on the line have been posted as invoiced.';
                    Caption = 'Qte Facturée';
                }
            }

        }
    }

}