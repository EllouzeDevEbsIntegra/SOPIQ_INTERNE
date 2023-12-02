tableextension 80104 "Purchase Line" extends "Purchase Line" //39
{
    fields
    {
        modify("No.")
        {
            trigger OnAfterValidate()
            var
                recItem: Record Item;
            begin
                if recItem.Get("No.") then Marge := recItem."Profit %";

            end;
        }

        field(80190; "Last Receipt Date"; Date)
        {
            CalcFormula = max("Purch. Rcpt. Line"."Posting Date" where("Order No." = field("Document No."), "Order Line No." = field("Line No.")));
            Editable = false;
            FieldClass = FlowField;
        }

        field(80104; "asking price"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'Prix demandé';

            trigger OnValidate()
            begin


            end;

        }

        field(80103; "asking qty"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'Qté demandé';
            DecimalPlaces = 0 : 5;

        }

        field(80110; "negotiated price"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'Prix négocié';
            trigger OnValidate()
            var
                recPurchasePrice: Record "Purchase Price";
            begin
                if ("negotiated price" > 0) then begin
                    "Initial Vendor Price" := "Vendor Unit Cost";
                    "Direct Unit Cost" := "negotiated price";
                    "Vendor Unit Cost" := "negotiated price";
                    // "Gap Unit Cost" := (("negotiated price" - "Initial Direct Unit Cost") / "Initial Direct Unit Cost") / 100;
                    Modify();

                    Validate("Direct Unit Cost", "Vendor Unit Cost");

                    recPurchasePrice.SetRange("Vendor No.", "Buy-from Vendor No.");
                    recPurchasePrice.SetRange("Item No.", "No.");
                    recPurchasePrice.SetRange("Ending Date", 0D);
                    if recPurchasePrice.FindFirst() then begin
                        repeat

                            recPurchasePrice."Direct Unit Cost" := "negotiated price";
                            recPurchasePrice.Modify();

                        until recPurchasePrice.Next() = 0;
                    end;


                end;
            end;
        }

        field(80111; "negotiated qty"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'Qté négocié';
            DecimalPlaces = 0 : 5;
            trigger OnValidate()

            begin
                if ("negotiated qty" > 0) then begin

                    Quantity := "negotiated qty";
                    Modify();
                    Validate(Quantity);
                end;
            end;
        }
        field(80112; "Initial Vendor Price"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'Prix Initial Vendeur';
            DecimalPlaces = 0 : 2;
        }

        field(80170; "Qty First Confirmation"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'Confirmation Initial Qte';
            DecimalPlaces = 0 : 5;
        }

        field(80171; "Quote Line Reason"; Enum "Quote Line Reason")
        {
            Caption = 'Raison de la Qté commandé';
            InitValue = ' ';
        }

        modify("Vendor Unit Cost")
        {
            trigger OnAfterValidate()
            var
                recPurchasePrice: Record "Purchase Price";
            begin
                "Initial Vendor Price" := "Vendor Unit Cost";
                recPurchasePrice.SetRange("Vendor No.", "Buy-from Vendor No.");
                recPurchasePrice.SetRange("Item No.", "No.");
                recPurchasePrice.SetRange("Ending Date", 0D);
                if recPurchasePrice.FindFirst() then begin
                    repeat
                        if (recPurchasePrice."Starting Date" = Today) then begin
                            recPurchasePrice."Direct Unit Cost" := "Vendor Unit Cost";
                            recPurchasePrice.Modify();
                        end;
                    until recPurchasePrice.Next() = 0;
                end;

            end;

        }

        modify(Preferential)
        {
            trigger OnAfterValidate()
            var
                recItem: Record Item;
            begin
                recItem.Reset();
                recItem.SetRange("No.", "No.");
                if recItem.FindFirst() then begin
                    recItem."Last. Preferential" := Preferential;
                    recItem.Modify();
                end;
            end;
        }


        field(80105; "Marge"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'Marge à définir';
            Editable = true;
        }

        field(80106; margeUpdate; Boolean)
        {
            DataClassification = ToBeClassified;
            Caption = 'Marge à jour';
            Editable = false;
            InitValue = false;
        }

        field(80119; "Prix vente calculé"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'Prix Vente Calculé';
            Editable = true;
        }

        field(80220; "Last Direct Cost"; Decimal)
        {
            Caption = 'Dernier Coût Direct';
            Editable = true;
            CalcFormula = lookup(Item."Last Direct Cost" where("No." = field("No.")));
            FieldClass = FlowField;
        }

        field(80300; "Stk Mg Principal"; Decimal)
        {
            DataClassification = ToBeClassified;
            Editable = false;
        }
    }

    var
        myInt: Integer;

    trigger OnAfterInsert()
    var
        recItem: Record Item;
        recInventorySetup: Record "Inventory Setup";

    begin

        recItem.Reset();
        recItem.SetRange("No.", rec."No.");
        if recItem.FindFirst() then begin
            // recInventorySetup.get();
            // recItem."Mg Principal Filter" := recInventorySetup."Magasin Central";
            // recItem.Modify();
            // recItem.CalcFields(StockMagPrincipal);
            recItem.CalcFields("Available Inventory");
            rec."Stk Mg Principal" := recItem."Available Inventory";
            // Message('Mg Principal Setup : %1 - Mg Principal Item :%2', recInventorySetup."Magasin Central", recItem."Mg Principal Filter");
            // Message('NO %1 - QteMgP %2 - SalesStkMgP %3', recItem."No.", recItem.StockMagPrincipal, "Stk Mg Principal");
            rec.Modify();

        end;

    end;


}