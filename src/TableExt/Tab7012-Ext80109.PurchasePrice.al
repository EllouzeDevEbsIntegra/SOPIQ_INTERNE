tableextension 80109 "Purchase Price" extends "Purchase Price"//7012
{

    DrillDownPageID = "Purchase Prices";
    LookupPageID = "Purchase Prices";
    fields
    {
        field(80109; master; code[50])
        {
            CalcFormula = lookup(item."Reference Origine Lié" where("No." = field("Item No.")));
            Editable = false;
            FieldClass = FlowField;

        }

        field(80110; "No."; code[50])
        {
            CalcFormula = lookup(item."No." where("Reference Origine Lié" = field("master")));
            Editable = false;
            FieldClass = FlowField;

        }

        field(80111; "frs"; code[20])
        {
            CalcFormula = lookup(item."Vendor No." where("No." = field("No.")));
            Editable = false;
            FieldClass = FlowField;

        }

        field(80112; "Description"; Text[250])
        {
            CalcFormula = lookup(item."Description structurée" where("No." = field("No.")));
            Editable = false;
            FieldClass = FlowField;

        }

        field(80113; "Famille"; Text[250])
        {
            CalcFormula = lookup(item."Groupe" where("No." = field("No.")));
            Editable = false;
            FieldClass = FlowField;
        }

        field(80114; "Sous Famille"; Text[250])
        {
            CalcFormula = lookup(item."Sous Groupe" where("No." = field("No.")));
            Editable = false;
            FieldClass = FlowField;
        }

        field(80115; "Sales Qty"; Decimal)
        {
            CalcFormula = lookup(item."Sales (Qty.)" where("No." = field("No.")));
            Editable = false;
            FieldClass = FlowField;
        }



        field(80118; "Last Date"; Date)
        {
            CalcFormula = max("purchase price"."Starting Date" where("Item No." = field("No."), "Ending Date" = filter(0D)));
            Editable = false;
            FieldClass = FlowField;
        }

        field(80119; "Last Ending Date"; Date)
        {
            CalcFormula = max("purchase price"."Ending Date" where("Item No." = field("No.")));
            Editable = false;
            FieldClass = FlowField;
        }

        field(80120; "Last starting Date"; Date)
        {
            CalcFormula = max("purchase price"."Starting Date" where("Item No." = field("No.")));
            Editable = false;
            FieldClass = FlowField;
        }

        field(80121; "Last Curr. Price."; Decimal)
        {
            CalcFormula = lookup("purchase price"."Direct Unit Cost" where("Item No." = field("No."), "Ending Date" = filter(0D), "Starting Date" = field("Last Date")));
            Editable = false;
            FieldClass = FlowField;
            DecimalPlaces = 2 : 2;
        }

        field(80122; "Current Year"; Integer)
        {
            CalcFormula = lookup("Purchases & Payables Setup"."Current Year");
            Editable = false;
            FieldClass = FlowField;
        }

        field(80123; "Last Year"; Integer)
        {
            CalcFormula = lookup("Purchases & Payables Setup"."Last Year");
            Editable = false;
            FieldClass = FlowField;
        }
        field(80100; "Last Year-1"; Integer)
        {
            CalcFormula = lookup("Purchases & Payables Setup"."Last Year-1");
            Editable = false;
            FieldClass = FlowField;
        }

        field(80124; "Purch. Qty Curr. Year frs"; Decimal)
        {
            CalcFormula = Sum("Item Ledger Entry"."Invoiced Quantity" WHERE("Entry Type" = CONST(Purchase),
                                                                             "Item No." = FIELD("No."),
                                                                            year = field("Current Year")
                                                                            ));
            Caption = 'Purch. Qty Curr. Year frs';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(80125; "Purch. Qty Last Year frs"; Decimal)
        {
            CalcFormula = Sum("Item Ledger Entry"."Invoiced Quantity" WHERE("Entry Type" = CONST(Purchase),
                                                                             "Item No." = FIELD("No."),
                                                                            year = field("Last Year")
                                                                            ));
            Caption = 'Purch. Qty Curr. Year frs';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }

        field(80126; "Purch. Qty Curr. Year Vendor"; Decimal)
        {
            CalcFormula = Sum("Item Ledger Entry"."Invoiced Quantity" WHERE("Entry Type" = CONST(Purchase),
                                                                             "Item No." = FIELD("Item No."),
                                                                            year = field("Current Year")
                                                                            ));
            Caption = 'Purch. Qty Curr. Year Vendor';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(80127; "Purch. Qty Last Year Vendor"; Decimal)
        {
            CalcFormula = Sum("Item Ledger Entry"."Invoiced Quantity" WHERE("Entry Type" = CONST(Purchase),
                                                                             "Item No." = FIELD("Item No."),
                                                                            year = field("Last Year")
                                                                            ));
            Caption = 'Purch. Qty Curr. Year Vendor';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }



    }


}
