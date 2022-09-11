tableextension 80108 "Item Vendor" extends "Item Vendor" //99
{
    fields
    {
        field(80108; "Last. Price. Date"; date)
        {
            CalcFormula = lookup("purchase price"."Starting Date" where("Item No." = field("Item No."), "Vendor No." = field("Vendor No."), "Ending Date" = filter(' ')));
            Editable = false;
            FieldClass = FlowField;
        }

        field(80109; "Last. Price"; Decimal)
        {
            CalcFormula = lookup("purchase price"."Direct Unit Cost" where("Item No." = field("Item No."), "Vendor No." = field("Vendor No."), "Ending Date" = filter(' ')));
            Editable = false;
            FieldClass = FlowField;
        }

        field(80110; "Last. Preferentiel"; Boolean)
        {
            //    CalcFormula = lookup("purchase price"."Direct Unit Cost" where("Item No." = field("Item No."), "Vendor No." = field("Vendor No."), "Ending Date" = filter(' ')));
            //     Editable = false;
            //     FieldClass = FlowField;

        }

        field(80111; "Last. Pirce. DS"; Decimal)
        {
            Editable = false;

        }
    }

    var
        myInt: Integer;
}