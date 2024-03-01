report 50208 "Batch Update Item Class"
{
    UsageCategory = ReportsAndAnalysis;
    ApplicationArea = All;
    Caption = 'Mise à jour des classes articles';
    Permissions = tabledata Item = rimd;  // Permission pour l'utilsateur de lire / ecrire / modofier / inserer dans une table 'Artcle' dans ce cas
    ProcessingOnly = true;  // Pour dire que just c'est un traitement en arrière plan

    dataset
    {
        dataitem(Item; Item)
        {
            trigger OnPreDataItem()
            begin

            end;

            trigger OnPostDataItem()
            var

            begin

            end;

            trigger OnAfterGetRecord()
            var
                RecItemClass: Record "Item Class Setup";

                recItem: Record Item;
                recCustomer: Record Customer;
                recProfitAdd: Record "Customer Additional Profit";
                recSalesPrice: Record "Sales Price";
                recCategory: Record "Item Category";

            begin
                // Mise à jour classe article
                RecItemClass.SetRange(RecItemClass."Manufacturer Code", "Manufacturer Code");
                RecItemClass.SetRange(RecItemClass."Item Product Code", "Item Product Code");
                if RecItemClass.FindFirst() then begin
                    "Item Class" := RecItemClass."Item Class";
                    Modify();
                end;


                recCategory.SetRange(Code, "Item Sub Product Code");
                if recCategory.FindFirst() then begin
                    "Item Product Code" := recCategory."Parent Category";
                    Modify();
                end;


            end;

        }
    }



    trigger OnInitReport()
    begin

    end;

    trigger OnPostReport()
    begin
        Message('Traitement terminé avec succès !');
    end;

    trigger OnPreReport()
    begin

    end;

    var
        myInt: Integer;
}