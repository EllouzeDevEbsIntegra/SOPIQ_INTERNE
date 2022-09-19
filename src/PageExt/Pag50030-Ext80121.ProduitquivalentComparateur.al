pageextension 80121 "Produit équivalent Comparateur" extends "Produit équivalent Comparateur" //50030
{


    layout
    {
        modify("Last date")
        {
            Caption = 'Date du dernier prix en devise';
        }
        modify("Last Direct Cost")
        {
            Visible = true;
        }

        modify("Inventory without Import")
        {
            Visible = false;
        }

        modify("Import Inventory")
        {
            Visible = false;
        }
        // Add changes to page layout here
        addbefore("Unit Price")
        {
            field("Last Pursh. Date"; rec."Last. Pursh. Date")
            {
                Caption = 'Date Dernier Achat';
                ApplicationArea = All;
                Editable = false;
            }
        }

        addafter("Unit Price")
        {

            field("Last Curr. Price."; "Last Curr. Price.")
            {
                Caption = 'Dernier Prix Devise Consulté';
                ApplicationArea = All;
                DecimalPlaces = 2 : 2;
            }


            field("Last. Preferential"; rec."Last. Preferential")
            {
                Caption = 'Dernier Preferential';
                ApplicationArea = All;
                Editable = false;

            }
        }

        addafter("Import Inventory")
        {
            field("StockQty"; StockQty)
            {
                Caption = 'Stock actuel';
                ApplicationArea = All;
                StyleExpr = FieldStyleQty;

            }
            field("ImportQty"; ImportQty)
            {
                Caption = 'Stock import';
                ApplicationArea = All;
                StyleExpr = FieldStyleQtyImport;
            }

            field("Last Pursh. Cost DS"; rec."Last. Pursh. cost DS")
            {
                Caption = 'Dernier Cout Achat Calculé';
                ApplicationArea = All;
                Editable = false;
            }
        }
    }

    actions
    {

        addafter(ItemTransaction)
        {
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
        }
    }

    var

        FieldStyleQty, FieldStyleQtyImport : Text[50];
        recKit, recComponent : Record "BOM Component";
        filterParent, filtreComponent : TEXT;
        EntredOnce: Boolean;
        RecgItem, recItem : Record item;


    procedure SetStyleQte(PDecimal: Decimal): Text[50]
    begin
        IF PDecimal <= 0 THEN exit('Unfavorable') ELSE exit('Favorable');
    end;

    procedure SetNo(PItemNo: TEXT)
    begin
        if RecgItem.get(PItemNo) THEN begin
            SETFILTER("No.", '%1', PItemNo);
            CurrPage.Update();
        end;
    end;

    procedure SetKit(PItemNo: TEXT)
    Var
        Master: Code[50];
    begin
        Message('kits!');
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
                Message('%1', filterParent);
                SetFilter("No.", '*');
                SetFilter(Produit, 'false');
                SETFILTER("Reference Origine Lié", filterParent);
                CurrPage.Update();
            end
        end;

    end;


    procedure SetComponent(PItemNo: TEXT)
    begin
        Message('compenents!');
        recComponent.Reset();
        filtreComponent := '';
        EntredOnce := false;
        recComponent.Reset();
        recComponent.SetRange("No.", PItemNo);
        if recComponent.FindSet() then begin
            repeat
                if EntredOnce then
                    filtreComponent := filtreComponent + '|';
                filtreComponent := filtreComponent + "No.";
                EntredOnce := true;
            until recComponent.next = 0;

            if EntredOnce then begin
                Message('%1', filtreComponent);
                SetFilter(Produit, 'false');
                SETFILTER("No.", filtreComponent);
                CurrPage.Update();
            end
        end;

    end;



    procedure SetNothing()
    begin
        SetFilter("No.", '''''');
        CurrPage.Update();

    end;


    trigger OnAfterGetRecord()
    var
        lPurchasePrice: Record "purchase price";



    begin

        CalcFields("Last Curr. Price.");
        FieldStyleQty := SetStyleQte(StockQty);
        FieldStyleQtyImport := SetStyleQte(ImportQty);

    end;

}