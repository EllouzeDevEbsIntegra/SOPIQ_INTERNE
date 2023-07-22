table 70014 "Vehicle parts"
{
    DataClassification = ToBeClassified;

    fields
    {
        field(50024; no; Integer)
        {
            DataClassification = ToBeClassified;

            AutoIncrement = true;

        }
        field(50025; vsn; code[20])
        {
            TableRelation = "vehicle"."Serial No.";


            trigger OnValidate()
            var
                vehicle: record "vehicle";

            begin
                vehicle.Reset();
                vehicle.SetRange("Serial No.", vsn);

                if vehicle.FindFirst() then begin
                    repeat
                        vin := vehicle.VIN;
                        vehicle.Modify();
                    until vehicle.Next() = 0;
                end

            end;
        }


        field(50026; vin; code[20])
        {
            DataClassification = ToBeClassified;
            Editable = false;
        }

        field(50027; subgroup; code[50])
        {
            DataClassification = ToBeClassified;
            TableRelation = "Item Category".Code where(Indentation = filter(2));


            trigger OnValidate()
            var
                categorie: record "Item Category";

            begin
                categorie.Reset();
                categorie.SetRange(code, subgroup);
                if categorie.FindFirst() then begin
                    repeat
                        "subgroup Description" := categorie.Description;
                        categorie.Modify();
                    until categorie.Next() = 0;
                end

            end;
        }

        field(50030; "subgroup Description"; Text[200])
        {
            DataClassification = ToBeClassified;
            Editable = false;
        }

        field(50028; itemNo; code[50])
        {
            DataClassification = ToBeClassified;
            TableRelation = Item."No." WHERE("Item Sub Product Code" = field(subgroup));
        }

        field(50029; Qty; Decimal)
        {
            DataClassification = ToBeClassified;
        }
    }

    keys
    {
        // key(Key1; No)
        // {
        //     Clustered = true;
        // }
        // key(Key2; VSN, subgroup)
        // {
        // }


    }

    var
        myInt: Integer;

    trigger OnInsert()
    begin

    end;

    trigger OnModify()
    begin

    end;

    trigger OnDelete()
    begin

    end;

    trigger OnRename()
    begin

    end;

}