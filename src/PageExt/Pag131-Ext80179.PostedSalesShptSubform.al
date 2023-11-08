pageextension 80179 "Posted Sales Shpt. Subform" extends "Posted Sales Shpt. Subform" //131
{
    layout
    {
        // Add changes to page layout here
        addbefore("Line Amount HT")
        {
            field("Unit Price"; "Unit Price")
            {
                ApplicationArea = all;

            }

            field("Line Discount %"; "Line Discount %")
            {
                ApplicationArea = all;
            }
        }
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

    trigger OnAfterGetRecord()
    var
        salesRecSetup: record "Sales & Receivables Setup";
    begin



        UndoShipment := BS;

        salesRecSetup.Reset();
        if salesRecSetup.FindFirst() then begin
            if (salesRecSetup.UndoShipment) then UndoShipment := true;

        end;

    end;
}