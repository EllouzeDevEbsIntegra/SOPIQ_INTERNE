tableextension 80110 "Service Line EDMS" extends "Service Line EDMS" //25006146
{
    fields
    {
        modify("No.")
        {
            trigger OnAfterValidate()
            var
                recUnitofMesure: Record "Item Unit of Measure";
                recItem: Record Item;

            begin
                recUnitofMesure.Reset();
                recItem.Reset();
                recItem.SetRange("No.", rec."No.");
                if recItem.FindFirst() then begin

                    recUnitofMesure.SetRange("Item No.", rec."No.");
                    recUnitofMesure.SetRange("code", recItem."Sales Unit of Measure");
                    if recUnitofMesure.FindFirst() then begin
                        rec."Unit of Measure Code" := recUnitofMesure.Code;
                        rec."Unit Price" := recItem."Unit Price" * recUnitofMesure."Qty. per Unit of Measure";
                        Validate(rec."Unit Price");

                    end

                end



            end;

        }

        modify("Quantity")
        {
            trigger OnAfterValidate()
            var
                recUnitofMesure: Record "Item Unit of Measure";
                recItem: Record Item;


            begin

                recUnitofMesure.Reset();
                recItem.Reset();
                recItem.SetRange("No.", rec."No.");
                if recItem.FindFirst() then begin

                    recUnitofMesure.SetRange("Item No.", rec."No.");
                    recUnitofMesure.SetRange("code", recItem."Sales Unit of Measure");
                    if recUnitofMesure.FindFirst() then begin

                        if (recUnitofMesure."Qty. per Unit of Measure" <> 1) then begin
                            rec."Line Discount %" := xRec."Line Discount %";
                            rec."Unit of Measure Code" := recUnitofMesure.Code;
                            rec."Unit Price" := recItem."Unit Price" * recUnitofMesure."Qty. per Unit of Measure";
                            Validate(rec."Unit Price");
                        end;
                    end

                end



            end;

        }
    }

    var
        myInt: Integer;
}