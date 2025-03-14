page 50106 "Purch. Recept. Lines"
{
    Caption = 'Ligne Reception Achat';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = List;
    Permissions = TableData "Purch. Rcpt. Line" = rm;
    SourceTable = "Purch. Rcpt. Line";
    SourceTableView = WHERE(Correction = FILTER(false), Quantity = filter(<> 0));
    UsageCategory = Lists;
    ApplicationArea = all;
    layout
    {
        area(content)
        {
            repeater(Control1120000)
            {
                field("Document No."; "Document No.")
                {
                    ApplicationArea = all;
                    Editable = false;
                    Enabled = false;
                    HideValue = "Document No.HideValue";
                    Style = Strong;
                    StyleExpr = TRUE;
                }
                field("Buy-from Vendor No."; "Buy-from Vendor No.")
                {
                    ApplicationArea = all;
                    Caption = 'Vendor No.';
                    HideValue = "Buy-from Vendor No.HideValue";
                    Style = AttentionAccent;
                    StyleExpr = Boolavoir;
                }

                field("No."; "No.")
                {
                    Editable = false;
                    Style = AttentionAccent;
                    StyleExpr = Boolavoir;
                    ApplicationArea = All;
                }
                field(Description; Description)
                {
                    Editable = false;
                    Style = StrongAccent;
                    StyleExpr = Boolavoir;
                    ApplicationArea = All;

                }
                field(Quantity; Quantity)
                {
                    Editable = false;
                    Style = AttentionAccent;
                    StyleExpr = Boolavoir;
                    ApplicationArea = All;
                }

                field("Direct Unit Cost"; "Direct Unit Cost")
                {
                    Editable = false;
                    Style = AttentionAccent;
                    StyleExpr = Boolavoir;
                    ApplicationArea = All;
                }
                field("Currency Code"; "Currency Code")
                {
                    Editable = false;
                    ApplicationArea = all;

                }
                field("Expected Receipt Date"; "Expected Receipt Date")
                {
                    Editable = false;
                    Style = AttentionAccent;
                    StyleExpr = Boolavoir;
                    ApplicationArea = All;
                }
                field("Order Date"; "Order Date")
                {
                    ApplicationArea = All;
                }
                field("Last Purchase Unit price"; "Last Purchase Unit price")
                {
                    Editable = false;
                    ApplicationArea = all;
                }
                field("Last Unit Price Devise"; "Last Unit Price Devise")
                {
                    Caption = 'Dernier PU Devise Facturé';
                    Editable = false;
                    ApplicationArea = all;
                }

                field("Last Unit Cost"; "Last Unit Cost")
                {
                    Editable = false;
                    ApplicationArea = all;
                }
                field("Expected Unit Cost LCY "; "Expected Unit Cost LCY ")
                {
                    Editable = false;
                    ApplicationArea = All;
                }
                field("Price/Profit Calculation"; "Price/Profit Calculation")
                {
                    ApplicationArea = All;
                }
                field("Profit %"; "Profit %")
                {
                    Editable = "Price/Profit Calculation" = "Price/Profit Calculation"::"Price=Cost+Profit";
                    ApplicationArea = All;
                    trigger OnValidate()
                    begin
                        CurrPage.SAVERECORD; //DELTA 02
                    end;
                }
                field("Unit Price"; "Unit Price")
                {
                    Editable = "Price/Profit Calculation" = "Price/Profit Calculation"::"Profit=Price-Cost";

                    ApplicationArea = All;
                    trigger OnValidate()
                    begin
                        CurrPage.SAVERECORD; //DELTA 02
                    end;
                }


                field("Actual Unit Price"; "Actual Unit Price")
                {
                    ApplicationArea = all;
                    Caption = 'Prix Vente Actuel';
                }
                field("sales price choice"; "sales price choice")
                {
                    ApplicationArea = all;
                }
                field("New Unit Price"; "New Unit Price")
                {
                    ApplicationArea = all;
                    Editable = false;
                }

                field("Prix Special Vendor"; "Prix Special Vendor")
                {
                    ApplicationArea = all;
                    Editable = true;
                }

            }

            part("Equivalent"; "Item Equivalent")
            {
                UpdatePropagation = SubPart;
                ApplicationArea = All;
            }

            part("Kit"; "Item Kit")
            {
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
        }
    }

    trigger OnAfterGetRecord()
    var
        PurchInvLine: Record "Purch. Inv. Line";
    begin
        "Buy-from Vendor No.HideValue" := false;
        "Document No.HideValue" := false;
        DocumentNoOnFormat;
        BuyfromVendorNoOnFormat;

        Boolavoir := AvoirExist;
        rec.CalcFields("Actual Unit Price");

        PurchInvLine.Reset();
        PurchInvLine.SetRange("No.", "No.");
        if PurchInvLine.FindLast() then begin
            "Last Unit Price Devise" := PurchInvLine."Direct Unit Cost";
            rec.Modify();
        end;
    end;

    trigger OnAfterGetCurrRecord()
    var
        Item: Record Item;

        recIsKit, recIsComponent : Record "BOM Component";
        recitem: Record item;
        recPurchLine: Record "Purchase Line";
        iscomponent, EntredOnce : Boolean;
        comparedNo: TEXT;
    begin
        if "Reference Origine Lié" = '' then begin
            if item.get("No.") then begin
                "Reference Origine Lié" := Item."Reference Origine Lié";
                Modify();
            end;
        end;


        CurrPage."Equivalent".Page.SetNo("No.");

        //Vérifier si c'est un parent, composant ou rien
        recIsKit.Reset();
        recIsKit.SetRange("Parent Item No.", "No.");

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
                CurrPage."kit".Page.SetKit("No.")
            else
                CurrPage.Kit.Page.SetComponent("No.");

    end;



    var
        [InDataSet]
        "Document No.HideValue": Boolean;
        [InDataSet]
        "Buy-from Vendor No.HideValue": Boolean;
        Boolavoir: Boolean;
    //TODO: explanation
    local procedure IsFirstDocLine(): Boolean
    var
        TempPurchRecepLines: Record "Purch. Rcpt. Line";

    begin
        TempPurchRecepLines.RESET;
        TempPurchRecepLines.SETRANGE("Transit Folder No.", "Transit Folder No.");
        TempPurchRecepLines.SETRANGE("Document No.", "Document No.");
        TempPurchRecepLines.SETRANGE(Correction, false);
        TempPurchRecepLines.SETFILTER(Quantity, '<>%1', 0);
        TempPurchRecepLines.SETFILTER(Type, '%1|%2'
                 , TempPurchRecepLines.Type::Item, TempPurchRecepLines.Type::"Fixed Asset");

        if TempPurchRecepLines.FindFirst() then
            if TempPurchRecepLines."Line No." = "Line No." then
                exit(true);

        exit(false);
    end;

    local procedure DocumentNoOnFormat()
    begin
        if not IsFirstDocLine then
            "Document No.HideValue" := true;
    end;

    local procedure BuyfromVendorNoOnFormat()
    begin
        if not IsFirstDocLine then
            "Buy-from Vendor No.HideValue" := true;
    end;

    procedure AvoirExist(): Boolean
    var
        PurchCrMemoLine: Record "Purch. Cr. Memo Line";
    begin

        PurchCrMemoLine.SETCURRENTKEY("Appl.-to Item Entry");
        PurchCrMemoLine.SETRANGE("Appl.-to Item Entry", "Item Rcpt. Entry No.");
        PurchCrMemoLine.SETRANGE("No.", "No.");
        PurchCrMemoLine.SETRANGE(Type, Type);

        if PurchCrMemoLine.FINDFIRST then
            exit(true)
        else
            exit(false);
    end;
}