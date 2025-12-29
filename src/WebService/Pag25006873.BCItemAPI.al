
page 25006873 "BC Item API"
{
    PageType = API;
    SourceTable = Item;
    APIPublisher = 'sopiq';
    APIGroup = 'interne';
    APIVersion = 'v1.0';
    EntityName = 'bcItem';
    EntitySetName = 'bcItems';
    ODataKeyFields = SystemId;
    DelayedInsert = true;

    // Même vue/tri que ta ListPart
    SourceTableView =
        WHERE(Produit = CONST(false),
              "Fabricant Is Actif" = FILTER(true));

    layout
    {
        area(content)
        {
            repeater(General)
            {
                // --- Identification ---
                field(id; Rec.SystemId)
                {
                    Caption = 'id';
                    ApplicationArea = All;
                }

                // --- Champs affichés dans ta page ---
                field(vendorNo; Rec."Vendor No.")
                {
                    Caption = 'vendorNo';
                    ApplicationArea = All;
                }
                field(VendorItemNo; "Vendor Item No.")
                {
                    Caption = 'vendorItemNo';
                    ApplicationArea = All;
                }
                field(no; Rec."No.")
                {
                    Caption = 'no';
                    ApplicationArea = All;
                }

                field(ReferenceMaster; "Reference Origine Lié")
                {
                    Caption = 'ReferenceMaster';
                    ApplicationArea = All;
                }
                field(descriptionStructured; Rec."Description structurée")
                {
                    Caption = 'descriptionStructured';
                    ApplicationArea = All;
                }

                field(qtyStock; QtyStockVar)
                {
                    Caption = 'qtyStock';
                    ToolTip = 'Stock (FlowField "Qty Stock").';
                    ApplicationArea = All;
                }
                field(qtyImport; QtyImportVar)
                {
                    Caption = 'qtyImport';
                    ToolTip = 'Import (FlowField "Qty Import").';
                    ApplicationArea = All;
                }
                field(qtyOnPurchOrder; QtyOnPurchOrderVar)
                {
                    Caption = 'qtyOnPurchOrder';
                    ToolTip = 'Quantité sur commande achat (FlowField "Qty. on Purch. Order").';
                    ApplicationArea = All;
                }

                field(totalVendu; Rec."Total Vendu")
                {
                    Caption = 'totalVendu';
                    ApplicationArea = All;
                }
                field(venduCurrYear; "Total Vendu curr. Year")
                {
                    Caption = 'totalVenduCurrYear';
                    ApplicationArea = All;
                }
                field(acheteCurrYear; "Total Achete curr. Year")
                {
                    Caption = 'totalAcheteCurrYear';
                    ApplicationArea = All;
                }
                field(totalAchete; Rec."Total Achete")
                {
                    Caption = 'totalAchete';
                    ApplicationArea = All;
                }

                field(lastPurshCostDS; "Last. Pursh. cost DS")
                {
                    Caption = 'lastPurshCostDS';
                    ToolTip = 'Coût calculé ("Last. Pursh. cost DS").';
                    ApplicationArea = All;
                }
                field(lastPurshDate; "Last. Pursh. Date")
                {
                    Caption = 'lastPurshDate';
                    ToolTip = 'Dernier achat ("Last. Pursh. Date").';
                    ApplicationArea = All;
                }
                field(LastPreferential; "Last. Preferential")
                {
                    Caption = 'LastPreferential';
                    ToolTip = 'Dernier préférentiel ("Last. Preferential").';
                    ApplicationArea = All;
                }
                field(lastPurshaseDate; "Last Purchase Date")
                {
                    Caption = 'lastPurshaseDate';
                    ToolTip = 'Date dernier achat';
                    ApplicationArea = All;
                }
                field(unitPrice; Rec."Unit Price")
                {
                    Caption = 'unitPrice';
                    ApplicationArea = All;
                }
                field(lastCurrPrice; LastCurrPriceVar)
                {
                    Caption = 'lastCurrPrice';
                    ToolTip = 'PU Devise (FlowField "Last Curr. Price.").';
                    ApplicationArea = All;
                }
                field(lastDate; LastDateVar)
                {
                    Caption = 'lastDate';
                    ToolTip = 'Date prix devise (FlowField "Last Date").';
                    ApplicationArea = All;
                }

                // --- Styles (optionnels) en lecture ---
                field(styleQty; StyleQtyVar)
                {
                    Caption = 'styleQty';
                    ApplicationArea = All;
                }
                field(styleImportQty; StyleImportQtyVar)
                {
                    Caption = 'styleImportQty';
                    ApplicationArea = All;
                }
                field(styleOnPurchQty; StyleOnPurchQtyVar)
                {
                    Caption = 'styleOnPurchQty';
                    ApplicationArea = All;
                }
                field(manufacturerTecdocId; ManufacturerTecdocId)
                {
                    Caption = 'manufacturerTecdocId';
                    ApplicationArea = All;
                }
            }
        }
    }

    var
        // Variables pour les FlowFields (on les calcule à chaque enregistrement)
        QtyStockVar: Decimal;
        QtyImportVar: Decimal;
        QtyOnPurchOrderVar: Decimal;
        LastCurrPriceVar: Decimal;
        LastDateVar: Date;
        LastPurshCostDSVar: Decimal;
        LastPurshDateVar: Date;

        // Styles (comme ta page)
        StyleQtyVar: Text[50];
        StyleImportQtyVar: Text[50];
        StyleOnPurchQtyVar: Text[50];

        ManufacturerTecdocId: Code[20];


        recManufacturer: Record Manufacturer;

    trigger OnAfterGetRecord()
    begin
        // Nettoyage des variables
        Clear(QtyStockVar);
        Clear(QtyImportVar);
        Clear(QtyOnPurchOrderVar);
        Clear(LastCurrPriceVar);
        Clear(LastDateVar);
        Clear(StyleQtyVar);
        Clear(StyleImportQtyVar);
        Clear(StyleOnPurchQtyVar);
        Clear(ManufacturerTecdocId);


        recManufacturer.Reset();
        if recManufacturer.GET(rec."Manufacturer Code") then begin
            ManufacturerTecdocId := recManufacturer."ID TechDOC";
        end;


        // Calcul des FlowFields
        Rec.CalcFields("Last Curr. Price.", "Qty. on Purch. Order", "Last Date", "Qty Stock", "Qty Import", "Current Year");
        rec.CalcFields("Total Vendu curr. Year", "Total Achete curr. Year");

        QtyStockVar := Rec."Qty Stock";
        QtyImportVar := Rec."Qty Import";
        QtyOnPurchOrderVar := Rec."Qty. on Purch. Order";
        LastCurrPriceVar := Rec."Last Curr. Price.";
        LastDateVar := Rec."Last Date";


        // Styles (Favorable si > 0, sinon Unfavorable)
        StyleQtyVar := SetStyleQte(QtyStockVar);
        StyleImportQtyVar := SetStyleQte(QtyImportVar);
        StyleOnPurchQtyVar := SetStyleQte(QtyOnPurchOrderVar);
    end;

    local procedure SetStyleQte(PDecimal: Decimal): Text[50]
    begin
        if PDecimal <= 0 then
            exit('Unfavorable')
        else
            exit('Favorable');
    end;
}
