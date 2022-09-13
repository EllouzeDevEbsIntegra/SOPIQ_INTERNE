report 70060 "Batch Update Item Class"
{
    UsageCategory = ReportsAndAnalysis;
    ApplicationArea = All;
    Caption = 'Mise à jour des classes articles';
    Permissions = tabledata Item = rimd; // Permission pour l'utilsateur de lire / ecrire / modofier / inserer dans une table 'Artcle' dans ce cas
    ProcessingOnly = true;  // Pour dire que just c'est un traitement en arrière plan

    dataset
    {
        dataitem(Item; Item)
        {
            trigger OnPreDataItem()
            begin

            end;

            trigger OnPostDataItem()
            begin

            end;

            trigger OnAfterGetRecord()
            var
                RecItemClass: Record "Item Class Setup";
            begin
                RecItemClass.SetRange(RecItemClass."Manufacturer Code", "Manufacturer Code");
                RecItemClass.SetRange(RecItemClass."Item Product Code", "Item Product Code");
                if RecItemClass.FindFirst() then begin

                end;
                "Item Class" := RecItemClass."Item Class";
                Modify();
            end;

        }
    }



    trigger OnInitReport()
    begin

    end;

    trigger OnPostReport()
    begin

    end;

    trigger OnPreReport()
    begin

    end;

    var
        myInt: Integer;
}