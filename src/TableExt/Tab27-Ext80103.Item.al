tableextension 80103 "Item" extends Item //27
{
    fields
    {
        field(80103; "Sales Qty 'Year'"; Decimal)
        {
            CalcFormula = - Sum("Value Entry"."Invoiced Quantity" WHERE("Item Ledger Entry Type" = CONST(Sale),
                                                                        "Item No." = FIELD("No."),
                                                                        "Global Dimension 1 Code" = FIELD("Global Dimension 1 Filter"),
                                                                        "Global Dimension 2 Code" = FIELD("Global Dimension 2 Filter"),
                                                                        "Location Code" = FIELD("Location Filter"),
                                                                        "Drop Shipment" = FIELD("Drop Shipment Filter"),
                                                                        "Variant Code" = FIELD("Variant Filter"),
                                                                        "Posting Date" = FIELD("Date filter 'Year'")));
            Caption = 'Sales (Qty.)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }

        field(80104; "Sales Qty 'Year-1'"; Decimal)
        {
            CalcFormula = - Sum("Value Entry"."Invoiced Quantity" WHERE("Item Ledger Entry Type" = CONST(Sale),
                                                                        "Item No." = FIELD("No."),
                                                                        "Global Dimension 1 Code" = FIELD("Global Dimension 1 Filter"),
                                                                        "Global Dimension 2 Code" = FIELD("Global Dimension 2 Filter"),
                                                                        "Location Code" = FIELD("Location Filter"),
                                                                        "Drop Shipment" = FIELD("Drop Shipment Filter"),
                                                                        "Variant Code" = FIELD("Variant Filter"),
                                                                        "Posting Date" = FIELD("Date filter 'Year-1'")));
            Caption = 'Sales (Qty.)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }

        field(80105; "Date filter 'Year'"; Date)
        {

        }
        field(80106; "Date filter 'Year-1'"; Date)
        {

        }

        // modify("Item Replacement No.")
        // {
        //     trigger OnAfterValidate()
        //     begin

        //         if (xRec."Item Replacement No." <> '') AND ("Item Replacement No." <> '') then begin

        //             DeleteReplacementItem("No.", "Item Replacement No.");
        //             Message('Step 1 %1 - %2', "No.", "Item Replacement No.");
        //         end;

        //         if (xRec."Item Replacement No." = '') AND ("Item Replacement No." <> '') then begin
        //             DeleteReplacement("No.", "Item Replacement No.");
        //             CreateReplacementItem("No.", "Item Replacement No.");
        //             Message('Step 2 %1 - %2', "No.", "Item Replacement No.");
        //         end;
        //     end;


        // }


        modify(Reserve)
        {
            trigger OnBeforeValidate()
            begin
                If (Type = Type::Inventory) then Reserve := Reserve::Always;
            end;
        }

        modify("Vendor Item No.")
        {
            trigger OnAfterValidate()
            begin
                "Vendor Item No." := "Vendor Item No.".Replace(' ', '');
            end;
        }

        field(50102; "Replacement No"; Code[20])
        {
            Caption = 'Référence de Remplacement';
            TableRelation = item;
            trigger OnValidate()
            begin
                if (xRec."Item Replacement No." <> '') AND ("Item Replacement No." <> '') then
                    DeleteReplacementItem("No.", "Item Replacement No.");

                if (xRec."Item Replacement No." = '') AND ("Item Replacement No." <> '') then
                    CreateReplacementItem("No.", "Item Replacement No.");
            end;

        }
        field(50103; "PurshQty20"; integer)
        {
            CalcFormula = sum("Item old transaction"."Purshase Qty" where("Item N°" = field("No."), Year = const('2020')));
            Editable = false;
            FieldClass = FlowField;
        }

        field(50104; "PurshQty21"; integer)
        {
            CalcFormula = sum("Item old transaction"."Purshase Qty" where("Item N°" = field("No."), Year = const('2021')));
            Editable = false;
            FieldClass = FlowField;
        }

        field(50105; "SalesQty20"; integer)
        {
            CalcFormula = sum("Item old transaction"."Sales Qty" where("Item N°" = field("No."), Year = const('2020')));
            Editable = false;
            FieldClass = FlowField;
        }

        field(50106; "SalesQty21"; integer)
        {
            CalcFormula = sum("Item old transaction"."Sales Qty" where("Item N°" = field("No."), Year = const('2021')));
            Editable = false;
            FieldClass = FlowField;
        }


        field(50119; "ImportQty"; Decimal)
        {
            CalcFormula = sum("Item Ledger Entry".Quantity where("Item No." = field("No."), "Location Code" = filter('IMPORT')));
            Editable = false;
            FieldClass = FlowField;
            DecimalPlaces = 0 : 5;
        }

        field(50120; "StockQty"; Decimal)
        {
            CalcFormula = sum("Item Ledger Entry".Quantity where("Item No." = field("No."), "Location Code" = filter('<>IMPORT&<>LITIGE')));
            Editable = false;
            FieldClass = FlowField;
            DecimalPlaces = 0 : 5;
        }

        field(50220; "StockMagPrincipal"; Decimal)
        {
            CalcFormula = sum("Item Ledger Entry".Quantity where("Item No." = field("No."), "Location Code" = filter('MG-SFAX')));
            Editable = false;
            FieldClass = FlowField;
            DecimalPlaces = 0 : 5;
        }




        field(50111; "Last Date"; Date)
        {
            CalcFormula = max("purchase price"."Starting Date" where("Item No." = field("No."), "Ending Date" = filter(0D)));
            Editable = false;
            FieldClass = FlowField;
        }

        field(50171; "Last Ending Date"; Date)
        {
            CalcFormula = max("purchase price"."Ending Date" where("Item No." = field("No.")));
            Editable = false;
            FieldClass = FlowField;
        }

        field(50172; "Last starting Date"; Date)
        {
            CalcFormula = max("purchase price"."Starting Date" where("Item No." = field("No.")));
            Editable = false;
            FieldClass = FlowField;
        }

        field(50107; "Last Curr. Price."; Decimal)
        {
            CalcFormula = lookup("purchase price"."Direct Unit Cost" where("Item No." = field("No."), "Ending Date" = filter(0D), "Starting Date" = field("Last Date")));
            Editable = false;
            FieldClass = FlowField;
            DecimalPlaces = 2 : 2;
        }

        field(50170; "Pre Last Curr. Price."; Decimal)
        {
            CalcFormula = lookup("purchase price"."Direct Unit Cost" where("Item No." = field("No."), "Ending Date" = field("Last Ending Date")));
            Editable = false;
            FieldClass = FlowField;
            DecimalPlaces = 2 : 2;
        }

        field(50108; "Last. Pursh. cost DS"; Decimal)
        {
            DataClassification = ToBeClassified;
            // CalcFormula = sum("purchase price"."Direct Unit Cost" where("Item No." = field("No."), "Ending Date" = filter(' ')));
            Editable = false;
            // FieldClass = FlowField;
            DecimalPlaces = 3 : 3;
        }

        field(50109; "Last. Pursh. Date"; Date)
        {
            DataClassification = ToBeClassified;
        }

        field(50110; "Last. Preferential"; Boolean)
        {
            DataClassification = ToBeClassified;
        }

        field(50112; "First Reception Date"; Date)
        {
            Caption = 'Date récep la plus proche';
            CalcFormula = Min("Purchase Line"."Expected Receipt Date" where("No." = field("No."), "Outstanding Quantity" = Filter('> 0'), "Document Type" = filter(Order)));
            Editable = false;
            FieldClass = FlowField;
        }

        field(50113; "Count Content"; Integer)
        {
            Caption = 'Nombre d''emplacement';

            FieldClass = FlowField;
            CalcFormula = count("Bin Content" where("Quantity" = filter(> 0), "Item No." = field("No.")));
        }

        field(50114; "Fabricant Is Actif"; Boolean)
        {
            Caption = 'Fabricant est Actif';
            CalcFormula = lookup(Manufacturer.Actif where(Code = field("Manufacturer Code")));
            FieldClass = FlowField;
        }


        field(50130; "NbJourRupture"; Decimal)
        {
            CalcFormula = sum("Specific Item Ledger Entry".Quantity where("Item No." = field("No."), "Entry Type" = filter(10)));
            Editable = false;
            FieldClass = FlowField;
            DecimalPlaces = 0 : 0;
        }

        // field(50150; "SP Incoming Quantity"; Decimal)
        // {
        //     CalcFormula = Sum("Specific Item Ledger Entry".Quantity WHERE("Item No." = FIELD("No."),
        //                                                         "Entry Type" = filter("Positive Adjmt." | Purchase),
        //                                                         "Document No." = Filter('<>''RECTR STK 2022'''),
        //                                                           "Location Code" = FIELD("Location Filter"),
        //                                                           "Drop Shipment" = FIELD("Drop Shipment Filter"),
        //                                                           "Unit of Measure Code" = FIELD("Unit of Measure Filter")));
        //     DecimalPlaces = 0 : 5;
        //     Editable = false;
        //     FieldClass = FlowField;
        // }

        // field(50151; "SP Outgoing Quantity"; Decimal)
        // {
        //     CalcFormula = Sum("Specific Item Ledger Entry".Quantity WHERE("Item No." = FIELD("No."),
        //                                                         "Entry Type" = filter("Negative Adjmt." | Sale),
        //                                                          "Document No." = Filter('<>''RECTR STK 2022'''),
        //                                                           "Location Code" = FIELD("Location Filter"),
        //                                                           "Drop Shipment" = FIELD("Drop Shipment Filter"),
        //                                                           "Unit of Measure Code" = FIELD("Unit of Measure Filter")));
        //     DecimalPlaces = 0 : 5;
        //     Editable = false;
        //     FieldClass = FlowField;
        // }

        field(50131; "Fabricant WS"; Code[50])
        {
            DataClassification = ToBeClassified;
        }


        field(50132; "LastPurchPricePrincipalVendor"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'Prix Revendeur';
        }


    }


    trigger OnAfterInsert()
    var
        recVendorByManufacturer: Record "Vendor By Manufacturer";
        recItemVendor: Record "Item Vendor";
        recVendor: Record "Vendor";
        recItemMaster: Record "items Master";
    begin
        recVendorByManufacturer.SetRange("Manufacturer Code", "Manufacturer Code");
        if recVendorByManufacturer.FindSet() then begin
            repeat

                recItemVendor.Init();
                recItemVendor."Item No." := "No.";
                recItemVendor."Vendor No." := recVendorByManufacturer."Vendor Code";
                recItemVendor."Vendor Item No." := "No.";
                if recVendor.Get(recVendorByManufacturer."Vendor Code") then recItemVendor."Lead Time Calculation" := recVendor."Lead Time Calculation";
                recItemVendor.Insert;

            until recVendorByManufacturer.next = 0;

        end;


        recItemMaster.Reset();
        recItemMaster.No := rec."No.";
        recItemMaster.Company := Database.CompanyName;
        recitemmaster.Insert();

    end;

    trigger OnAfterModify()
    var
        recItemMaster: Record "items Master";
    begin
        recItemMaster.SetRange(No, rec."No.");
        recItemMaster.SetRange(Company, Database.CompanyName);
        if recItemMaster.FindSet() then begin
            REPEAT
                recItemMaster.Famille := rec.Groupe;
                recItemMaster."Sous Famille" := rec."Sous Groupe";
                recItemMaster.Master := rec."Reference Origine Lié";
                recItemMaster.Modify();
            UNTIL recItemMaster.Next() = 0;
        end;
    end;


    procedure CreateReplacementItem(ReplacedNo: Code[20]; ReplacedBy: Code[20])
    var
        ItemSubstitution: Record "Item Substitution";
        Master: record "Nonstock Item";
        Item: Record Item;
    begin
        IF NOT Master.Get(ReplacedNo) then begin
            If Item.GET(ReplacedNo) then begin
                Master.Init();
                Master."Entry No." := ReplacedNo;
                Master."Item No." := ReplacedNo;
                Master."Vendor Item No." := ReplacedNo;
                Master.Description := Item.Description;
                Master.INSERT;
            end;
        end;
        IF NOT Master.Get(ReplacedBy) then begin
            If Item.GET(ReplacedBy) then begin
                Master.Init();
                Master."Entry No." := ReplacedBy;
                Master."Item No." := ReplacedBy;
                Master."Vendor Item No." := ReplacedBy;
                Master.Description := Item.Description;
                Master.INSERT;
            end;
        end;

        ItemSubstitution.init;
        ItemSubstitution.Type := ItemSubstitution.Type::"Nonstock Item";
        ItemSubstitution."No." := ReplacedNo;
        ItemSubstitution."Entry Type" := ItemSubstitution."Entry Type"::Replacement;
        ItemSubstitution."Substitute Type" := ItemSubstitution."Substitute Type"::Item;
        ItemSubstitution."Replacement Info." := ItemSubstitution."Replacement Info."::Replacement;
        ItemSubstitution."Substitute No." := ReplacedBy;
        ItemSubstitution.Description := 'Interne';
        ItemSubstitution."Posting Date" := Today;
        ItemSubstitution.Validate(Interchangeable, true);
        Message('%1 - %2 - %3 ', ItemSubstitution."No.", ItemSubstitution."Substitute No.", ItemSubstitution."Posting Date");
        ItemSubstitution.Insert();


    end;

    procedure DeleteReplacementItem(ReplacedNo: Code[20]; ReplacedBy: Code[20])
    var
        ItemSubstitution: Record "Item Substitution";
    begin
        ItemSubstitution.SetRange(Type, ItemSubstitution.Type::Item);
        ItemSubstitution.SetRange("No.", ReplacedNo);
        ItemSubstitution.SetRange("Entry Type", ItemSubstitution."Entry Type"::Replacement);
        ItemSubstitution.SetRange("Substitute Type", ItemSubstitution."Substitute Type"::Item);
        ItemSubstitution.SetRange("Replacement Info.", ItemSubstitution."Replacement Info."::Replacement);
        ItemSubstitution.SetRange("Substitute No.", ReplacedBy);
        IF ItemSubstitution.FindFirst() then
            ItemSubstitution.Delete();


    end;

}