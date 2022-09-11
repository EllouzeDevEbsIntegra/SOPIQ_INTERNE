pageextension 80121 "Produit équivalent Comparateur" extends "Produit équivalent Comparateur" //50030
{

    layout
    {
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
            // field("Last Curr. Price."; lastDevisePrice)
            // {
            //     Caption = 'Dernier Prix Devise Consulté';
            //     ApplicationArea = All;
            //     Editable = false;
            //     DecimalPlaces = 2 : 2;
            // }

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
        lastDevisePrice: Decimal;
        FieldStyleQty, FieldStyleQtyImport : Text[50];
        RecgItem: Record item;


    procedure SetStyleQte(PDecimal: Decimal): Text[50]
    begin
        IF PDecimal <= 0 THEN exit('Unfavorable') ELSE exit('Favorable');
    end;

    procedure SetNo(PItemNo: Code[20])
    begin

        if RecgItem.get(PItemNo) THEN begin
            SETFILTER("No.", '%1', PItemNo);

            CurrPage.Update();
        end;

    end;

    trigger OnAfterGetRecord()
    var
        lPurchasePrice: Record "purchase price";



    begin


        // CalcFields("Last. Pursh. cost DS", "Last Curr. Price.");
        CalcFields("Last Curr. Price.");
        FieldStyleQty := SetStyleQte(StockQty);
        FieldStyleQtyImport := SetStyleQte(ImportQty);

        // Initialisation des variables
        // lastDevisePrice := 0;

        // // récupérer dernier prix en devise 
        // lPurchasePrice.SetCurrentKey("Starting Date");
        // lPurchasePrice.SetRange("Vendor No.", "Vendor No.");
        // lPurchasePrice.SetRange("Item No.", "No.");
        // lPurchasePrice.SetFilter("Unit of Measure Code", '%1|%2', "Purch. Unit of Measure", '');
        // if lPurchasePrice.FindLast() then begin
        //     lastDevisePrice := lPurchasePrice."Direct Unit Cost";
        // end;

    end;

}