page 50105 "Item Kit"
{
    PageType = ListPart;
    SourceTable = Item;
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    Editable = true;
    Caption = 'Produit Kit';
    SourceTableView = sorting("StockQty", "ImportQty", "Qty. on Purch. Order") order(descending) where(Produit = const(FALSE));
    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Vendor No."; "Vendor No.")
                {
                    Caption = 'Frs';
                    ApplicationArea = All;
                    Editable = false;
                }

                field("No."; "No.")
                {
                    Caption = 'Référence';
                    Editable = false;
                    ApplicationArea = All;
                    Style = strong;

                }
                field("Description structurée"; "Description structurée")
                {
                    Caption = 'Description';
                    ApplicationArea = All;
                    Editable = false;
                    Style = strong;
                }
                field("StockQty"; StockQty)
                {
                    Caption = 'Stock';
                    ApplicationArea = All;
                    StyleExpr = FieldStyleQty;

                }
                field("ImportQty"; ImportQty)
                {
                    Caption = 'Import';
                    ApplicationArea = All;
                    StyleExpr = FieldStyleImportQty;
                }

                field("Qty. on Purch. Order"; "Qty. on Purch. Order")
                {
                    Caption = 'Qté Cmdé';
                    ApplicationArea = All;
                    StyleExpr = FieldStyleOnPurchQty;

                }
                field("Last Pursh. Cost DS"; rec."Last. Pursh. cost DS")
                {
                    Caption = 'Cout Calculé';
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Last Pursh. Date"; rec."Last. Pursh. Date")
                {
                    Caption = 'Dernier Achat';
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Unit Price"; "Unit Price")
                {
                    Caption = 'PUHT';
                    ApplicationArea = All;
                    Editable = false;
                }

                field("Last Curr. Price."; "Last Curr. Price.")
                {
                    Caption = 'PU Devise';
                    ApplicationArea = All;
                    DecimalPlaces = 2 : 2;
                }


                field("Last. Preferential"; rec."Last. Preferential")
                {
                    Caption = 'Pref';
                    ApplicationArea = All;
                    Editable = false;

                }
                field("Last date"; rec."Last Date")
                {
                    Caption = 'Date Prix Devise';
                    ApplicationArea = All;
                    Editable = false;
                }
            }

        }
    }

    actions
    {
        area(Processing)
        {
            action(ItemTransaction)
            {
                Caption = 'Transactions articles';
                ShortcutKey = F9;
                // Visible = false;
                RunObject = page "Specific Item Ledger Entry";
                RunPageLink = "Item No." = field("No.");
            }

            action("Item Old Transaction")  // On click, afficher la page historique des articles 2020 - 2021  
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
                RunPageLink = "Item No." = FIELD("No."), "Vendor No." = FIELD("Vendor No.");
                RunPageView = SORTING("Item No.");
                ToolTip = 'View or set up different prices for the item. An item price is automatically granted on invoice lines when the specified criteria are met, such as vendor, quantity, or ending date.';
                ShortcutKey = F7;
            }
        }
    }

    VAR
        LastDate: date;
        filterParent, filtreComponent, filtreKitofComponent : TEXT;
        EntredOnce: Boolean;
        LorderNo, lItemNo : TEXT;
        varInventory, Coefficiant, LastPrice : Decimal;
        Vendor: Record Vendor;
        PurchaseSetup: Record "Purchases & Payables Setup";
        RecGOrder: Record "Sales Header";
        recItem, RecgItem, Item, Item2 : Record item;
        recKit, recComponent : Record "BOM Component";
        [InDataSet]
        FieldStyleQty, FieldStyleImportQty, FieldStyleOnPurchQty : Text[50];


    trigger OnAfterGetRecord()
    var

    begin

        CalcFields("Last Curr. Price.", "Qty. on Purch. Order", "Last Date", StockQty, ImportQty);
        FieldStyleQty := SetStyleQte(StockQty);
        FieldStyleImportQty := SetStyleQte(ImportQty);
        FieldStyleOnPurchQty := SetStyleQte("Qty. on Purch. Order");
    end;

    procedure SetStyleQte(PDecimal: Decimal): Text[50]
    begin
        IF PDecimal <= 0 THEN exit('Unfavorable') ELSE exit('Favorable');
    end;

    procedure SetOrderNo(POrderNo: TEXT)
    begin
        LorderNo := POrderNo;
    end;

    procedure SetKit(PItemNo: TEXT)
    Var
        Master: Code[50];
    begin
        // Message('kits!');
        recKit.Reset();
        filterParent := '';
        EntredOnce := false;

        recKit.Reset();
        recKit.SetRange("Parent Item No.", PItemNo);
        if recKit.FindSet() then begin
            repeat
                recItem.SetRange("No.", recKit."No.");
                if recitem.FindFirst() then Master := recitem."Reference Origine Lié";
                if EntredOnce then
                    FilterParent := FilterParent + '|';
                FilterParent := FilterParent + Master;
                EntredOnce := true;
            until recKit.next = 0;

            if EntredOnce then begin
                // Message('Parent %1', filterParent);
                SetFilter("No.", '');
                SETFILTER("Reference Origine Lié", filterParent);
                SetFilter("Fabricant Is Actif", 'Oui');
                CurrPage.Update();
            end
        end;

    end;


    procedure SetComponent(PItemNo: TEXT)
    Var
        recItem, recItemMaster : Record Item;
    begin
        recItem.Reset();
        recItem.SetRange("No.", PItemNo);
        if recitem.FindFirst() then begin
            filtreComponent := '';
            EntredOnce := false;
            recItemMaster.Reset();
            recItemMaster.SetRange("Reference Origine Lié", recItem."Reference Origine Lié");
            if recItemMaster.FindSet() then begin
                repeat
                    if EntredOnce then
                        filtreComponent := filtreComponent + '|';
                    filtreComponent := filtreComponent + recItemMaster."No.";
                    EntredOnce := true;
                until recItemMaster.next = 0;
            end;
            filtreKitofComponent := '';
            EntredOnce := false;
            // Message('filtre Component : %1', filtreComponent);
            recComponent.Reset();
            recComponent.SetFilter("No.", filtreComponent);
            if recComponent.FindSet() then begin
                repeat
                    if EntredOnce then
                        filtreKitofComponent := filtreKitofComponent + '|';
                    filtreKitofComponent := filtreKitofComponent + recComponent."Parent Item No.";
                    EntredOnce := true;
                until recComponent.next = 0;
            end;
            if EntredOnce then begin
                // Message('filtre KIT OF Component : %1', filtreKitofComponent);
                SETFILTER("Reference Origine Lié", '');
                SETFILTER("No.", filtreKitofComponent);
                SetFilter("Fabricant Is Actif", 'Oui');
                CurrPage.Update();
            end;

        end;
    end;



    procedure SetNothing()
    begin
        SetFilter("No.", '''''');
        CurrPage.Update();
    end;










    //////////////////////////////////////////////////////// ?! A VERIFIER

    procedure GetOrderNo(ReclOrder: Record "Sales Header")
    begin
        RecGOrder := ReclOrder;
    end;

    local procedure FieldsVisibility(lvarLocation: Code[20]): Boolean
    begin
        if lvarLocation <> '' then exit(true) else exit(false);
    end;

    procedure insertItem(litem: Record Item; NewxlocationVar: code[10]; QtytoInsert: Decimal)
    var
        salesline: Record "Sales Line";
        Lineno: Integer;
    begin
        salesline.RESET;
        salesline.setrange("Document Type", salesline."Document Type"::Order);
        salesline.setrange("Document No.", RecGOrder."No.");
        IF salesline.FindLast() THEN
            Lineno := salesline."Line No." + 10000 else
            Lineno := 10000;
        salesline.init;
        salesline."Document Type" := salesline."Document Type"::Order;
        salesline."Document No." := RecGOrder."No.";
        salesline."Line No." := Lineno;
        salesline."Document Profile" := salesline."Document Profile"::"Spare Parts Trade";
        salesline.Type := salesline.Type::Item;
        salesline.validate("No.", litem."No.");
        salesline.validate("Location Code", NewxlocationVar);
        salesline.validate(quantity, QtytoInsert);
        salesline.insert;
    end;

}
