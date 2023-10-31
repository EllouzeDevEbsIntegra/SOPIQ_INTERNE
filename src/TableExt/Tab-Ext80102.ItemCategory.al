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

    trigger OnDelete()
    Var
        recCategory, TempCat : Record "Item Category";
        recCompany: Record Company;
        recCompanyInformation: Record "Company Information";
    begin

        // Message('%1', Database.CompanyName);
        recCompanyInformation.Reset();
        recCompanyInformation.SetRange(Company, Database.CompanyName);
        if recCompanyInformation.FindFirst() THEN begin
            // Message('%1 - %2', recCompanyInformation.Company, recCompanyInformation."Base Company");
            if (recCompanyInformation."Base Company" = false) then begin
                Error('Vous n''êtes pas autorisé à supprimer une catégorie !');
            end
            else begin
                TempCat.Reset();
                recCategory.Reset();
                recCategory.SetRange(Code, rec.Code);
                if recCategory.FindFirst() then begin
                    TempCat := recCategory;
                    // Message('cat Temporaire : %1 --- cat : %2', TempCat.Code, recCategory.Code);
                end;
                recCompany.Reset();
                if recCompany.FindSet() then begin
                    REPEAT

                        if (recCompany.Name <> recCompanyInformation.Company) then begin
                            TempCat.ChangeCompany(recCompany.Name);
                            recCategory.Reset();
                            recCategory.SetRange(Code, rec.Code);
                            recCategory.ChangeCompany(recCompany.Name);

                            if recCategory.FindFirst() then begin
                                recCategory.Delete();
                                // Message('Category Deleted : %1 Dans société : %2', recCategory.Code, recCompany.Name);
                            end;
                        end

                    UNTIL recCompany.Next() = 0;
                end;
            end;
        end;

    end;


    trigger OnBeforeInsert()
    Var
        recCompanyInformation: Record "Company Information";
    begin

        recCompanyInformation.SetRange(Company, Database.CompanyName);
        if recCompanyInformation.FindFirst() THEN begin

            if (recCompanyInformation."Base Company" = false) then begin
                Error('Vous n''êtes pas autorisé à ajouter une catégorie !');
            end;

        end;

    end;
}