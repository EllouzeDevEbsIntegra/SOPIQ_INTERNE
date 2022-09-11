tableextension 80103 "Item" extends Item //27
{
    fields
    {

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

        field(50107; "Last Curr. Price."; Decimal)
        {
            CalcFormula = lookup("purchase price"."Direct Unit Cost" where("Item No." = field("No."), "Ending Date" = filter(' ')));
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

    }

}