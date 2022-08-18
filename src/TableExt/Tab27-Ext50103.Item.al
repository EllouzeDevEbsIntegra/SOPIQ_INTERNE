tableextension 50103 "Item" extends Item //27
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
    }

    var

        recItemOld: Record "Item old transaction";
}