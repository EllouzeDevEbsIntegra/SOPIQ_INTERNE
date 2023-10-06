pageextension 80185 "Catalog Item List" extends "Catalog Item List"//5726
{
    layout
    {
        addafter("Item No.")
        {
            field(Inventory; Inventory)
            {

            }

            field("Reserved Qty. on Inventory"; "Reserved Qty. on Inventory")
            {

            }
        }
        // Add changes to page layout here
    }

    actions
    {
        // Add changes to page actions here
    }

    var
        ItemStk: Record "Nonstock Item";

    trigger OnAfterGetRecord()

    begin

        if ItemStk.get("Item No.") Then
            ItemStk.CalcFields(Inventory, "Reserved Qty. on Inventory");

    end;
}