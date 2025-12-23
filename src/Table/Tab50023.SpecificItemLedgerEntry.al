table 50023 "Specific Item Ledger Entry"
{
    Caption = 'Item Ledger Entry';
    DrillDownPageID = "Item Ledger Entries";
    LookupPageID = "Item Ledger Entries";
    Permissions = TableData "Item Ledger Entry" = rimd;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(2; "Item No."; Code[20])
        {
            Caption = 'Item No.';
        }
        field(3; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(4; "Entry Type"; Option)
        {
            Caption = 'Entry Type';
            OptionCaption = 'Purchase,Sale,Positive Adjmt.,Negative Adjmt.,Transfer,Consumption,Output, ,Assembly Consumption,Assembly Output,Rupture';
            OptionMembers = Purchase,Sale,"Positive Adjmt.","Negative Adjmt.",Transfer,Consumption,Output," ","Assembly Consumption","Assembly Output",Rupture;
        }
        field(5; "Source No."; Code[20])
        {
            Caption = 'Source No.';
            TableRelation = IF ("Source Type" = CONST(Customer)) Customer
            ELSE
            IF ("Source Type" = CONST(Vendor)) Vendor
            ELSE
            IF ("Source Type" = CONST(Item)) Item;
        }
        field(6; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(7; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(8; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location;
        }
        field(12; Quantity; Decimal)
        {
            Caption = 'Quantity';
            DecimalPlaces = 0 : 5;
        }
        field(13; "Remaining Quantity"; Decimal)
        {
            Caption = 'Remaining Quantity';
            DecimalPlaces = 0 : 5;
        }
        field(14; "Invoiced Quantity"; Decimal)
        {
            Caption = 'Invoiced Quantity';
            DecimalPlaces = 0 : 5;
        }
        field(28; "Applies-to Entry"; Integer)
        {
            Caption = 'Applies-to Entry';
        }
        field(29; Open; Boolean)
        {
            Caption = 'Open';
        }

        field(36; Positive; Boolean)
        {
            Caption = 'Positive';
        }
        field(40; "Shpt. Method Code"; Code[10])
        {
            Caption = 'Shpt. Method Code';
            TableRelation = "Shipment Method";
        }
        field(41; "Source Type"; Option)
        {
            Caption = 'Source Type';
            OptionCaption = ' ,Customer,Vendor,Item';
            OptionMembers = " ",Customer,Vendor,Item;
        }
        field(47; "Drop Shipment"; Boolean)
        {
            AccessByPermission = TableData "Drop Shpt. Post. Buffer" = R;
            Caption = 'Drop Shipment';
        }
        field(50; "Transaction Type"; Code[10])
        {
            Caption = 'Transaction Type';
            TableRelation = "Transaction Type";
        }
        field(51; "Transport Method"; Code[10])
        {
            Caption = 'Transport Method';
            TableRelation = "Transport Method";
        }

        field(60; "Document Date"; Date)
        {
            Caption = 'Document Date';
        }
        field(61; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
        }

        field(79; "Document Type"; Enum "Item Ledger Document Type")
        {
            Caption = 'Document Type';
        }
        field(80; "Document Line No."; Integer)
        {
            Caption = 'Document Line No.';
        }
        field(90; "Order Type"; Enum "Inventory Order Type")
        {
            Caption = 'Order Type';
            Editable = false;
        }
        field(91; "Order No."; Code[20])
        {
            Caption = 'Order No.';
            Editable = false;
        }
        field(92; "Order Line No."; Integer)
        {
            Caption = 'Order Line No.';
            Editable = false;
        }

        field(5404; "Qty. per Unit of Measure"; Decimal)
        {
            Caption = 'Qty. per Unit of Measure';
            DecimalPlaces = 0 : 5;
        }
        field(5407; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            TableRelation = "Item Unit of Measure".Code WHERE("Item No." = FIELD("Item No."));
        }

        field(5800; "Completely Invoiced"; Boolean)
        {
            Caption = 'Completely Invoiced';
        }
        field(5801; "Last Invoice Date"; Date)
        {
            Caption = 'Last Invoice Date';
        }
        field(5803; "Cost Amount (Expected)"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = Sum("Value Entry"."Cost Amount (Expected)" WHERE("Item Ledger Entry No." = FIELD("Entry No.")));
            Caption = 'Cost Amount (Expected)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5804; "Cost Amount (Actual)"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = Sum("Value Entry"."Cost Amount (Actual)" WHERE("Item Ledger Entry No." = FIELD("Entry No.")));
            Caption = 'Cost Amount (Actual)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5805; "Cost Amount (Non-Invtbl.)"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = Sum("Value Entry"."Cost Amount (Non-Invtbl.)" WHERE("Item Ledger Entry No." = FIELD("Entry No.")));
            Caption = 'Cost Amount (Non-Invtbl.)';
            Editable = false;
            FieldClass = FlowField;
        }


        field(5813; "Purchase Amount (Expected)"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = Sum("Value Entry"."Purchase Amount (Expected)" WHERE("Item Ledger Entry No." = FIELD("Entry No.")));
            Caption = 'Purchase Amount (Expected)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5814; "Purchase Amount (Actual)"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = Sum("Value Entry"."Purchase Amount (Actual)" WHERE("Item Ledger Entry No." = FIELD("Entry No.")));
            Caption = 'Purchase Amount (Actual)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5815; "Sales Amount (Expected)"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = Sum("Value Entry"."Sales Amount (Expected)" WHERE("Item Ledger Entry No." = FIELD("Entry No.")));
            Caption = 'Sales Amount (Expected)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5816; "Sales Amount (Actual)"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = Sum("Value Entry"."Sales Amount (Actual)" WHERE("Item Ledger Entry No." = FIELD("Entry No.")));
            Caption = 'Sales Amount (Actual)';
            Editable = false;
            FieldClass = FlowField;
        }

        field(25006001; "Item Type"; Option)
        {
            Caption = 'Item Type';
            OptionCaption = ' ,Item,Model Version';
            OptionMembers = " ",Item,"Model Version";
        }
        field(25006002; "Make Code"; Code[20])
        {
            Caption = 'Make Code';
            TableRelation = Make;
        }
        field(25006003; "Model Code"; Code[20])
        {
            Caption = 'Model Code';
            TableRelation = Model.Code where("Make Code" = field("Make Code"));
        }
        field(25006004; "Model Version No."; Code[20])
        {
            Caption = 'Model Version No.';
            TableRelation = Item."No." where("Make Code" = field("Make Code"),
                                              "Model Code" = field("Model Code"),
                                              "Item Type" = const("Model Version"));

            trigger OnLookup()
            var
                recItem: Record Item;
            begin
                recItem.SetCurrentkey("Item Type", "Make Code", "Model Code");
                recItem.SetRange("Item Type", recItem."item type"::"Model Version");
                recItem.SetRange("Make Code", "Make Code");
                recItem.SetRange("Model Code", "Model Code");
                if Page.RunModal(Page::"Item List", recItem) = Action::LookupOK then begin
                    Validate("Model Version No.", recItem."No.");
                end;
            end;
        }
        field(50023; Year; Integer)
        {
            DataClassification = ToBeClassified;
        }

        field(50024; "N° Doc Frs"; code[35])
        {
            AutoFormatType = 1;
            CalcFormula = lookup("Purch. Rcpt. Header"."Vendor Shipment No." where("No." = field("Document No.")));
            Caption = 'N° Doc Frs';
            Editable = false;
            FieldClass = FlowField;
        }

        field(50025; "Cmd Achat"; code[35])
        {
            AutoFormatType = 1;
            CalcFormula = lookup("Purch. Rcpt. Header"."Order No." where("No." = field("Document No.")));
            Caption = 'Cmd Achat';
            Editable = false;
            FieldClass = FlowField;
        }
        field(50026; "Cmd Vente"; code[35])
        {
            AutoFormatType = 1;
            CalcFormula = lookup("Sales Shipment Header"."Order No." where("No." = field("Document No.")));
            Caption = 'Cmd Vente';
            Editable = false;
            FieldClass = FlowField;
        }

    }

    keys
    {

    }

}