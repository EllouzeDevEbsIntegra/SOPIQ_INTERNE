page 25006984 "Sales Item Search"
{
    //PageType = NavigatePage;
    PageType = List;
    SourceTable = Item;
    SourceTableView = sorting("No.") where("No." = Filter('<> '''''));
    UsageCategory = Lists;
    ApplicationArea = all;
    ModifyAllowed = false;
    DeleteAllowed = false;
    InsertAllowed = false;
    Caption = 'Vente : Consultation articles';
    Editable = true;
    layout
    {

        area(Content)
        {
            repeater("Search Item")
            {
                Caption = 'Recherche Article';

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
                field("Available Inventory"; "Available Inventory")
                {
                    Caption = 'Stock';
                    ApplicationArea = All;
                    StyleExpr = FieldStyleQty;

                }

                field("Qty. on Purch. Order"; "Qty. on Purch. Order")
                {
                    Caption = 'Qté Cmdé';
                    ApplicationArea = All;
                    StyleExpr = FieldStyleOnPurchQty;

                }
                field("Total Vendu"; "Total Vendu")
                {
                    Caption = 'Total Vendu';
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Total Achete"; "Total Achete")
                {
                    Caption = 'Total Acheté';
                    ApplicationArea = All;
                    Editable = false;
                }


                field("Unit Price"; "Unit Price")
                {
                    Caption = 'PUHT';
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
        }

    }

    var
        [InDataSet]
        FieldStyleQty, FieldStyleImportQty, FieldStyleOnPurchQty : Text[50];

    trigger OnAfterGetRecord()
    var

    begin

        CalcFields("Last Curr. Price.", "Qty. on Purch. Order", "Last Date", "Available Inventory", ImportQty, "First Reception Date");
        FieldStyleQty := SetStyleQte("Available Inventory");
        FieldStyleImportQty := SetStyleQte(ImportQty);
        FieldStyleOnPurchQty := SetStyleQte("Qty. on Purch. Order");

    end;

    trigger OnAfterGetCurrRecord()
    VAR

        recIsKit, recIsComponent : Record "BOM Component";
        recitem: Record item;
        iscomponent: Boolean;

    begin
        CurrPage."Produitéquivalent".Page.SetItemNo(rec."No.");
        CurrPage."Produitéquivalent".Page.SetVisibleColumn();
        CurrPage.Kit.Page.SetVisibleColumn();
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

    procedure SetStyleQte(PDecimal: Decimal): Text[50]
    begin
        IF PDecimal <= 0 THEN exit('Unfavorable') ELSE exit('Favorable');
    end;

}