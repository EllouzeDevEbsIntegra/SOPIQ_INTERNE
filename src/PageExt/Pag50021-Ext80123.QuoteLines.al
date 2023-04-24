pageextension 80123 "Quote Lines" extends "Quote Lines" //50021
{
    layout
    {
        modify("No.")
        {
            StyleExpr = styleExpr;
        }
        modify(DateDernierAchat)
        {
            Visible = false;
        }

        addafter(Quantity)
        {
            field("StockQty"; recItem.StockQty)
            {
                Caption = 'Stock';
                ApplicationArea = All;
                StyleExpr = FieldStyleQty;
            }
        }
        addafter("DateDernierAchat")
        {
            field("Date Dernier Achat"; recItem."Last. Pursh. Date")
            {
                Caption = 'Date Dernier Achat';
                ApplicationArea = All;
                Editable = false;
            }
        }
        // Add changes to page layout here
        addbefore("Initial Quantity")
        {
            field("Last Unit Price"; "Direct Unit Cost")
            {
                Caption = 'Prix Devise Consulté';
                ApplicationArea = All;
                Editable = false;
            }
            field("Initial Vendor Price"; "Initial Vendor Price")
            {
                Caption = 'Prix Initial Vendeur';
                ApplicationArea = All;
                Editable = false;
            }
        }
    }

    actions
    {
        modify(ItemTransaction)
        {
            Visible = false;
        }
        addafter(ItemTransaction)
        {
            action("ITEM-TRANSACTION")
            {
                Caption = 'Transactions articles';
                ShortcutKey = F9;
                // Visible = false;
                RunObject = page "Specific Item Ledger Entry";
                RunPageLink = "Item No." = field("No."), "Posting Date" = filter('01012023..');
            }
            action("Item Old Transaction")
            {
                ApplicationArea = All;
                Caption = 'Historique article 2021';
                Promoted = true;
                PromotedIsBig = true;
                PromotedCategory = Process;
                RunObject = page "Item Transaction 2021";
                RunPageLink = "Item N°" = field("No."), Year = CONST('2021');
                ShortcutKey = F8;
            }
            action(Prices)
            {
                ApplicationArea = All;
                Caption = 'Prices';
                Image = Price;
                RunObject = Page "Purchase Prices";
                RunPageLink = "Item No." = FIELD("No."), "Vendor No." = FIELD("Buy-from Vendor No.");
                RunPageView = SORTING("Item No.");
                ToolTip = 'View or set up different prices for the item. An item price is automatically granted on invoice lines when the specified criteria are met, such as vendor, quantity, or ending date.';
                ShortcutKey = F7;
            }
        }
    }

    var
        styleExpr: text[50];
        recItem: Record item;
        FieldStyleQty: Text[50];

    procedure SetStyleDate(PDate: Date): Text[50]
    var
        recdate: date;
    begin
        recdate := CalcDate('<-24M>', WorkDate());
        // Message('%1- %2', recdate, PDate);
        IF PDate <= recdate THEN exit('Unfavorable') ELSE IF (PDate <= CalcDate('<-12M>', WorkDate())) THEN exit('Attention') ELSE exit('Strong');
    end;

    trigger OnAfterGetRecord()
    begin
        recItem.Reset();
        recItem.get("No.");
        if recItem.get("No.") then begin
            recItem.CalcFields(StockQty);
            FieldStyleQty := SetStyleQte(recItem.StockQty)
        end;
        styleExpr := SetStyleDate(recItem."Last. Pursh. Date");
    end;

    procedure SetStyleQte(PDecimal: Decimal): Text[50]
    begin
        IF PDecimal <= 0 THEN exit('Unfavorable') ELSE exit('Favorable');
    end;
}