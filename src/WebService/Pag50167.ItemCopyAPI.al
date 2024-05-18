page 50167 "ItemCopyAPI"
{
    PageType = API;
    Caption = 'Item Copy API';
    APIPublisher = 'sopiq';
    APIGroup = 'interne';
    APIVersion = 'v1.0';
    EntityName = 'ItemCopy';
    EntitySetName = 'ItemCopy';
    SourceTable = Item;
    DelayedInsert = true;

    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                field(ref; "No.")
                {
                    Caption = 'Référence SOPIQ';
                }

                field(frs; "Vendor No.")
                {
                    Caption = 'Code Fournisseur';
                }
                field(refTecdoc; "Vendor Item No.")
                {
                    Caption = 'Référence Tecdoc';
                }

                field(refMaster; "Reference Origine Lié")
                {
                    Caption = 'Reference Origine Lié';
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
        fabricant: Text[100];
        // Item By Vendor & Item Cross Reference
        ItemVendor: Record "Item Vendor";
        Vendor: Record Vendor;
        ItemCrossReference: Record "Item Cross Reference";
    begin
        if "No." = '' then
            Error(NotProvidedCustomerNameErr);

        recFabricant.Reset();
        If recFabricant.get(rec."Fabricant WS") then fabricant := recFabricant.Name;
        //Add item unit
        recItemUnit.Init();
        recItemUnit.SetRange("Item No.", rec."No.");
        if not recItemUnit.FindFirst() then begin
            recItemUnit."Item No." := rec."No.";
            recItemUnit.code := 'PCS';
            recItemUnit."Qty. per Unit of Measure" := 1;
            recItemUnit.Insert;
        end;

        rec."Base Unit of Measure" := 'PCS';
        rec."Sales Unit of Measure" := 'PCS';
        rec."Purch. Unit of Measure" := 'PCS';
        rec."Item Type" := "Item Type"::Item;
        rec.Produit := false;
        rec."Search Description2" := rec."No." + ' - ' + rec."Description structurée" + ' - ' + fabricant;
        rec."Gen. Prod. Posting Group" := 'MARCH_19';
        rec."VAT Prod. Posting Group" := 'TVA_19';
        rec."Inventory Posting Group" := 'MARCHANDISES';
        rec."Item Class" := "Item Class"::Adaptable;
        rec.Reserve := Reserve::Always;
        rec."Price/Profit Calculation" := "Price/Profit Calculation"::"No Relationship";
        rec."VAT Bus. Posting Gr. (Price)" := 'LOCAL';
        rec."Profit %" := 20;

        rec."Manufacturer Code" := rec."Fabricant WS";


        // Add item vendor & item cross ref 
        ItemVendor.Init();
        ItemVendor."Item No." := Rec."No.";
        ItemVendor."Vendor No." := "Vendor No.";
        Vendor.get("Vendor No.");
        ItemVendor."Lead Time Calculation" := Vendor."Lead Time Calculation"; //
        ItemVendor."Vendor Item No." := "Vendor Item No.";
        ItemVendor.Insert();


        ItemCrossReference.Init();
        ItemCrossReference."Item No." := rec."No.";
        ItemCrossReference."Cross-Reference Type" := ItemCrossReference."Cross-Reference Type"::Vendor;
        ItemCrossReference."Cross-Reference Type No." := "Vendor No.";
        ItemCrossReference."Cross-Reference No." := "Vendor Item No.";
        ItemCrossReference."Unit of Measure" := rec."Purch. Unit of Measure";
        ItemCrossReference.Insert();


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