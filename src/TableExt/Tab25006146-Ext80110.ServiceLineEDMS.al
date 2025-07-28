tableextension 80110 "Service Line EDMS" extends "Service Line EDMS" //25006146
{
    fields
    {
        field(80108; "Available Qty"; Decimal)
        {
            DataClassification = ToBeClassified;
            Editable = false;
            Caption = 'Stock Disponible';
        }

        field(80109; "Prix Vente Public"; Decimal) { }

        field(80110; "Last Price First Vendor"; Decimal) { }

        field(80111; "Last Price Date"; Date) { }

        field(80112; "Last Document Type"; Enum "Purchase Document Type") { }

        modify("No.")
        {
            trigger OnBeforeValidate()
            var
                recItem2: Record Item;
                recSalesLine: Record "Service Line EDMS";
            begin
                recSalesLine.SetRange("Document No.", "Document No.");
                recSalesLine.SetRange("No.", "No.");
                if recSalesLine.FindFirst() then begin
                    recItem2.SetRange("No.", recSalesLine."No.");
                    recItem2.SetRange("Item Type", recItem2."Item Type"::Item);
                    if recItem2.FindFirst() then
                        if not recItem2."Small Parts" then
                            Error('L''article %1 existe déjà dans ce document !', "No.");
                end;
            end;

            trigger OnAfterValidate()
            var
                recUnitofMesure: Record "Item Unit of Measure";
                recItem: Record Item;
                recPurchaseLine: Record "Purchase Line";
                recSetupPurchase: Record "Purchases & Payables Setup";
                defaultVendor: Code[20];
                defaultProfit: Decimal;
            begin
                recItem.SetRange("No.", rec."No.");
                if recItem.FindFirst() then begin
                    recUnitofMesure.SetRange("Item No.", rec."No.");
                    recUnitofMesure.SetRange("Code", recItem."Sales Unit of Measure");
                    if recUnitofMesure.FindFirst() then begin
                        rec."Unit of Measure Code" := recUnitofMesure.Code;
                        rec."Unit Price" := recItem."Unit Price" * recUnitofMesure."Qty. per Unit of Measure";
                        Validate(rec."Unit Price");
                    end;
                end;

                if recSetupPurchase.FindFirst() then begin
                    defaultVendor := recSetupPurchase."Default Vendor";
                    defaultProfit := recSetupPurchase."DEFAult Profit %";
                end;

                recPurchaseLine.SetRange("No.", "No.");
                recPurchaseLine.SetRange("Buy-from Vendor No.", defaultVendor);
                if recPurchaseLine.FindLast() then begin
                    rec."Last Price First Vendor" := recPurchaseLine."Direct Unit Cost";
                    rec."Prix Vente Public" := recPurchaseLine."Direct Unit Cost" * (1 + defaultProfit / 100);
                    rec."Last Price Date" := recPurchaseLine."Order Date";
                    rec."Last Document Type" := recPurchaseLine."Document Type";
                end;
            end;
        }

        modify("Quantity")
        {
            trigger OnAfterValidate()
            var
                recUnitofMesure: Record "Item Unit of Measure";
                recItem: Record Item;
            begin
                recItem.SetRange("No.", rec."No.");
                if recItem.FindFirst() then begin
                    recUnitofMesure.SetRange("Item No.", rec."No.");
                    recUnitofMesure.SetRange("Code", recItem."Sales Unit of Measure");
                    if recUnitofMesure.FindFirst() then begin
                        if recUnitofMesure."Qty. per Unit of Measure" <> 1 then begin
                            rec."Line Discount %" := xRec."Line Discount %";
                            rec."Unit of Measure Code" := recUnitofMesure.Code;
                            rec."Unit Price" := recItem."Unit Price" * recUnitofMesure."Qty. per Unit of Measure";
                            Validate(rec."Unit Price");
                        end;
                    end;
                end;
            end;
        }
    }

    var
        myInt: Integer;

    trigger OnAfterInsert()
    var
        recItem: Record Item;
        TaskGenerator: Record "Service Line Labor Task";
    begin
        //  Mise à jour du stock
        recItem.SetRange("No.", rec."No.");
        if recItem.FindFirst() then begin
            recItem.CalcFields("Available Inventory");
            rec."Available Qty" := recItem."Available Inventory";
            rec.Modify();
        end;

        // Vérification du type avant autogénération
        if rec.Type = rec.Type::Labor then
            if rec."No." <> '' then
                TaskGenerator.GenerateTasksFromLabor(rec."No.", rec."Document No.", rec."Line No.");
    end;
}
