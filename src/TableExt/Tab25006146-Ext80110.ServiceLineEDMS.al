tableextension 80110 "Service Line EDMS" extends "Service Line EDMS" //25006146
{
    fields
    {
        field(80109; "Prix Vente Public"; Decimal)
        {

        }

        field(80110; "Last Price First Vendor"; Decimal)
        {

        }

        field(80111; "Last Price Date"; Date)
        {

        }

        field(80112; "Last Document Type"; Enum "Purchase Document Type")
        {

        }
        modify("No.")
        {
            trigger OnBeforeValidate()
            var
                recItem2: Record Item;
                recSalesLine: Record "Service Line EDMS";
            begin
                recSalesLine.Reset();
                recSalesLine.SetRange("Document No.", "Document No.");
                recSalesLine.SetRange("No.", "No.");
                if recSalesLine.FindFirst() then begin
                    recItem2.Reset();
                    recItem2.SetRange("No.", recSalesLine."No.");
                    recItem2.SetRange("Item Type", recItem2."Item Type"::Item);
                    // recItem2.Setfilter("Small Parts", 'False');
                    if recItem2.FindFirst() then begin
                        if (recItem2."Small Parts" = false) then begin
                            message('L''article %1 existe déja dans ce document !', "No.");
                            Error('L''article %1 existe déja dans ce document !', "No.");
                        end
                    end
                end;
            end;


            trigger OnAfterValidate()
            var
                recUnitofMesure: Record "Item Unit of Measure";
                recItem: Record Item;
                recPurchaseLine: Record "Purchase Line";
                recSetupPurchase: Record "Purchases & Payables Setup";
                defaultVendor: code[20];
                defaultProfit: Decimal;

            begin




                recUnitofMesure.Reset();
                recItem.Reset();
                recItem.SetRange("No.", rec."No.");
                if recItem.FindFirst() then begin

                    recUnitofMesure.SetRange("Item No.", rec."No.");
                    recUnitofMesure.SetRange("code", recItem."Sales Unit of Measure");
                    if recUnitofMesure.FindFirst() then begin
                        rec."Unit of Measure Code" := recUnitofMesure.Code;
                        rec."Unit Price" := recItem."Unit Price" * recUnitofMesure."Qty. per Unit of Measure";
                        Validate(rec."Unit Price");

                    end

                end;

                recSetupPurchase.Reset();
                if recSetupPurchase.FindFirst() then begin
                    defaultVendor := recSetupPurchase."Default Vendor";
                    defaultProfit := recSetupPurchase."DEFAult Profit %";
                end;

                recPurchaseLine.Reset();
                recPurchaseLine.SetRange("No.", "No.");
                recPurchaseLine.SetRange("Buy-from Vendor No.", defaultVendor);
                if recPurchaseLine.FindLast() then begin
                    rec."Last Price First Vendor" := recPurchaseLine."Direct Unit Cost";
                    rec."Prix Vente Public" := recPurchaseLine."Direct Unit Cost" * (1 + (defaultProfit / 100));
                    rec."Last Price Date" := recPurchaseLine."Order Date";
                    rec."Last Document Type" := recPurchaseLine."Document Type";
                    // Message('%1 - %2 - %3', rec."Last Price First Vendor", defaultVendor, (1 + (defaultProfit / 100)));
                end;

                // if (rec."Unit Price" < rec."Prix Vente Public") then Message('Attention ! Prix de vente à vérifier SVP !');

            end;

        }

        modify("Quantity")
        {
            trigger OnAfterValidate()
            var
                recUnitofMesure: Record "Item Unit of Measure";
                recItem: Record Item;

            begin

                recUnitofMesure.Reset();
                recItem.Reset();
                recItem.SetRange("No.", rec."No.");
                if recItem.FindFirst() then begin

                    recUnitofMesure.SetRange("Item No.", rec."No.");
                    recUnitofMesure.SetRange("code", recItem."Sales Unit of Measure");
                    if recUnitofMesure.FindFirst() then begin

                        if (recUnitofMesure."Qty. per Unit of Measure" <> 1) then begin
                            rec."Line Discount %" := xRec."Line Discount %";
                            rec."Unit of Measure Code" := recUnitofMesure.Code;
                            rec."Unit Price" := recItem."Unit Price" * recUnitofMesure."Qty. per Unit of Measure";
                            Validate(rec."Unit Price");
                        end;
                    end

                end

            end;

        }

        modify("Unit Price")
        {
            trigger OnAfterValidate()
            begin
                // if (rec."Unit Price" < rec."Prix Vente Public") then Message('Attention ! Prix de vente à vérifier SVP !');

            end;
        }

    }

    var
        myInt: Integer;
}