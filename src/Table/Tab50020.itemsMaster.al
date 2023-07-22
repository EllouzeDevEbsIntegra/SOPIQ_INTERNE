table 50020 "items Master"
{
    DataClassification = ToBeClassified;
    DataPerCompany = false;

    fields
    {
        field(1; No; Code[20])
        {
            DataClassification = ToBeClassified;
            TableRelation = Item."No.";

        }
        field(2; Famille; Code[20])
        {
            DataClassification = ToBeClassified;
            TableRelation = "Item Category".Code;
        }

        field(20; Company; Code[20])
        {
            DataClassification = ToBeClassified;
            TableRelation = Company.Name;
        }

        field(21; Verified; Boolean)
        {
            DataClassification = ToBeClassified;
            InitValue = false;
        }


    }

    keys
    {
        key(Key1; No)
        {
            Clustered = true;
        }
    }

    var
        myInt: Integer;


    trigger OnInsert()
    begin
        Message(Database.CompanyName);


    end;

    trigger OnModify()
    var
        recItem, tempItem : Record Item;
        recCompany: Record Company;
        tempNo, tempFamille : Code[20];

    begin

        recCompany.Reset();
        if recCompany.FindSet() then begin
            REPEAT

                recItem.Reset();
                recItem.SetRange("No.", rec.No);
                recItem.ChangeCompany(recCompany.Name);
                if recItem.FindFirst() then begin
                    Message('Modification' + recItem."No." + ' - ' + rec.Famille + Database.CompanyName);
                    recItem."Item Product Code" := rec.Famille;
                    recItem.Modify();

                end else begin
                    tempItem.Reset();
                    tempItem."No." := rec.No;
                    tempItem."Item Sub Product Code" := rec.Famille;
                    tempItem.Type := tempItem.Type::Inventory;
                    tempItem.Insert();
                    Message('Insertion %1 - %2 - %3', tempItem."No.", tempItem."Item Sub Product Code", tempItem.Type);
                end;


            UNTIL recCompany.Next() = 0;
        end;

        rec.Verified := true;


    end;

    trigger OnDelete()
    begin



    end;

    trigger OnRename()
    begin

    end;

}