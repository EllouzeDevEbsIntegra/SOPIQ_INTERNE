
page 25006868 "Purchase Quote Line API"
{
    PageType = API;
    SourceTable = "Purchase Line";
    APIPublisher = 'sopiq';
    APIGroup = 'interne';
    APIVersion = 'v1.0';
    EntityName = 'quoteLine';
    EntitySetName = 'quoteLines';
    ODataKeyFields = SystemId;
    DelayedInsert = true;

    SourceTableView = WHERE("Document Type" = CONST(Quote));

    layout
    {
        area(content)
        {
            repeater(Fields)
            {
                // --- Clé/Identification ---
                field(id; Rec.SystemId)
                {
                    Caption = 'id';
                    ApplicationArea = All;
                }
                field(documentNo; Rec."Document No.")
                {
                    Caption = 'documentNo';
                    ApplicationArea = All;
                }
                field(lineNo; Rec."Line No.")
                {
                    Caption = 'lineNo';
                    ApplicationArea = All;
                }

                field(CompareQuoteNo; "Compare Quote No.")
                {
                    Caption = 'compareQuoteNo';
                    ApplicationArea = All;
                }
                field(ReferenceMaster; "Reference Origine Lié")
                {
                    Caption = 'referenceOrigineLie';
                    ApplicationArea = All;
                }

                // --- Champs natifs de la page 50021 ---
                field(buyFromVendorNo; Rec."Buy-from Vendor No.")
                {
                    Caption = 'buyFromVendorNo';
                    ApplicationArea = All;
                }
                field(no; Rec."No.")
                {
                    Caption = 'no';
                    ApplicationArea = All;
                }
                field(descriptionStructured; Rec."Description structurée")
                {
                    Caption = 'descriptionStructured';
                    ApplicationArea = All;
                }
                field(unitPriceLCY; Rec."Unit Price (LCY)")
                {
                    Caption = 'unitPriceLCY';
                    ApplicationArea = All;
                }
                field(initialQuantity; Rec."Initial Quantity")
                {
                    Caption = 'initialQuantity';
                    ApplicationArea = All;
                }
                field(vendorQuantity; Rec."Vendor Quantity")
                {
                    Caption = 'vendorQuantity';
                    ApplicationArea = All;
                }
                field(quantity; Rec.Quantity)
                {
                    Caption = 'quantity';
                    ApplicationArea = All;
                }
                field(treated; Rec.Treated)
                {
                    Caption = 'treated';
                    ApplicationArea = All;
                }
                field(gapUnitCost; Rec."Gap Unit Cost")
                {
                    Caption = 'gapUnitCost';
                    ApplicationArea = All;
                }
                field(preferential; Rec.Preferential)
                {
                    Caption = 'preferential';
                    ApplicationArea = All;
                }
                field(directUnitCost; Rec."Direct Unit Cost")
                {
                    Caption = 'lastUnitPrice';
                    ApplicationArea = All;
                }
                field(initialVendorPrice; Rec."Initial Vendor Price")
                {
                    Caption = 'initialVendorPrice';
                    ApplicationArea = All;
                }
                field(prixDeRevientCalcule; Rec."Prix de revient (calcule)")
                {
                    Caption = 'prixDeRevientCalcule';
                    ApplicationArea = All;
                }

                // --- Champs calculés affichés sur la page 50021 ---
                field(importInventory; ImportInventoryVar)
                {
                    Caption = 'importInventory';
                    ToolTip = 'Stock import (Item Inventory filtré sur le lieu Import).';
                    ApplicationArea = All;
                }
                field(inventoryWithoutImport; InventoryWithoutImportVar)
                {
                    Caption = 'inventoryWithoutImport';
                    ToolTip = 'Stock actuel hors lieu Import.';
                    ApplicationArea = All;
                }
                field(qtyOnPurchOrder; QtyOnPurchOrderVar)
                {
                    Caption = 'qtyOnPurchOrder';
                    ToolTip = 'Qté sur commandes achat (Item."Qty. on Purch. Order").';
                    ApplicationArea = All;
                }
                field(lastDirectUnitCostCalculated; LastDirectUnitCostCalculatedVar)
                {
                    Caption = 'lastDirectUnitCostCalculated';
                    ToolTip = 'Ancien prix de revient (Item."Last Direct Cost" × Vendor.Coefficient).';
                    ApplicationArea = All;
                }
                field(calcAncienPrixDeVente; CalcAncienPrixDeVenteVar)
                {
                    Caption = 'calcAncienPrixDeVente';
                    ToolTip = 'Prix de vente (Calculé) = Prix de revient (calcule) / (100 - Item."Profit %") × 100.';
                    ApplicationArea = All;
                }

                // --- Champs page extension 80123 ---
                field(availableInventory; AvailableInventoryVar)
                {
                    Caption = 'availableInventory';
                    ToolTip = 'Stock disponible (Item."Available Inventory").';
                    ApplicationArea = All;
                }
                field(dateDernierAchat; LastPurchaseDateVar)
                {
                    Caption = 'dateDernierAchat';
                    ToolTip = 'Date du dernier achat (Item."Last. Pursh. Date").';
                    ApplicationArea = All;
                }
                field(quoteLineReason; Rec."Quote Line Reason")
                {
                    Caption = 'quoteLineReason';
                    ApplicationArea = All;
                }
                field(askingPrice; Rec."asking price")
                {
                    Caption = 'askingPrice';
                    ApplicationArea = All;

                    // On reproduit le comportement de la page extension :
                    // quand le prix est saisi, on met "asking qty" = "Vendor Quantity"
                    trigger OnValidate()
                    begin
                        Rec."asking qty" := Rec."Vendor Quantity";
                    end;
                }
                field(askingQty; Rec."asking qty")
                {
                    Caption = 'askingQty';
                    ApplicationArea = All;
                }

                // --- (Optionnel) Exposer aussi les styles de la page, si vous le souhaitez ---
                field(styleQty; StyleQtyVar)
                {
                    Caption = 'styleQty';
                    ToolTip = 'Style calculé en fonction des quantités (Favorable/Unfavorable).';
                    ApplicationArea = All;
                }
                field(styleInvImport; StyleInvImportVar)
                {
                    Caption = 'styleInvImport';
                    ApplicationArea = All;
                }
                field(styleInvNoImport; StyleInvNoImportVar)
                {
                    Caption = 'styleInvNoImport';
                    ApplicationArea = All;
                }
                field(styleDate; StyleDateVar)
                {
                    Caption = 'styleDate';
                    ToolTip = 'Style en fonction de la date du dernier achat (Strong/Attention/Unfavorable).';
                    ApplicationArea = All;
                }
                field(LastDirectCost; "Last Direct Cost")
                {
                    Caption = 'lastDirectCost';
                    ApplicationArea = All;
                }
                field(VendorItemNo; item."Vendor Item No.")
                {
                    Caption = 'vendorItemNo';
                    ApplicationArea = All;
                }
                field(ManufacturerTecdocId; ManufacturerTecdocId)
                {
                    Caption = 'manufacturerTecdocId';
                    ApplicationArea = All;
                }


            }
        }
    }

    var
        // Items pour calculs
        Item: Record Item;
        Item2: Record Item;
        Item3: Record Item;

        ManufacturerTecdocId: Code[20];
        PurchaseSetup: Record "Purchases & Payables Setup";

        // Variables exposées (champs calculés)
        ImportInventoryVar: Decimal;
        InventoryWithoutImportVar: Decimal;
        QtyOnPurchOrderVar: Decimal;
        LastDirectUnitCostCalculatedVar: Decimal;
        CalcAncienPrixDeVenteVar: Decimal;
        AvailableInventoryVar: Decimal;
        LastPurchaseDateVar: Date;

        // Styles (optionnels)
        StyleQtyVar: Text[50];
        StyleInvImportVar: Text[50];
        StyleInvNoImportVar: Text[50];
        StyleDateVar: Text[50];
        recManufacturer: Record Manufacturer;

    trigger OnAfterGetRecord()
    begin
        Clear(ImportInventoryVar);
        Clear(InventoryWithoutImportVar);
        Clear(QtyOnPurchOrderVar);
        Clear(LastDirectUnitCostCalculatedVar);
        Clear(CalcAncienPrixDeVenteVar);
        Clear(AvailableInventoryVar);
        Clear(LastPurchaseDateVar);
        Clear(StyleQtyVar);
        Clear(StyleInvImportVar);
        Clear(StyleInvNoImportVar);
        Clear(StyleDateVar);
        Clear(ManufacturerTecdocId);






        if Rec."No." = '' then
            exit;

        // Récupération Item principal
        if Item.Get(Rec."No.") then begin

            recManufacturer.Reset();
            if recManufacturer.GET(Item."Manufacturer Code") then begin
                ManufacturerTecdocId := recManufacturer."ID TechDOC";
            end;


            // Qté sur commandes achat
            Item.CalcFields("Qty. on Purch. Order");
            QtyOnPurchOrderVar := Item."Qty. on Purch. Order";

            // Ancien prix de revient (Last Direct Cost * Vendor.Coefficient)
            LastDirectUnitCostCalculatedVar := GetLastDirectUnitCostCalculated();

            // Prix de vente (Calculé) = Prix de revient (calcule) / (100 - Item."Profit %") * 100
            CalcAncienPrixDeVenteVar := CalcAncienPrixDeVente();

            // Données de la page extension
            Item.CalcFields("Available Inventory");
            AvailableInventoryVar := Item."Available Inventory";
            LastPurchaseDateVar := Item."Last. Pursh. Date";

            // Styles (optionnel)
            StyleQtyVar := SetStyleQty(AvailableInventoryVar);
            StyleDateVar := SetStyleDate(LastPurchaseDateVar);
        end;

        // Stocks Import / Hors Import selon Purchase Setup."Import Location Code"
        if PurchaseSetup.Get() then
            if PurchaseSetup."Import Location Code" <> '' then begin
                if Item2.Get(Rec."No.") then begin
                    Item2.SetFilter("Location Filter", PurchaseSetup."Import Location Code");
                    Item2.CalcFields(Inventory);
                    ImportInventoryVar := Item2.Inventory;
                    StyleInvImportVar := SetStyleQty(ImportInventoryVar);
                end;

                if Item3.Get(Rec."No.") then begin
                    Item3.SetFilter("Location Filter", '<>%1', PurchaseSetup."Import Location Code");
                    Item3.CalcFields(Inventory);
                    InventoryWithoutImportVar := Item3.Inventory;
                    StyleInvNoImportVar := SetStyleQty(InventoryWithoutImportVar);
                end;
            end;
    end;

    trigger OnModifyRecord(): Boolean
    begin
        if rec.Quantity <> xrec.Quantity then begin
            rec.Validate(Treated, true);
        end;
    end;

    local procedure GetLastDirectUnitCostCalculated(): Decimal
    var
        Vendor: Record Vendor;
    begin
        if (Rec."Buy-from Vendor No." <> '') and Vendor.Get(Rec."Buy-from Vendor No.") then
            if (Rec."No." <> '') and Item.Get(Rec."No.") then
                exit(Item."Last Direct Cost" * Vendor.Coefficient);

        exit(0);
    end;

    local procedure CalcAncienPrixDeVente(): Decimal
    var
        Den: Decimal;
    begin
        if (Rec."No." = '') then
            exit(0);
        if not Item.Get(Rec."No.") then
            exit(0);

        // Même logique que votre page : ne tient compte que du Profit % de l'Item
        Den := 100 - Item."Profit %";
        if Den = 0 then
            exit(0);

        exit(Rec."Prix de revient (calcule)" / Den * 100);
    end;

    local procedure SetStyleQty(Value: Decimal): Text[50]
    begin
        if Value <= 0 then
            exit('Unfavorable')
        else
            exit('Favorable');
    end;

    local procedure SetStyleDate(PDate: Date): Text[50]
    var
        ref24m: Date;
        ref12m: Date;
    begin
        ref24m := CalcDate('<-24M>', WorkDate());
        ref12m := CalcDate('<-12M>', WorkDate());

        if PDate <= ref24m then
            exit('Unfavorable')
        else
            if PDate <= ref12m then
                exit('Attention')
            else
                exit('Strong');
    end;
}
