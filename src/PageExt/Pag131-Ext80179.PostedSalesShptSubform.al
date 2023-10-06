pageextension 80179 "Posted Sales Shpt. Subform" extends "Posted Sales Shpt. Subform" //131
{
    layout
    {
        // Add changes to page layout here
    }

    actions
    {
        modify(UndoShipment)
        {
            Visible = UndoShipment;
        }
    }

    var
        UndoShipment: Boolean;

    trigger OnOpenPage()
    var
        salesRecSetup: record "Sales & Receivables Setup";
    begin
        UndoShipment := false;

        salesRecSetup.Reset();
        if salesRecSetup.FindFirst() then begin
            if (salesRecSetup.UndoShipment) then UndoShipment := true else UndoShipment := BS;
        end;


    end;
}