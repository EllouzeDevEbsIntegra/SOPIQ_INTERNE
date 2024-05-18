page 50168 "ItemAPI"
{
    PageType = API;
    Caption = 'Item API';
    APIPublisher = 'sopiq';
    APIGroup = 'interne';
    APIVersion = 'v1.0';
    EntityName = 'Item';
    EntitySetName = 'Item';
    SourceTable = Item;
    DelayedInsert = true;
    // InsertAllowed = true;

    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                field(ref; "No.")
                {
                    Caption = 'Référence Master';

                }
                field(category; "Item Category Code")
                {
                    Caption = 'Category';
                }

                field(group; "Item Product Code")
                {
                    caption = 'Group';
                }
                field(SubGroup; "Item Sub Product Code")
                {
                    Caption = 'Sub Group';
                }

                field(ChampsLibre; "Champs libre")
                {
                    caption = 'Champs Libre';
                }

                field(Manufacturer; "Fabricant WS")
                {
                    Caption = 'Fabricant';
                }


                field(marque; "Make Code")
                {
                    Caption = 'Marque';
                }

            }
        }
    }


    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        item: Record Item;
        recFabricant: Record Manufacturer;
        recItemUnit: Record "Item Unit of Measure";
        fabricant, reference : Text[100];
    begin
        if "No." = '' then
            Error(NotProvidedCustomerNameErr);

        recFabricant.Reset();
        If recFabricant.get(rec."Fabricant WS") then fabricant := recFabricant.Name;


        reference := rec."No.";
        rec."No." := 'MASTER' + rec."No.";



        recItemUnit.Init();
        recItemUnit."Item No." := rec."No.";
        recItemUnit.code := 'PCS';
        recItemUnit."Qty. per Unit of Measure" := 1;
        recItemUnit.Insert;


        rec."Reference Origine Lié" := rec."No.";
        rec."Base Unit of Measure" := 'PCS';
        rec."Sales Unit of Measure" := 'PCS';
        rec."Purch. Unit of Measure" := 'PCS';
        rec."Item Type" := "Item Type"::Item;
        rec.Produit := true;
        rec."Search Description2" := rec."No." + ' - ' + rec."Description structurée" + ' - ' + fabricant;
        rec."Gen. Prod. Posting Group" := 'MARCH_19';
        rec."VAT Prod. Posting Group" := 'TVA_19';
        rec."Inventory Posting Group" := 'MARCHANDISES';
        rec."Vendor No." := '401230';
        rec."Vendor Item No." := reference;
        rec."Item Class" := "Item Class"::Original;
        rec.Reserve := Reserve::Always;
        rec."Price/Profit Calculation" := "Price/Profit Calculation"::"No Relationship";
        rec."VAT Bus. Posting Gr. (Price)" := 'LOCAL';

        rec."Manufacturer Code" := rec."Fabricant WS";

        Item.SetRange("No.", "No.");

        if not Item.IsEmpty then
            Insert;

        Insert(true);

        Modify(true);


        exit(false);




    end;


    var
        NotProvidedCustomerNameErr: Label '"No." must be provided.', Locked = true;

}