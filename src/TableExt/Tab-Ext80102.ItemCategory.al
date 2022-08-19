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
            begin
                if (rec.Description <> '') AND (rec.Indentation = 2) then begin
                    recItem.reset();
                    recItem.SetRange("Item Sub Product Code", code);
                    if recItem.FindFirst() then begin
                        repeat
                            recItem."Sous Groupe" := rec.Description;
                            recItem.Modify();
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