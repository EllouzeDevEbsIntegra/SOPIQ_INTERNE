pageextension 80123 "Quote Lines" extends "Quote Lines" //50021
{
    layout
    {
        addfirst(Content)
        {
            grid("1")
            {
                field("Item No"; rec."No.")
                {
                    ApplicationArea = All;
                    Caption = 'Article';
                }

                field("Stock Ste 1"; recItemCompany1.Inventory)
                {
                    Caption = 'Qte Ste 1';
                    Editable = false;
                    trigger OnDrillDown()
                    var
                        ILECompany1: Record "Specific Item Ledger Entry";
                    begin
                        ILECompany1.Reset();
                        ILECompany1.SetRange("Item No.", rec."No.");
                        ILECompany1.ChangeCompany(recCompany."Inter Society 1");
                        Commit();
                        PAGE.RUNMODAL(PAGE::"Specific Item Ledger Entry", ILECompany1);
                    end;


                }
                field("Last Purchase Date Ste 1"; recItemCompany1."Last Purchase Date")
                {
                    Caption = 'Dern. Date. Achat Ste 1';
                    Editable = false;
                }
                field("Stock Ste 2"; recItemCompany2.Inventory)
                {
                    Caption = 'Qte Ste 2';
                    Editable = false;
                    trigger OnDrillDown()
                    var
                        ILECompany2: Record "Specific Item Ledger Entry";

                    begin
                        ILECompany2.Reset();
                        ILECompany2.SetRange("Item No.", rec."No.");
                        ILECompany2.ChangeCompany(recCompany."Inter Society 2");
                        Commit();
                        PAGE.RUNMODAL(PAGE::"Specific Item Ledger Entry", ILECompany2);
                    end;

                }
                field("Last Purchase Date Ste 2"; recItemCompany2."Last Purchase Date")
                {
                    Caption = 'Dern. Date. Achat Ste 2';
                    Editable = false;
                }
            }
        }


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
            field("Available Inventory"; recItem."Available Inventory")
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

        addafter(Quantity)
        {
            field("Quote Line Reason"; "Quote Line Reason")
            {
                Caption = 'Raison Qte Cmdé';
                ApplicationArea = All;
                Editable = true;
            }
            field("Quote Line Comment"; "Quote Line Comment")
            {
                Caption = 'Commentaire Ligne Devis';
                ApplicationArea = All;
                Editable = true;
            }


            field("asking Price"; "asking price")
            {
                Caption = 'Prix Demandé';
                ApplicationArea = All;
                Editable = true;
                trigger OnValidate()
                begin
                    "asking qty" := "Vendor Quantity";
                    Modify();
                end;
            }

            field("asking Qty"; "asking qty")
            {
                Caption = 'Qté Demandée';
                ApplicationArea = All;
                Editable = true;
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
                RunObject = page "Specific Item Ledger Entry";
                RunPageLink = "Item No." = field("No.");
            }
            action("Item Old Transaction")
            {
                ApplicationArea = All;
                ShortcutKey = F8;
                Caption = 'Ancien Historique';
                RunObject = page "Item Old Transaction";
                RunPageLink = "Item N°" = field("No.");
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
            action(verifyItem)
            {
                ApplicationArea = All;
                Caption = 'Article à vérifier';
                Image = ChangeStatus;
                ShortcutKey = 'Ctrl+F7';
                trigger OnAction()
                var
                    recitem: Record Item;
                begin
                    if Dialog.Confirm('Voulez vous vérifier article N° %1', true, "No.")
                    then begin
                        recitem.SetRange("No.", "No.");
                        if recitem.FindFirst() then begin
                            recitem."To verify" := true;
                            recitem.Modify();
                        end;
                    end

                end;
            }

            action("Item Info")
            {
                Caption = 'Information article';
                ShortcutKey = 'Ctrl+F8';
                Image = Picture;
                // Visible = false;
                RunObject = page "Item Info";
                RunPageLink = "No." = field("No.");
            }
        }
    }

    var
        styleExpr: text[50];
        recItem: Record item;
        FieldStyleQty: Text[50];
        recItemCompany1, recItemCompany2 : Record Item;
        recCompany: Record "Company Information";

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
            recItem.CalcFields("Available Inventory");
            FieldStyleQty := SetStyleQte(recItem."Available Inventory")
        end;
        styleExpr := SetStyleDate(recItem."Last. Pursh. Date");
    end;


    procedure SetStyleQte(PDecimal: Decimal): Text[50]
    begin
        IF PDecimal <= 0 THEN exit('Unfavorable') ELSE exit('Favorable');
    end;

    trigger OnAfterGetCurrRecord()
    var
    begin
        recCompany.get();

        recItemCompany1.Reset();
        recItemCompany1.ChangeCompany(recCompany."Inter Society 1");
        IF recItemCompany1.GET(rec."No.") then begin
            recItemCompany1.CalcFields(Inventory);

        end;

        recItemCompany2.Reset();
        recItemCompany2.ChangeCompany(recCompany."Inter Society 2");
        IF recItemCompany2.GET(rec."No.") then begin
            recItemCompany2.CalcFields(Inventory);
        end;
    end;

}