tableextension 80103 "Item" extends Item //27
{
    fields
    {
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



        field(50111; "Last Date"; Date)
        {
            CalcFormula = max("purchase price"."Starting Date" where("Item No." = field("No."), "Ending Date" = filter(0D)));
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
    end;

}