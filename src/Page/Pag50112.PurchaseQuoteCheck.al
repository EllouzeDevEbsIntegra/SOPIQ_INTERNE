page 50112 "Purchase Quote Check"
{
    //PageType = NavigatePage;
    PageType = List;
    SourceTable = "Purchase Line";
    SourceTableView = sorting("No.");
    UsageCategory = Lists;
    ApplicationArea = all;
    ModifyAllowed = true;
    DeleteAllowed = false;
    InsertAllowed = false;
    Caption = 'Achat : Vérification demande de prix';
    Editable = true;
    layout
    {

        area(Content)
        {
            repeater("Quotes Lines")
            {
                Caption = 'Lignes Devis';
                field("Vendor No."; "Buy-from Vendor No.")
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
                    StyleExpr = FieldStyleDernierPUHT;

                }
                field("Description structurée"; "Description structurée")
                {
                    Caption = 'Description';
                    ApplicationArea = All;
                    Editable = false;
                    Style = strong;
                }
                field("Confirmed Quantity"; "Qty First Confirmation")
                {
                    Caption = 'Qte à Confirmer';
                    ApplicationArea = all;
                    Editable = false;
                }
                field("Quantity"; Quantity)
                {
                    Caption = 'Qte Final';
                    ApplicationArea = All;
                    Editable = true;
                }

                field("Direct Unit Price"; "Direct Unit Cost")
                {
                    Caption = 'PU Devise';
                    ApplicationArea = All;
                    Editable = false;
                }

                field("Prix de revient (calcule)"; "Prix de revient (calcule)")
                {
                    Caption = 'Prix Revient (Calculé)';
                    ApplicationArea = All;
                    Editable = false;
                }

                field(PrixDeVenteCalcule; CalcAncienPrixDeVente)
                {
                    Caption = 'Prix de vente (Calculé)';
                    Editable = false;
                }
                field("Available Inventory"; ItemStk."Available Inventory")
                {
                    Caption = 'Stock';
                    ApplicationArea = All;
                    StyleExpr = FieldStyleQty;
                    Editable = false;

                }
                field("ImportQty"; ItemStk.ImportQty)
                {
                    Caption = 'Import';
                    ApplicationArea = All;
                    StyleExpr = FieldStyleImportQty;
                    Editable = false;

                }

                field("Qty. on Purch. Order"; ItemStk."Qty. on Purch. Order")
                {
                    Caption = 'Qté Cmdé';
                    ApplicationArea = All;
                    StyleExpr = FieldStyleOnPurchQty;
                    Editable = false;
                    trigger OnDrillDown()
                    var
                        PurchLine: Record "Purchase Line";
                    begin
                        PurchLine.Reset();
                        PurchLine.SetRange("Document Type", PurchLine."Document Type"::Order);
                        PurchLine.SetRange("No.", "No.");
                        Page.Run(518, PurchLine);
                    end;
                }
                field("Vendor Qty"; "Vendor Quantity")
                {
                    Caption = 'Vendor Qty';
                    ApplicationArea = All;
                    Editable = false;
                }


                field("Asking Qty"; "asking qty")
                {
                    Caption = 'Asking Qty';
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Asking Price"; "asking price")
                {
                    Caption = 'Asking Price';
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Negociated Qty"; "negotiated qty")
                {
                    Caption = 'Negociated Qty';
                    ApplicationArea = All;
                    Editable = false;
                }

                field("Negociated Price"; "negotiated price")
                {
                    Caption = 'Negociated Price';
                    ApplicationArea = All;
                    Editable = false;
                }

                field("Initial Vendor Price"; "Initial Vendor Price")
                {
                    Caption = 'Initial Vendor Price';
                    ApplicationArea = All;
                    Editable = false;
                }

                field("Preferentiel"; Preferential)
                {
                    Caption = 'Pref.';
                    ApplicationArea = All;
                    Editable = false;
                }

                field("Last Pursh. Cost DS"; ItemStk."Last. Pursh. cost DS")
                {
                    Caption = 'Dernier Cout DS';
                    ApplicationArea = All;
                    Editable = false;
                }

                field("Last Pursh. Date"; ItemStk."Last. Pursh. Date")
                {
                    Caption = 'Dernier Achat';
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Last Unit Price"; rec."Unit Price (LCY)")
                {
                    Caption = 'Dernier PUHT';
                    ApplicationArea = All;
                    Editable = false;
                }

                field("Last Curr. Price."; ItemStk."Pre Last Curr. Price.")
                {
                    Caption = 'Dernier PU Devise';
                    ApplicationArea = All;
                    DecimalPlaces = 2 : 2;
                    Editable = false;
                }


                field("Last. Preferential"; ItemStk."Last. Preferential")
                {
                    Caption = 'Pref';
                    ApplicationArea = All;
                    Editable = false;

                }
                field("Last date"; ItemStk."Last starting Date")
                {
                    Caption = 'Date Prix Devise';
                    ApplicationArea = All;
                    Editable = false;
                }

                field("First Reception Date"; ItemStk."First Reception Date")
                {
                    Caption = 'Date Recep proche';
                    ApplicationArea = All;
                    Editable = false;
                }

                field("Quote Line Reason"; "Quote Line Reason")
                {
                    Caption = 'Raison Qte Cmdé';
                    ApplicationArea = All;
                    Editable = false;
                }

            }
            // part("cmd"; "Purchase Line Reliquat")
            // {
            //     Caption = 'Vérification article en commande';
            //     UpdatePropagation = SubPart;
            //     ApplicationArea = All;
            //     SubPageLink = "No." = field("No.");
            // }
            part("Produitéquivalent"; "Item Equivalent")
            {
                Caption = 'Equivalent';
                UpdatePropagation = SubPart;
                ApplicationArea = All;
            }
            part("Kit"; "Item Kit")
            {
                Caption = 'Kit';
                UpdatePropagation = SubPart;
                ApplicationArea = All;
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
                RunObject = page "Specific Item Ledger Entry";
                RunPageLink = "Item No." = field("No.");
            }

            action("Validate Quote")
            {
                caption = 'Valider Demande de prix';
                trigger OnAction()
                begin
                    purshaseHeader.Reset();
                    purshaseHeader.SetFilter("No.", "Document No.");
                    if purshaseHeader.FindFirst() then begin
                        purshaseHeader."Etat Demande" := Enum::"Etat Demande Prix"::Valide;
                        purshaseHeader.Modify();
                    end;
                end;

            }
        }

    }

    var
        [InDataSet]
        FieldStyleQty, FieldStyleImportQty, FieldStyleOnPurchQty, FieldStyleDernierPUHT : Text[50];
        ItemStk: Record Item;
        purshaseHeader: Record "Purchase Header";
        Item: Record Item;

    trigger OnAfterGetRecord()
    var

    begin

        if ItemStk.get("No.") Then
            ItemStk.CalcFields("Last starting Date", "Last Curr. Price.", "Qty. on Purch. Order", "Last Date", "Last Ending Date", "Available Inventory", ImportQty, "First Reception Date", "Pre Last Curr. Price.");
        FieldStyleQty := SetStyleQte(ItemStk."Available Inventory");
        FieldStyleImportQty := SetStyleQte(ItemStk.ImportQty);
        FieldStyleOnPurchQty := SetStyleQte(ItemStk."Qty. on Purch. Order");
        FieldStyleDernierPUHT := SetStylePrix(ItemStk."Unit Price");

    end;

    trigger OnAfterGetCurrRecord()
    VAR
        recIsKit, recIsComponent : Record "BOM Component";
        recitem: Record item;
        iscomponent: Boolean;

    begin
        if (rec.IsEmpty = true) then begin
            Message('Aucun enregistrement trouvé avec ces filtres !');
            CurrPage."Produitéquivalent".Page.SetNothing();
            CurrPage.Kit.Page.SetNothing();
        end
        else begin
            CurrPage."Produitéquivalent".Page.SetItemNo(rec."No.");

            // Vérifier si c'est un parent, composant ou rien
            recIsKit.Reset();
            recIsKit.SetRange("Parent Item No.", rec."No.");

            iscomponent := false;
            recitem.Reset();
            recitem.SetRange("Reference Origine Lié", "Reference Origine Lié");
            if recitem.FindSet() then begin
                repeat
                    recIsComponent.Reset();
                    recIsComponent.SetRange("No.", recitem."No.");
                    if recIsComponent.FindFirst() then iscomponent := true;
                until recitem.next = 0;
            end;

            if (recIsKit.IsEmpty = true AND iscomponent = false) then begin
                CurrPage.Kit.Page.SetNothing();
            end
            else
                if recIsKit.FindFirst() then
                    CurrPage."kit".Page.SetKit(rec."No.")
                else
                    CurrPage.Kit.Page.SetComponent(rec."No.");

        end;
    end;

    procedure SetStyleQte(PDecimal: Decimal): Text[50]
    begin
        IF PDecimal <= 0 THEN exit('Unfavorable') ELSE exit('Favorable');
    end;


    procedure SetStylePrix(PDecimal: Decimal): Text[50]
    begin
        IF PDecimal = 0 THEN exit('Unfavorable');
    end;

    procedure CalcAncienPrixDeVente(): Decimal
    var
        Currency: Record Currency;
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        ExchangeRateDate: Date;
        ExchangeRateAmt: Decimal;
    begin
        if Item.get("No.") then
            if Currency.get("Currency Code") then begin
                CurrencyExchangeRate.GetLastestExchangeRate(Currency.Code, ExchangeRateDate, ExchangeRateAmt);
                exit(rec."Prix de revient (calcule)" / (100 - Item."Profit %") * 100);
            end;
    end;


    procedure GetLastDirectUnitCostCalculated(): Decimal
    var
        Vendor: Record Vendor;
    begin
        if Vendor.get("Buy-from Vendor No.") then
            if item.Get("No.") then
                exit(Item."Last Direct Cost" * Vendor.Coefficient); //demande de prix last direct 
    end;

}