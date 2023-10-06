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
        field(2; Famille; Code[200])
        {
            DataClassification = ToBeClassified;
            TableRelation = "Item Category".Code;
        }

        field(3; "Sous Famille"; Code[200])
        {
            DataClassification = ToBeClassified;
            TableRelation = "Item Category".Code;
        }

        field(4; "Master"; Code[50])
        {
            DataClassification = ToBeClassified;
            TableRelation = "Item"."No.";
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
        key(Key1; No, Company)
        {
            Clustered = true;
        }
    }

    var
        myInt: Integer;


    // trigger OnModify()
    // var
    //     recItem, tempItem : Record Item;
    //     recCompany: Record Company;
    //     tempNo, tempFamille : Code[20];

    // begin

    //     recCompany.Reset();
    //     if recCompany.FindSet() then begin
    //         REPEAT

    //             recItem.Reset();
    //             recItem.SetRange("No.", rec.No);
    //             recItem.ChangeCompany(recCompany.Name);
    //             if recItem.FindFirst() then begin
    //                 tempItem := recItem;
    //                 Message('Modification' + recItem."No." + ' - ' + rec.Famille + Database.CompanyName);
    //                 recItem."Item Product Code" := rec.Famille;
    //                 recItem.Modify();

    //             end else begin
    //                 recItem.Reset();
    //                 recItem."No." := rec.No;
    //                 recItem."Item Product Code" := rec.Famille;
    //                 recItem.Type := recItem.Type::Inventory;
    //                 recItem."Item Type" := recItem."Item Type"::Item;
    //                 recItem.Insert();
    //                 Message('Insertion %1 - %2 - %3 - %4', recItem."No.", recItem."Item Sub Product Code", recItem.Type, Database.CompanyName);
    //             end;


    //         UNTIL recCompany.Next() = 0;
    //     end;

    //     rec.Verified := true;


    // end;

    trigger OnDelete()
    begin



    end;

    trigger OnRename()
    begin

    end;

}