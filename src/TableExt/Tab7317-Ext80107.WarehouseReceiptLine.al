tableextension 80107 "Warehouse Receipt Line" extends "Warehouse Receipt Line" //7317
{
    fields
    {
        // Add changes to table fields here
        modify(Preferential)
        {
            trigger OnAfterValidate()
            var
                recItem: Record Item;
            begin
                recItem.Reset();
                recItem.SetRange("No.", "Item No.");
                if recItem.FindFirst() then begin
                    recItem."Last. Preferential" := Preferential;
                    recItem.Modify();
                end;
            end;
        }
    }

    var
        myInt: Integer;
}