page 50157 "Ligne BL Subform"
{
    Caption = 'Lignes BL';
    LinksAllowed = false;
    PageType = ListPart;
    SourceTable = "Sales Shipment Line";
    SourceTableView = WHERE(BS = FILTER(false), CustDivers = filter(false));
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
                    Caption = 'Qte Livrée';
                    ToolTip = 'Specifies the quantity of the shipped item that has been posted as shipped but that has not yet been posted as invoiced.';
                }
                field("Quantity Invoiced"; "Quantity Invoiced")
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    Caption = 'Qte Facturée';
                    ToolTip = 'Specifies how many units of the item on the line have been posted as invoiced.';
                }
                field("Related Invoice No. "; "Order No.")
                {
                    ApplicationArea = All;
                    Caption = 'Cmd Liée';
                }
                field("Bill-to Customer No."; "Bill-to Customer No.")
                {
                    ApplicationArea = All;
                    Caption = 'Client';
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        CalcFields(CustDivers);
    end;

    procedure setDate(firstDay: date; lastDate: date)
    begin
        SetRange("Posting Date", firstDay, lastDate);
        CurrPage.Update();
    end;
}

