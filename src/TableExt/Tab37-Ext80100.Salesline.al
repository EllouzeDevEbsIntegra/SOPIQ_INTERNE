tableextension 80100 "Sales line" extends "Sales line" //37
{
    fields
    {
        modify("No.")
        {
            trigger OnAfterValidate()
            var
                SalesInvoiceLine: Record "Sales Invoice Line";
            begin
                "Initial Unit Price" := "Unit Price";
                "Initial Discount" := "Line Discount %";

                SalesInvoiceLine.Reset();
                SalesInvoiceLine.SetRange("Sell-to Customer No.", rec."Sell-to Customer No.");
                SalesInvoiceLine.SetRange("No.", rec."No.");
                if SalesInvoiceLine.FindLast() then begin
                    lastSalesPrice := SalesInvoiceLine."Unit Price";
                    lastSalesDate := SalesInvoiceLine."Posting Date";
                    lastSalesDiscount := SalesInvoiceLine."Line Discount %";
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
            begin
                if ("Unit Price" = "Initial Unit Price") Then begin
                    "Price modified" := false;
                end
                else
                    if ("Initial Unit Price" = 0) then begin
                        "Price modified" := false;
                    end
                    else
                        "Price modified" := true;

            end;
        }

        modify("Line Discount %")
        {


            trigger OnAfterValidate()

            begin
                if ("Line Discount %" = "Initial Discount") then begin
                    "Discount modified" := false;
                end
                else
                    "Discount modified" := true;
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