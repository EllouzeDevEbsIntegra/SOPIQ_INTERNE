tableextension 80100 "Sales line" extends "Sales line" //37
{
    fields
    {
        modify("No.")
        {
            trigger OnAfterValidate()
            var
                SalesInvoiceLine: Record "Sales Invoice Line";
                salesLine: Record "Sales Line";
                archiveLineBS: Record "Ligne archive BS";
                salesShipLine: Record "Sales Shipment Line";
                dateToCompare: Date;
                cmdVenteNo: Code[20];
            begin
                "Initial Unit Price" := "Unit Price";
                "Initial Discount" := "Line Discount %";

                dateToCompare := 19770101D;
                SalesInvoiceLine.Reset();
                SalesInvoiceLine.SetRange("Sell-to Customer No.", rec."Sell-to Customer No.");
                SalesInvoiceLine.SetRange("No.", rec."No.");
                if SalesInvoiceLine.FindLast() then begin
                    //Message('Facrure %1 - %2', SalesInvoiceLine."Posting Date", dateToCompare);
                    dateToCompare := SalesInvoiceLine."Posting Date";
                    lastSalesPrice := SalesInvoiceLine."Unit Price";
                    lastSalesDate := SalesInvoiceLine."Posting Date";
                    lastSalesDiscount := SalesInvoiceLine."Line Discount %";
                    lastSalesDocType := lastSalesDocType::FV;
                end;

                salesShipLine.Reset();
                salesShipLine.SetRange("Sell-to Customer No.", rec."Sell-to Customer No.");
                salesShipLine.SetRange("No.", rec."No.");
                salesShipLine.SetRange(BS, false);
                if salesShipLine.FindLast() then begin
                    //Message('BL %1 - %2', salesShipLine."Posting Date", dateToCompare);
                    if salesShipLine."Posting Date" > dateToCompare then begin
                        // Message('BL 2 %1 - %2', salesShipLine."Posting Date", dateToCompare);
                        dateToCompare := salesShipLine."Posting Date";
                        lastSalesPrice := salesShipLine."Unit Price";
                        lastSalesDate := salesShipLine."Posting Date";
                        lastSalesDiscount := salesShipLine."% Discount";
                        lastSalesDocType := lastSalesDocType::BL;
                        cmdVenteNo := salesShipLine."Order No.";
                    end;
                end;

                archiveLineBS.Reset();
                archiveLineBS.SetRange("Sell-to Customer No.", rec."Sell-to Customer No.");
                archiveLineBS.SetRange("No.", rec."No.");
                if archiveLineBS.FindLast() then begin
                    //Message('BS %1 - %2', archiveLineBS."Posting Date", dateToCompare);
                    if archiveLineBS."Posting Date" > dateToCompare then begin
                        //Message('BS 2 %1 - %2', archiveLineBS."Posting Date", dateToCompare);
                        dateToCompare := archiveLineBS."Posting Date";
                        lastSalesPrice := archiveLineBS."Unit Price";
                        lastSalesDate := archiveLineBS."Posting Date";
                        lastSalesDiscount := archiveLineBS."% Discount";
                        lastSalesDocType := lastSalesDocType::BS;
                        cmdVenteNo := archiveLineBS."Order No.";
                    end;
                end;

                salesLine.Reset();
                salesLine.SetRange("Sell-to Customer No.", rec."Sell-to Customer No.");
                salesLine.SetRange("No.", rec."No.");
                if salesLine.FindLast() then begin
                    // Message('CMD %1 - %2', salesLine."Shipment Date", dateToCompare);
                    if (salesLine."Shipment Date" > dateToCompare) AND (salesLine."Document No." <> cmdVenteNo) then begin
                        //Message('CMD 2 %1 - %2', salesLine."Posting Date", dateToCompare);
                        dateToCompare := salesLine."Shipment Date";
                        lastSalesPrice := salesLine."Unit Price";
                        lastSalesDate := salesLine."Shipment Date";
                        lastSalesDiscount := salesLine."Line Discount %";
                        lastSalesDocType := lastSalesDocType::CmdDevis;
                    end;
                end;
            end;


        }
        modify(Quantity)
        {
            trigger OnAfterValidate()
            var
                recItem: Record Item;
                recProfitAdd: Record "Customer Additional Profit";

            begin

                recItem.Reset();
                recItem.SetRange("No.", "No.");
                if recItem.FindFirst() then begin

                    recProfitAdd.Reset();
                    recProfitAdd.SetRange(Type, recProfitAdd.Type::"Remise Exceptionnelle");
                    recProfitAdd.SetRange("Item Manufacturer", recItem."Manufacturer Code");
                    recProfitAdd.SetRange(Customers, rec."Sell-to Customer No.");
                    if recProfitAdd.FindSet() then begin
                        repeat
                            if (recProfitAdd."Item Group" = 'PR') OR (recProfitAdd."Item Group" = recItem."Item Product Code") then begin

                                rec."Line Discount %" := recProfitAdd.Taux;
                                Validate(rec."Line Discount %");
                            end;

                        // Message('Here %1 - %2', recItem."No.", recItem."Manufacturer Code");

                        until recProfitAdd.next = 0;

                    end;

                end;
            end;
        }

        modify("Unit Price")
        {
            trigger OnAfterValidate()
            var
                RecCust: Record Customer;
            begin
                if ("Unit Price" = "Initial Unit Price") Then begin
                    "Price modified" := false;
                end
                else
                    if ("Initial Unit Price" = 0) then begin
                        "Price modified" := false;
                    end
                    else begin
                        "Price modified" := true;
                        RecCust.Reset();
                        RecCust.SetRange("No.", rec."Sell-to Customer No.");
                        RecCust.SetRange("Ecarter Ctrl Modif Prix Remise", true);
                        if RecCust.FindFirst() then begin
                            "Ctrl Modified Price" := true;
                        end;

                    end;


            end;
        }

        modify("Line Discount %")
        {


            trigger OnAfterValidate()
            var
                RecCust: Record Customer;
            begin
                if ("Line Discount %" = "Initial Discount") then begin
                    "Discount modified" := false;
                end
                else begin
                    "Discount modified" := true;
                    RecCust.Reset();
                    RecCust.SetRange("No.", rec."Sell-to Customer No.");
                    RecCust.SetRange("Ecarter Ctrl Modif Prix Remise", true);
                    if RecCust.FindFirst() then begin
                        "Ctrl Modified Discount" := true;
                    end;

                end;

            end;
        }

        field(50100; "Initial Unit Price"; Decimal)
        {
            DataClassification = ToBeClassified;
            Editable = false;
        }

        field(50101; "Price modified"; Boolean)
        {
            DataClassification = ToBeClassified;
            InitValue = false;
            Editable = false;
        }
        field(50110; "Discount modified"; Boolean)
        {
            DataClassification = ToBeClassified;
            InitValue = false;
            Editable = false;
        }
        field(14; "Ctrl Modified Price"; Boolean)
        {
            DataClassification = ToBeClassified;
            InitValue = false;
        }

        field(187; "Ctrl Modified Discount"; Boolean)
        {
            DataClassification = ToBeClassified;
            InitValue = false;
        }


        field(50104; "Initial Discount"; Decimal)
        {
            DataClassification = ToBeClassified;
            Editable = false;
        }

        field(50200; "Available Qty"; Decimal)
        {
            DataClassification = ToBeClassified;
            Editable = false;
            Caption = 'Stock Disponible';
        }

        field(50210; "Received Quantity"; Decimal)
        {
            Caption = 'Qte Receptionnée';

            FieldClass = FlowField;
            CalcFormula = lookup("Purchase Line"."Quantity Received" where("Special Order" = filter(true), "Document Type" = filter(Order), "Special Order Sales No." = field("Document No."), "Special Order Sales Line No." = field("Line No.")));
        }


        field(50211; lastSalesDate; Date)
        {
            Caption = 'Dernière Date Vente';
            DataClassification = ToBeClassified;
        }

        field(50212; lastSalesPrice; Decimal)
        {
            Caption = 'Dernier prix Vente';
            DataClassification = ToBeClassified;
        }

        field(50213; lastSalesDiscount; Decimal)
        {
            Caption = 'Dernière remise Vente';
            DataClassification = ToBeClassified;
        }
        field(50214; lastSalesDocType; Option)
        {
            OptionCaption = 'Facture vente, Bon de livraison, Bon de sortie, Cmd / Devis';
            OptionMembers = FV,BL,BS,CmdDevis;
            Caption = 'Dernière Type Document vente';
            DataClassification = ToBeClassified;
        }
        field(50215; "Description Structuré"; Text[200])
        {
            Caption = 'Description Structuré';
            FieldClass = FlowField;
            CalcFormula = lookup(Item."Description structurée" where("No." = field("No.")));
        }
        field(50216; "Is Ship Canceled"; Boolean)
        {
            Caption = 'Expédition Annulée';
            DataClassification = ToBeClassified;
        }
        field(50217; "Last Purchase Date"; Date)
        {
            Caption = 'Dernière Date Achat';
            FieldClass = FlowField;
            CalcFormula = lookup(Item."Last. Pursh. Date" where("No." = field("No.")));
        }
    }


    trigger OnAfterInsert()
    var
        recItem: Record Item;
    begin

        recItem.Reset();
        recItem.SetRange("No.", rec."No.");
        if recItem.FindFirst() then begin
            recItem.CalcFields("Available Inventory");
            rec."Available Qty" := recItem."Available Inventory";
            rec.Modify();
        end;

    end;

}