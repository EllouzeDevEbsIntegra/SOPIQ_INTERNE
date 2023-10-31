pageextension 80220 "Item Category Card" extends "Item Category Card" //5733
{
    layout
    {
        // Add changes to page layout here
    }

    actions
    {
        // Add changes to page actions here
    }

    var
        myInt: Integer;

    trigger OnClosePage()
    Var
        recCategory, TempCat : Record "Item Category";
        recCompany: Record Company;
        recCompanyInformation: Record "Company Information";
    begin

        TempCat.Reset();
        recCategory.Reset();
        recCategory.SetRange(Code, rec.Code);
        if recCategory.FindFirst() then begin
            TempCat := recCategory;
            // Message('cat Temporaire : %1 --- cat : %2', TempCat.Code, recCategory.Code);
        end;

        recCompanyInformation.Reset();
        recCompanyInformation.SetRange("Base Company", true);
        if recCompanyInformation.FindFirst() then begin

            if (Database.CompanyName = recCompanyInformation.Company) then begin

                recCompany.Reset();
                if recCompany.FindSet() then begin
                    REPEAT

                        if (recCompany.Name <> recCompanyInformation.Company) then begin
                            TempCat.ChangeCompany(recCompany.Name);
                            recCategory.Reset();
                            recCategory.SetRange(Code, rec.Code);
                            recCategory.ChangeCompany(recCompany.Name);

                            if recCategory.FindFirst() then begin
                                recCategory := rec;
                                recCategory.Modify();
                                // Message('Category Modified : %1 Dans société : %2', recCategory.Code, recCompany.Name);
                            end
                            else begin
                                TempCat.Insert();
                                // Message('Category Inserted : %1 Dans société : %2', recCategory.Code, recCompany.Name);

                            end;
                        end

                    UNTIL recCompany.Next() = 0;
                end;


            end
        end;


    end;
}