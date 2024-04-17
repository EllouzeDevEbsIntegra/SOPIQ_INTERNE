page 50104 "Item Equivalent"
{
    PageType = ListPart;
    SourceTable = Item;
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    Editable = true;
    Caption = 'Produit Equivalent';
    //SourceTableView = sorting("Available Inventory", "ImportQty", "Qty. on Purch. Order") order(descending) where(Produit = const(FALSE), "Fabricant Is Actif" = filter(true));
    SourceTableView = sorting("Qty Stock", "Qty Import", "Qty. on Purch. Order") order(descending) where(Produit = const(FALSE), "Fabricant Is Actif" = filter(true));

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

                field("Qty Stock"; "Qty Stock")
                {
                    Caption = 'Stock';
                    ApplicationArea = All;
                    StyleExpr = FieldStyleQty;

                }
                field("Qty Import"; "Qty Import")
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
                field(SalesQty; "Total Vendu")
                {
                    Caption = 'Total Vendu';
                    ApplicationArea = All;
                    Editable = false;
                }
                field(PurchQty; "Total Achete")
                {
                    Caption = 'Total Acheté';
                    ApplicationArea = All;
                    Editable = false;
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
                Caption = 'Ancien Historique';
                Promoted = true;
                PromotedIsBig = true;
                PromotedCategory = Process;
                RunObject = page "Item Old Transaction";
                RunPageLink = "Item N°" = field("No.");
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
            action(verifyItem)
            {
                ApplicationArea = All;
                Caption = 'Article à vérifier';
                Image = ChangeStatus;
                trigger OnAction()

                begin
                    if Dialog.Confirm('Voulez vous vérifier article N° %1', true, "No.")
                    then begin
                        rec."To verify" := true;
                        rec.Modify();
                    end;
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

    VAR
        lItemNo: TEXT;
        RecgItem: Record item;
        [InDataSet]
        FieldStyleQty, FieldStyleImportQty, FieldStyleOnPurchQty : Text[50];


    trigger OnAfterGetRecord()
    var

    begin

        CalcFields("Last Curr. Price.", "Qty. on Purch. Order", "Last Date", "Qty Stock", "Qty Import");

        FieldStyleQty := SetStyleQte("Qty Stock");
        FieldStyleImportQty := SetStyleQte("Qty Import");
        FieldStyleOnPurchQty := SetStyleQte("Qty. on Purch. Order");
    end;

    procedure SetStyleQte(PDecimal: Decimal): Text[50]
    begin
        IF PDecimal <= 0 THEN exit('Unfavorable') ELSE exit('Favorable');
    end;

    procedure SetItemNo(PItemNo: TEXT)
    begin
        RecgItem.reset();
        RecgItem.SetFilter("No.", PItemNo);
        lItemNo := '<>' + PItemNo;
        if RecgItem.FindFirst() then begin
            IF RecgItem.Produit THEN begin
                SETFILTER("Reference Origine Lié", PItemNo);
                SetFilter("No.", lItemNo.Replace('|', '&<>'));
                SetFilter("Fabricant Is Actif", 'Oui');
                CurrPage.Update();
            end else begin
                if RecgItem."Reference Origine Lié" <> '' then
                    SETFILTER("Reference Origine Lié", RecgItem."Reference Origine Lié");
                SETFILTER("No.", lItemNo.Replace('|', '&<>'));
                SetFilter("Fabricant Is Actif", 'Oui');
                CurrPage.Update();
            end;


        end;



    end;

    procedure SetNo(PItemNo: TEXT)
    begin
        RecgItem.reset();
        RecgItem.SetFilter("No.", PItemNo);
        if RecgItem.FindFirst() then begin
            IF RecgItem.Produit THEN begin
                SETFILTER("Reference Origine Lié", PItemNo);
                CurrPage.Update();
            end else begin
                if RecgItem."Reference Origine Lié" <> '' then begin
                    SETFILTER("Reference Origine Lié", RecgItem."Reference Origine Lié");
                end;

                CurrPage.Update();
            end;
        end


    end;


    procedure SetNothing()
    begin
        SetFilter("No.", '''''');
        CurrPage.Update();
    end;

    trigger OnOpenPage()
    begin
        // @@@@@@ TO VERIFY
        IF FindFirst THEN;
    end;
}
