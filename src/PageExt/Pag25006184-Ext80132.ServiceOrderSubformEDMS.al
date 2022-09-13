pageextension 80132 "Service Order Subform EDMS" extends "Service Order Subform EDMS" //25006184
{
    layout
    {
        // Add changes to page layout here

        // modify(No)
        // {


        //     trigger OnafterValidate()
        //     var
        //         recUnitofMesure: Record "Item Unit of Measure";
        //         recItem: Record Item;

        //     begin
        //         recUnitofMesure.Reset();
        //         recItem.Reset();
        //         recItem.SetRange("No.", "No.");
        //         if recItem.FindFirst() then begin
        //             // Message('test item No : %1 - %2', recItem."No.", "No.");

        //             recUnitofMesure.SetRange("Item No.", "No.");
        //             recUnitofMesure.SetRange("code", recItem."Sales Unit of Measure");
        //             if recUnitofMesure.FindFirst() then begin
        //                 // Message('test unit item %1', recUnitofMesure."Item No.");
        //                 // Message('test sales item unit of mesue : %1', recItem."Sales Unit of Measure");
        //                 // Message('test unit mesure code : %1', recUnitofMesure.code);

        //                 "Unit of Measure Code" := recUnitofMesure.Code;
        //                 "Unit Price" := recItem."Unit Price" * recUnitofMesure."Qty. per Unit of Measure";
        //                 CurrPage.Update();

        //                 // Message('ref : %1  -  Unit : %2  -  Unit Price : %3', "No.", "Unit of Measure Code", "Unit Price");
        //             end

        //         end



        //     end;

        // }

        // modify(Quantity)
        // {


        //     trigger OnafterValidate()
        //     var
        //         recUnitofMesure: Record "Item Unit of Measure";
        //         recItem: Record Item;

        // begin
        //     recUnitofMesure.Reset();
        //     recItem.Reset();
        //     recItem.SetRange("No.", "No.");
        //     if recItem.FindFirst() then begin
        //         // Message('test item No : %1 - %2', recItem."No.", "No.");

        //         recUnitofMesure.SetRange("Item No.", "No.");
        //         recUnitofMesure.SetRange("code", recItem."Sales Unit of Measure");
        //         if recUnitofMesure.FindFirst() then begin
        //             // Message('test unit item %1', recUnitofMesure."Item No.");
        //             // Message('test sales item unit of mesue : %1', recItem."Sales Unit of Measure");
        //             // Message('test unit mesure code : %1', recUnitofMesure.code);

        //             "Unit of Measure Code" := recUnitofMesure.Code;
        //             "Unit Price" := recItem."Unit Price" * recUnitofMesure."Qty. per Unit of Measure";
        //             "Amount" := Quantity * recItem."Unit Price" * recUnitofMesure."Qty. per Unit of Measure" * (1 - ("Line Discount %" / 100));
        //             "Amount Including VAT" := Quantity * recItem."Unit Price" * recUnitofMesure."Qty. per Unit of Measure" * (1 - ("Line Discount %" / 100));
        //             "Line Amount" := Quantity * recItem."Unit Price" * recUnitofMesure."Qty. per Unit of Measure" * (1 - ("Line Discount %" / 100));
        //             CurrPage.Update();

        //             // Message('ref : %1  -  Unit : %2  -  Unit Price : %3', "No.", "Unit of Measure Code", "Unit Price");
        //         end

        //     end



        // end;
        // }
    }

    actions
    {
        // Add changes to page actions here
    }

    var
        myInt: Integer;
}