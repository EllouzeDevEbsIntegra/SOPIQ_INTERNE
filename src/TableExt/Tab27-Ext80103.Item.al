tableextension 80103 "Item" extends Item //27
{
    fields
    {
        field(80103; "Sales Qty 'Year'"; Decimal)
        {
            CalcFormula = - Sum("Value Entry"."Invoiced Quantity" WHERE("Item Ledger Entry Type" = CONST(Sale),
                                                                        "Item No." = FIELD("No."),
                                                                        "Global Dimension 1 Code" = FIELD("Global Dimension 1 Filter"),
                                                                        "Global Dimension 2 Code" = FIELD("Global Dimension 2 Filter"),
                                                                        "Location Code" = FIELD("Location Filter"),
                                                                        "Drop Shipment" = FIELD("Drop Shipment Filter"),
                                                                        "Variant Code" = FIELD("Variant Filter"),
                                                                        "Posting Date" = FIELD("Date filter 'Year'")));
            Caption = 'Sales (Qty.)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }

        field(80104; "Sales Qty 'Year-1'"; Decimal)
        {
            CalcFormula = - Sum("Value Entry"."Invoiced Quantity" WHERE("Item Ledger Entry Type" = CONST(Sale),
                                                                        "Item No." = FIELD("No."),
                                                                        "Global Dimension 1 Code" = FIELD("Global Dimension 1 Filter"),
                                                                        "Global Dimension 2 Code" = FIELD("Global Dimension 2 Filter"),
                                                                        "Location Code" = FIELD("Location Filter"),
                                                                        "Drop Shipment" = FIELD("Drop Shipment Filter"),
                                                                        "Variant Code" = FIELD("Variant Filter"),
                                                                        "Posting Date" = FIELD("Date filter 'Year-1'")));
            Caption = 'Sales (Qty.)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }

        field(80105; "Date filter 'Year'"; Date)
        {

        }
        field(80106; "Date filter 'Year-1'"; Date)
        {

        }

        field(80107; "Mg Principal Filter"; code[20])
        {

        }

        modify(Reserve)
        {
            trigger OnBeforeValidate()
            var
                salesRecSetup: record "Sales & Receivables Setup";
            begin

                salesRecSetup.Reset();
                if salesRecSetup.FindFirst() then begin
                    if (salesRecSetup."Reservation Mandatory") then begin
                        If (Type = Type::Inventory) then Reserve := Reserve::Always;
                    end;

                end;

            end;


        }

        modify("Vendor Item No.")
        {
            trigger OnAfterValidate()
            begin
                "Vendor Item No." := "Vendor Item No.".Replace(' ', '');
            end;
        }

        field(50103; "PurshQty20"; integer)
        {
            CalcFormula = sum("Item old transaction"."Purshase Qty" where("Item N°" = field("No."), Year = const('2020')));
            Editable = false;
            FieldClass = FlowField;
        }

        field(50104; "PurshQty21"; integer)
        {
            CalcFormula = sum("Item old transaction"."Purshase Qty" where("Item N°" = field("No."), Year = const('2021')));
            Editable = false;
            FieldClass = FlowField;
        }

        field(50105; "SalesQty20"; integer)
        {
            CalcFormula = sum("Item old transaction"."Sales Qty" where("Item N°" = field("No."), Year = const('2020')));
            Editable = false;
            FieldClass = FlowField;
        }

        field(50106; "SalesQty21"; integer)
        {
            CalcFormula = sum("Item old transaction"."Sales Qty" where("Item N°" = field("No."), Year = const('2021')));
            Editable = false;
            FieldClass = FlowField;
        }


        field(50119; "ImportQty"; Decimal)
        {
            CalcFormula = sum("Item Ledger Entry".Quantity where("Item No." = field("No."), "Location Code" = filter('IMPORT')));
            Editable = false;
            FieldClass = FlowField;
            DecimalPlaces = 0 : 5;
        }

        field(50120; "StockQty"; Decimal)
        {
            CalcFormula = sum("Item Ledger Entry".Quantity where("Item No." = field("No."), "Location Code" = filter('<>IMPORT&<>LITIGE')));
            Editable = false;
            FieldClass = FlowField;
            DecimalPlaces = 0 : 5;
        }

        field(50220; "StockMagPrincipal"; Decimal)
        {
            CalcFormula = sum("Item Ledger Entry".Quantity where("Item No." = field("No."), "Location Code" = field("Mg Principal Filter")));
            Editable = false;
            FieldClass = FlowField;
            DecimalPlaces = 0 : 5;
        }




        field(50111; "Last Date"; Date)
        {
            CalcFormula = max("purchase price"."Starting Date" where("Item No." = field("No."), "Ending Date" = filter(0D)));
            Editable = false;
            FieldClass = FlowField;
        }

        field(50171; "Last Ending Date"; Date)
        {
            CalcFormula = max("purchase price"."Ending Date" where("Item No." = field("No.")));
            Editable = false;
            FieldClass = FlowField;
        }

        field(50172; "Last starting Date"; Date)
        {
            CalcFormula = max("purchase price"."Starting Date" where("Item No." = field("No.")));
            Editable = false;
            FieldClass = FlowField;
        }

        field(50107; "Last Curr. Price."; Decimal)
        {
            CalcFormula = lookup("purchase price"."Direct Unit Cost" where("Item No." = field("No."), "Ending Date" = filter(0D), "Starting Date" = field("Last Date")));
            Editable = false;
            FieldClass = FlowField;
            DecimalPlaces = 2 : 2;
        }

        field(50170; "Pre Last Curr. Price."; Decimal)
        {
            CalcFormula = lookup("purchase price"."Direct Unit Cost" where("Item No." = field("No."), "Ending Date" = field("Last Ending Date")));
            Editable = false;
            FieldClass = FlowField;
            DecimalPlaces = 2 : 2;
        }

        field(50108; "Last. Pursh. cost DS"; Decimal)
        {
            DataClassification = ToBeClassified;
            // CalcFormula = sum("purchase price"."Direct Unit Cost" where("Item No." = field("No."), "Ending Date" = filter(' ')));
            Editable = false;
            // FieldClass = FlowField;
            DecimalPlaces = 3 : 3;
        }

        field(50109; "Last. Pursh. Date"; Date)
        {
            DataClassification = ToBeClassified;
        }

        field(50110; "Last. Preferential"; Boolean)
        {
            DataClassification = ToBeClassified;
        }

        field(50112; "First Reception Date"; Date)
        {
            Caption = 'Date récep la plus proche';
            CalcFormula = Min("Purchase Line"."Expected Receipt Date" where("No." = field("No."), "Outstanding Quantity" = Filter('> 0'), "Document Type" = filter(Order)));
            Editable = false;
            FieldClass = FlowField;
        }

        field(50113; "Count Content"; Integer)
        {
            Caption = 'Nombre d''emplacement';

            FieldClass = FlowField;
            CalcFormula = count("Bin Content" where("Quantity" = filter(> 0), "Item No." = field("No.")));
        }

        field(50114; "Fabricant Is Actif"; Boolean)
        {
            Caption = 'Fabricant est Actif';
            CalcFormula = lookup(Manufacturer.Actif where(Code = field("Manufacturer Code")));
            FieldClass = FlowField;
        }


        field(50130; "NbJourRupture"; Decimal)
        {
            CalcFormula = sum("Specific Item Ledger Entry".Quantity where("Item No." = field("No."), "Entry Type" = filter(10)));
            Editable = false;
            FieldClass = FlowField;
            DecimalPlaces = 0 : 0;
        }
        field(50131; "Fabricant WS"; Code[50])
        {
            DataClassification = ToBeClassified;
        }


        field(50132; "LastPurchPricePrincipalVendor"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'Prix Revendeur';
        }


    }

    trigger OnAfterDelete()
    var
        recItemMaster: Record "items Master";
    begin
        recItemMaster.Reset();
        recItemMaster.SetRange(No, "No.");
        recItemMaster.SetRange(Company, Database.CompanyName);
        recItemMaster.SetRange(Verified, false);
        if recItemMaster.FindSet() then begin
            repeat
                recItemMaster.Delete();
            until recItemMaster.Next() = 0;
        end;
    end;

    trigger OnAfterModify()
    var
        recItemMaster, recMasterExist : Record "items Master";
        TypeModif: Text[200];
    begin
        if (rec.Verified = false) then begin
            // Message('Not verified Item');
            if (rec.Description <> '') then BEGIN
                recMasterExist.Reset();
                recMasterExist.SetRange(Company, Database.CompanyName);
                recMasterExist.SetRange(Verified, false);
                recMasterExist.SetRange("No", "No.");
                if recMasterExist.FindFirst() then begin
                    // Message('test id : %1', recMasterExist.id);
                    if (rec.Description <> xRec.Description)
                        OR (rec."Item Product Code" <> xRec."Item Product Code")
                        OR (rec."Item Sub Product Code" <> xRec."Item Sub Product Code")
                        OR (rec."Champs libre" <> xRec."Champs libre")
                        OR (rec.Produit <> xRec.Produit)
                        OR (rec."Reference Origine Lié" <> xRec."Reference Origine Lié")
                        OR (rec."Manufacturer Code" <> xRec."Manufacturer Code")
                        OR (rec."Make Code" <> xRec."Make Code")
                    THEN BEGIN
                        // Message('article dispo et Il y une modification  dans item !');
                        if (rec."Reference Origine Lié" <> '') THEN
                            recMasterExist.Master := rec."Reference Origine Lié";
                        if (rec.Groupe <> '') THEN
                            recMasterExist.Famille := rec.Groupe;
                        if (rec."Sous Groupe" <> '') THEN
                            recMasterExist."Sous Famille" := rec."Sous Groupe";
                        recMasterExist."Type Ajout" := 'Nouveau';
                        recMasterExist.modify(true);
                        Message(recMasterExist."Type Ajout");
                    END
                end
                else begin
                    // Message('Non Dispo');
                    if (rec.Description <> xRec.Description)
                        OR (rec."Item Product Code" <> xRec."Item Product Code")
                        OR (rec."Item Sub Product Code" <> xRec."Item Sub Product Code")
                        OR (rec."Champs libre" <> xRec."Champs libre")
                        OR (rec.Produit <> xRec.Produit)
                        OR (rec."Reference Origine Lié" <> xRec."Reference Origine Lié")
                        OR (rec."Manufacturer Code" <> xRec."Manufacturer Code")
                        OR (rec."Make Code" <> xRec."Make Code")
                    THEN BEGIN
                        // Message('Article Non Dispo et il y une modification dans item !');
                        recItemMaster.Reset();
                        recItemMaster.Company := Database.CompanyName;
                        recItemMaster.No := rec."No.";
                        if (rec."Reference Origine Lié" <> '') THEN
                            recItemMaster.Master := rec."Reference Origine Lié";
                        if (rec.Groupe <> '') THEN
                            recItemMaster.Famille := rec.Groupe;
                        if (rec."Sous Groupe" <> '') THEN
                            recItemMaster."Sous Famille" := rec."Sous Groupe";
                        recItemMaster."Add date" := System.today;
                        recItemMaster."Add User" := Database.UserId;
                        recItemMaster."Type Ajout" := 'Nouveau';
                        recItemMaster.Insert(true);
                        Message(recMasterExist."Type Ajout");
                    END
                end;
            END;
        end
        else begin

            // Message('Vérified - Modification sur un article');
            // Message('verified Item');
            if (xRec."No." <> '') then begin
                TypeModif := 'Champs Modifiés : ';
                if (rec.Description <> xRec.Description) then TypeModif := TypeModif + '- Description';
                if (rec."Item Product Code" <> xRec."Item Product Code") then TypeModif := TypeModif + '- Famille';
                if (rec."Item Sub Product Code" <> xRec."Item Sub Product Code") then TypeModif := TypeModif + '- Sous Famille';
                if (rec."Champs libre" <> xRec."Champs libre") then TypeModif := TypeModif + '- Champ libre';
                if (rec.Produit <> xRec.Produit) then TypeModif := TypeModif + '- Est Produit';
                if (rec."Reference Origine Lié" <> xRec."Reference Origine Lié") then TypeModif := TypeModif + '- Ref Master';
                if (rec."Manufacturer Code" <> xRec."Manufacturer Code") then TypeModif := TypeModif + '- Fabricant';
                if (rec."Make Code" <> xRec."Make Code") then TypeModif := TypeModif + '- Marque';
                //Message(TypeModif);

                if (rec.Description <> xRec.Description)
                    OR (rec."Item Product Code" <> xRec."Item Product Code")
                    OR (rec."Item Sub Product Code" <> xRec."Item Sub Product Code")
                    OR (rec."Champs libre" <> xRec."Champs libre")
                    OR (rec.Produit <> xRec.Produit)
                    OR (rec."Reference Origine Lié" <> xRec."Reference Origine Lié")
                    OR (rec."Manufacturer Code" <> xRec."Manufacturer Code")
                    OR (rec."Make Code" <> xRec."Make Code")
                THEN BEGIN
                    recItemMaster.Reset();
                    recItemMaster.Company := Database.CompanyName;
                    recItemMaster.No := rec."No.";
                    if (rec."Reference Origine Lié" <> '') THEN
                        recItemMaster.Master := rec."Reference Origine Lié";
                    if (rec.Groupe <> '') THEN
                        recItemMaster.Famille := rec.Groupe;
                    if (rec."Sous Groupe" <> '') THEN
                        recItemMaster."Sous Famille" := rec."Sous Groupe";
                    recItemMaster."Add date" := System.today;
                    recItemMaster."Add User" := Database.UserId;
                    recItemMaster."Type Ajout" := TypeModif;
                    recItemMaster.Insert(true);
                END
            end;



        end;

    end;
}