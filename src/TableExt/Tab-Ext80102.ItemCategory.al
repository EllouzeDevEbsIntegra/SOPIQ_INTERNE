tableextension 80102 "Item Category" extends "Item Category"
{
    fields
    {
        // Mettre à jour tous les libellé Groupe / sous groupe en cas de changement au niveau du descrption du sous catégories
        modify(Description)
        {
            trigger OnAfterValidate()
            var
                recItem: Record Item;
                recManufacturer: Record Manufacturer;
            begin
                if (rec.Description <> '') AND (rec.Indentation = 2) then begin
                    recItem.reset();
                    recItem.SetRange("Item Sub Product Code", code);
                    if recItem.FindFirst() then begin
                        repeat
                            recManufacturer.Reset();
                            recManufacturer.SetRange(Code, recitem."Manufacturer Code");
                            if recManufacturer.FindFirst() then begin
                                recItem."Sous Groupe" := rec.Description;
                                recItem.Description := rec.Description;
                                if (recItem."Champs libre" <> '') then begin
                                    recItem."Description structurée" := rec.Description + ' - ' + recItem."Champs libre";
                                    // Message(' test 1 %1', recManufacturer.Name);
                                    recItem."Search Description2" := recItem."No." + ' - ' + recItem."Description structurée" + ' - ' + recManufacturer.Name;

                                end
                                else begin
                                    recItem."Description structurée" := rec.Description;
                                    // Message(' test 2 %1', recManufacturer.Name);
                                    recItem."Search Description2" := recItem."No." + ' - ' + recItem."Description structurée" + ' - ' + recManufacturer.Name;


                                end;
                                recItem.Modify();
                            end

                        until recItem.Next() = 0;
                    end
                end
                else

                    if (rec.Description <> '') AND (rec.Indentation = 1) then begin
                        recItem.reset();
                        recItem.SetRange("Item Product Code", code);
                        if recItem.FindFirst() then begin
                            repeat
                                recItem."Groupe" := rec.Description;
                                recItem.Modify();
                            until recItem.Next() = 0;
                        end
                    end
                    else
                        if (rec.Description <> '') AND (rec.Indentation = 0) then begin
                            recItem.reset();
                            recItem.SetRange("Item Category Code", code);
                            if recItem.FindFirst() then begin
                                repeat
                                    recItem."Item Category" := rec.Description;
                                    recItem.Modify();
                                until recItem.Next() = 0;
                            end
                        end


            end;
        }
    }

    var
        myInt: Integer;
}