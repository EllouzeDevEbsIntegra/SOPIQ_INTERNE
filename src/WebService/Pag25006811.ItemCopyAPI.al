page 25006811 "ItemCopyAPI"
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
        fabricant: Text[100];
        // Item By Vendor & Item Cross Reference
        ItemVendor: Record "Item Vendor";
        Vendor: Record Vendor;
        ItemCrossReference: Record "Item Cross Reference";
    begin
        if "No." = '' then
            Error(NotProvidedCustomerNameErr);

        // ---- Controle d'existence AVANT toute ecriture
        if item.Get(rec."No.") then
            Error(ArticleExisteDejaErr, rec."No.");

        recFabricant.Reset();
        If recFabricant.get(rec."Fabricant WS") then fabricant := recFabricant.Name;

        // ---- Champs d'entete (inchanges, hors unites de mesure)
        rec."Item Type" := "Item Type"::Item;
        rec.Produit := false;
        rec."Search Description2" := CopyStr(rec."No." + ' - ' + rec."Description structurée" + ' - ' + fabricant,
                                            1, MaxStrLen(rec."Search Description2"));
        rec."Gen. Prod. Posting Group" := 'MARCH_19';
        rec."VAT Prod. Posting Group" := 'TVA_19';
        rec."Inventory Posting Group" := 'MARCHANDISES';
        rec."Item Class" := "Item Class"::Adaptable;
        rec.Reserve := Reserve::Always;
        rec."Price/Profit Calculation" := "Price/Profit Calculation"::"No Relationship";
        rec."VAT Bus. Posting Gr. (Price)" := 'LOCAL';
        rec."Profit %" := 20;
        rec."Manufacturer Code" := rec."Fabricant WS";

        // =============== 1) L'ARTICLE D'ABORD ===============
        Insert(true);

        // =============== 2) LES UNITES ENSUITE ==============
        // Validate("Base Unit of Measure") cree automatiquement la ligne
        // Item Unit of Measure : plus besoin de l'inserer a la main.
        Validate("Base Unit of Measure", 'PCS');
        Validate("Sales Unit of Measure", 'PCS');
        Validate("Purch. Unit of Measure", 'PCS');

        rec."Origine Création" := "Origine Création"::Automatically;
        rec.Modify(true);

        // =============== 3) LES TABLES FILLES ===============
        if Vendor.Get(rec."Vendor No.") then begin

            ItemVendor.Reset();
            ItemVendor.SetRange("Item No.", rec."No.");
            ItemVendor.SetRange("Vendor No.", rec."Vendor No.");
            if ItemVendor.IsEmpty() then begin
                ItemVendor.Init();
                ItemVendor.Validate("Item No.", rec."No.");
                ItemVendor.Validate("Vendor No.", rec."Vendor No.");
                ItemVendor.Validate("Variant Code", '');
                ItemVendor.Validate("Vendor Item No.", rec."Vendor Item No.");
                ItemVendor.Validate("Lead Time Calculation", Vendor."Lead Time Calculation");
                ItemVendor.Insert(true);
            end;

            if rec."Vendor Item No." <> '' then begin
                ItemCrossReference.Init();
                ItemCrossReference.Validate("Item No.", rec."No.");
                ItemCrossReference.Validate("Variant Code", '');
                ItemCrossReference.Validate("Unit of Measure", rec."Purch. Unit of Measure");
                ItemCrossReference.Validate("Cross-Reference Type",
                                            ItemCrossReference."Cross-Reference Type"::Vendor);
                ItemCrossReference.Validate("Cross-Reference Type No.", rec."Vendor No.");
                ItemCrossReference.Validate("Cross-Reference No.", rec."Vendor Item No.");
                if ItemCrossReference.Insert(true) then;
            end;
        end;

        exit(false);
    end;

    var
        NotProvidedCustomerNameErr: Label '"No." must be provided.', Locked = true;
        ArticleExisteDejaErr: Label 'L''article %1 existe deja.', Comment = '%1 = No article';
}