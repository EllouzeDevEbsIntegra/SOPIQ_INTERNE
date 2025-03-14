tableextension 80117 "Bin Content" extends "Bin Content" //7302
{
    fields
    {
        field(50113; "Count Content"; Integer)
        {
            Caption = 'Nombre d''emplacement';

            FieldClass = FlowField;
            CalcFormula = count("Bin Content" where("Location Code" = filter('<> ''LITIGE'''), "Bin Code" = filter('<>''RECEPTION'''), "Quantity" = filter(> 0), "Item No." = field("Item No.")));
        }

        field(50114; "Invoice No."; code[20])
        {
            DataClassification = ToBeClassified;
            TableRelation = "Purch. Inv. Line"."Document No." where("No." = field("Item No."));
        }

        field(50115; "Purch. Line Date"; Date)
        {
            DataClassification = ToBeClassified;
        }

        field(50116; "Purch. Line Price"; Decimal)
        {
            DataClassification = ToBeClassified;
        }

        field(50117; "Status"; Enum "Vendor Claim Statuts")
        {
            DataClassification = ToBeClassified;
        }
        field(50118; "Last Modification Date"; date)
        {
            DataClassification = ToBeClassified;
        }
        field(50119; Observation; Text[2048])
        {
            DataClassification = ToBeClassified;
        }
        field(50120; "Vendor Inv. No."; Code[35])
        {
            DataClassification = ToBeClassified;
        }
    }

    var
        myInt: Integer;
}