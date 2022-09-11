page 50101 "Purchase Item Search"
{
    PageType = NavigatePage;
    SourceTable = Item;
    SourceTableView = sorting("No.");
    UsageCategory = Lists;
    ApplicationArea = all;
    Caption = 'Achat : Consultation articles';
    Editable = true;
    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';
                field(Article; ItemCode)
                {
                    Style = Strong;
                    StyleExpr = TRUE;
                    // TableRelation = Item;
                    Importance = Promoted;

                    trigger OnValidate()
                    begin
                        SETFILTER("No.", ItemCode);
                        CurrPage."Produitéquivalent".Page.SetItemNo(ItemCode);
                        CurrPage."Liste Recherche".Page.SetNo(ItemCode);
                        CurrPage."kit".Page.Update();
                        CurrPage."kit".Page.SetItemNo(ItemCode);
                        CurrPage.UPDATE;
                    end;
                }

            }
            // group("Liste de recherche")
            // {
            //     repeater(Control1)
            //     {
            //         field("Vendor No."; "Vendor No.")
            //         {
            //             Editable = false;
            //             caption = 'N° Frs';
            //             //StyleExpr = FieldStyle;
            //         }

            //         field("No."; "No.")
            //         {
            //             Editable = false;
            //             ApplicationArea = All;

            //         }
            //         field("Description structurée"; "Description structurée")
            //         {
            //             ApplicationArea = All;
            //         }

            //         field("Inventory without Import"; StockQty)
            //         {
            //             Caption = 'Stock actuel';

            //             Editable = false;
            //             StyleExpr = FieldStyleInv2;
            //             ToolTip = 'Specifies the value of the Stock actuel field.';
            //             ApplicationArea = All;

            //         }
            //         field("Import Inventory"; ImportQty)
            //         {
            //             Editable = false;
            //             Caption = 'Stock import';
            //             StyleExpr = FieldStyleInv;
            //             ToolTip = 'Specifies the value of the Stock Import field.';
            //             ApplicationArea = All;

            //         }
            //         field("Qty. on Purch. Order"; "Qty. on Purch. Order")
            //         {
            //             ApplicationArea = All;
            //             StyleExpr = FieldStyleQty;

            //         }
            //         field("Last Direct Cost"; LastPrice)
            //         {
            //             Caption = 'Ancien prix de revient';
            //             ApplicationArea = All;
            //             Editable = false;
            //         }
            //         field("Unit Price"; "Unit Price")
            //         {
            //             ApplicationArea = All;
            //             Editable = false;
            //         }

            //         field("Last date"; LastDate)
            //         {
            //             Caption = 'Date du dernier prix en devise';
            //             ApplicationArea = All;
            //             Editable = false;
            //         }

            //     }

            // }
            part("Liste Recherche"; "Produit équivalent Comparateur")
            {
                Caption = 'Liste Recherche';
                UpdatePropagation = Both;
                ApplicationArea = All;

            }
            part("Produitéquivalent"; "Produit équivalent Comparateur")
            {
                Caption = 'Produit équivalent';
                UpdatePropagation = Both;
                ApplicationArea = All;


            }
            part("Kit"; "Kit")
            {
                Caption = 'Kit';
                UpdatePropagation = Both;
                ApplicationArea = All;
            }



        }

    }
    var

        ItemCode: Code[20];
    // FieldStyle: Text[50];
    // ItemStk: Record Item;
    // FieldStyleQty, FieldStyleOnOrdQty : Text[50];
    // FieldStyleInv, FieldStyleInv2 : Text[50];
    // PurchaseSetup: Record "Purchases & Payables Setup";
    // Item2: Record Item;
    // Item: Record Item;
    // RecGOrder: Record "Sales Header";
    // varInventory: Decimal;
    // LastPrice: Decimal;
    // LastDate: date;
    // Coefficiant: Decimal;
    // Vendor: Record Vendor;

    // trigger OnAfterGetCurrRecord()
    // var
    //     myInt: Integer;
    //     reclitem: Record Item;
    //     ItemTemp: Record ItemTmp;
    // begin
    //     CurrPage.SetSelectionFilter(reclitem);
    //     CurrPage."Produitéquivalent".Page.SetItemNo("No.");
    //     CurrPage.Kit.Page.SetItemNo("No.");
    //     CalcFields(Inventory);
    //     varInventory := Inventory;

    //     //-----------------------------------------------------------------------------------
    //     if Vendor.get("Vendor No.") then
    //         Coefficiant := Vendor.Coefficient;
    //     CalcFields(Inventory);
    //     varInventory := Inventory;

    //     FieldStyleQty := SetStyle("Qty. on Purch. Order");
    //     item.Get("No.");
    //     Item2.get("No.");
    //     if PurchaseSetup.Get() then begin
    //         if PurchaseSetup."Import Location Code" <> '' then begin
    //             Item.SetFilter("Location Filter", PurchaseSetup."Import Location Code");
    //             Item.CalcFields(Inventory);

    //             Item2.SetFilter("Location Filter", '<>%1', PurchaseSetup."Import Location Code");
    //             Item2.CalcFields(Inventory);

    //         end;
    //     end;
    // end;



    // trigger OnAfterGetRecord()

    // var
    //     lPurchasePrice: Record "purchase price";
    //     lCurrExchRate: Record "Currency Exchange Rate";

    //     PurPrice: Decimal;
    //     CurrencyFactor: Decimal;
    // begin
    //     SetStyle();
    //     Item2.reset;
    //     Item2.setrange("No.", "No.");
    //     if PurchaseSetup.Get() then
    //         if PurchaseSetup."Import Location Code" <> '' then
    //             Item2.SetFilter("Location Filter", PurchaseSetup."Import Location Code");
    //     if Item2.FindSet() then
    //         FieldStyleQty := SetStyle(ItemStk.Inventory);
    //     FieldStyleOnOrdQty := SetStyle(ItemStk."Qty. on Purch. Order");



    //     //----------------------------------------------------------------------------------

    //     if Vendor.get("Vendor No.") then
    //         Coefficiant := Vendor.Coefficient;
    //     CalcFields("Qty. on Purch. Order");
    //     // varInventory := Inventory;

    //     FieldStyleQty := SetStyle("Qty. on Purch. Order");

    //     item.Get("No.");
    //     Item2.get("No.");
    //     if PurchaseSetup.Get() then begin
    //         if PurchaseSetup."Import Location Code" <> '' then begin
    //             Item.SetFilter("Location Filter", PurchaseSetup."Import Location Code");
    //             Item.CalcFields(Inventory);
    //             FieldStyleInv := SetStyle(Item.Inventory);

    //             Item2.SetFilter("Location Filter", '<>%1', PurchaseSetup."Import Location Code");
    //             Item2.CalcFields(Inventory);
    //             FieldStyleInv2 := SetStyle(Item2.Inventory);


    //         end;
    //     end;
    //     LastDate := 0D;
    //     LastPrice := 0;
    //     PurPrice := 0;

    //     PurPrice := "Last Direct Cost";
    //     lPurchasePrice.Reset();
    //     lPurchasePrice.SetCurrentKey("Starting Date");
    //     lPurchasePrice.SetRange("Vendor No.", "Vendor No.");
    //     lPurchasePrice.SetRange("Item No.", "No.");
    //     lPurchasePrice.SetFilter("Unit of Measure Code", '%1|%2', "Purch. Unit of Measure", '');
    //     lPurchasePrice.SetRange("Currency Code", Vendor."Currency Code");
    //     if lPurchasePrice.FindLast() then begin
    //         LastDate := lPurchasePrice."Starting Date";
    //         PurPrice := lPurchasePrice."Direct Unit Cost";
    //     end;

    //     if Vendor."Currency Code" <> '' then begin

    //         CurrencyFactor := lCurrExchRate.ExchangeRate(Today, Vendor."Currency Code");
    //         if CurrencyFactor <> 0 then
    //             CurrencyFactor := 1 / CurrencyFactor
    //         else
    //             CurrencyFactor := 1;

    //         LastPrice := PurPrice * Coefficiant * CurrencyFactor;
    //     end
    //     else
    //         LastPrice := PurPrice * Coefficiant;
    // end;

    // trigger OnOpenPage()
    // begin
    //     CurrPage."Liste Recherche".Page.SetItemNo('02380');
    //     CurrPage."Liste Recherche".Page.Update();
    //     CurrPage."Produitéquivalent".Page.SetItemNo('02380');
    //     CurrPage."Produitéquivalent".Page.Update();
    //     CurrPage.Kit.Page.SetItemNo('02380');
    //     CurrPage.Kit.Page.Update();
    //     CurrPage.Update();
    // end;

    // trigger OnClosePage()
    // var
    //     ItemKit: Record ItemTmp;
    // begin

    //     ItemKit.reset;
    //     ItemKit.setrange("Order No", RecGOrder."No.");
    //     if ItemKit.FindSet() then
    //         ItemKit.DeleteAll();

    // end;
}