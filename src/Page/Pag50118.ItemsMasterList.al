page 50118 "Items Master List"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "items Master";
    SourceTableView = where(Verified = filter(false));
    Editable = false;
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;

    Permissions = tabledata "Item Unit of Measure" = RIMD;

    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                field(No; No)
                {
                    ApplicationArea = All;
                }

                field(Famille; Famille)
                {
                    ApplicationArea = All;

                }

                field("Sous Famille"; "Sous Famille")
                {
                    ApplicationArea = All;

                }

                field("Master"; Master)
                {
                    ApplicationArea = All;

                }

                field(Company; Company)
                {
                    ApplicationArea = All;

                }

                field("Add date"; "Add date")
                {
                    ApplicationArea = All;
                    Caption = 'Date Ajout';
                }

                field("Add User"; "Add User")
                {
                    ApplicationArea = All;
                    Caption = 'Ajouté par';
                }
                field("Type Ajout"; "Type Ajout")
                {
                    ApplicationArea = All;
                    Caption = 'Type d''ajout';
                }
            }
        }
        area(Factboxes)
        {

        }
    }

    actions
    {
        area(Processing)
        {
            action("Modify Item Information")
            {
                ApplicationArea = All;
                Caption = 'Modifier Informations Article';
                Image = Edit;

                trigger OnAction();
                var
                    recItem: Record Item;
                    itemCard: Page "Item Card";
                begin
                    recItem.Reset();
                    recItem.SetRange("No.", rec.No);
                    recItem.ChangeCompany(rec.Company);
                    Commit();
                    PAGE.RUNMODAL(PAGE::"Item Card", recItem);



                end;
            }

            action("Validate Item")
            {
                ApplicationArea = All;
                Caption = 'Valider Article';
                Image = ApprovalSetup;

                trigger OnAction();
                var
                    recItem, recItem2, tempItem, unitItem : Record Item;
                    recCompany: Record Company;
                    recItemMaster: Record "items Master";
                    tempUnit: Code[10];
                    UnitOfMeasure: Record "Unit of Measure";
                    UnitOfMeasureNotExistErr: Label 'The Unit of Measure with Code %1 does not exist.', Comment = '%1 = Code of Unit of measure';
                    ItemUnitOfMeasure: Record "Item Unit of Measure";
                    BaseUnitOfMeasureQtyMustBeOneErr: Label 'The quantity per base unit of measure must be 1. %1 is set up with %2 per unit of measure.\\You can change this setup in the Item Units of Measure window.', Comment = '%1 Name of Unit of measure (e.g. BOX, PCS, KG...), %2 Qty. of %1 per base unit of measure ';

                begin
                    tempItem.Reset();
                    recItem.Reset();
                    recItem.SetRange("No.", rec.No);
                    recItem.ChangeCompany(rec.Company);
                    if recItem.FindFirst() then begin
                        recItem.Verified := true;
                        recItem.Modify();
                        tempItem := recItem;
                        // Message('Article Temporaire : %1 --- Article : %2', tempItem."No.", recItem."No.");
                    end;

                    recCompany.Reset();
                    if recCompany.FindSet() then begin
                        REPEAT
                            // Message('Parcours de la société : %1', recCompany.Name);
                            IF recCompany.Name <> rec.Company THEN BEGIN
                                tempItem.ChangeCompany(recCompany.Name);
                                // Message('Société : %1 -- Item Temp : %2', recCompany.Name, tempItem."No.");
                                recItem.Reset();
                                recItem.SetFilter("No.", tempItem."No.");
                                recItem.ChangeCompany(recCompany.Name);
                                if recItem.FindFirst() then begin

                                    recItem.validate(Description, tempItem.Description);
                                    recItem.validate("Item Product Code", tempItem."Item Product Code");
                                    recItem.validate("Item Sub Product Code", tempItem."Item Sub Product Code");
                                    recItem.validate("Champs libre", tempItem."Champs libre");
                                    recItem.validate(recItem.Produit, tempItem.Produit);
                                    recItem.validate("Reference Origine Lié", tempItem."Reference Origine Lié");
                                    recItem.validate("Manufacturer Code", tempItem."Manufacturer Code");
                                    recItem.validate("Make Code", tempItem."Make Code");
                                    recItem.Modify;

                                    // Message('Item Modified : %1 Dans société : %2', recItem."No.", recCompany.Name);
                                end
                                else begin
                                    tempItem.Insert;
                                end;

                                unitItem.Reset();
                                unitItem.ChangeCompany(recCompany.Name);
                                unitItem.SetRange("No.", tempItem."No.");
                                if unitItem.FindFirst() then begin

                                    unitItem."Base Unit of Measure" := tempItem."Base Unit of Measure";
                                    unitItem.Modify();
                                    unitItem.UpdateUnitOfMeasureId;

                                    if unitItem."Base Unit of Measure" <> '' then begin
                                        UnitOfMeasure.ChangeCompany(recCompany.Name);
                                        if not UnitOfMeasure.Get(unitItem."Base Unit of Measure") then begin
                                            UnitOfMeasure.SetRange("International Standard Code", unitItem."Base Unit of Measure");
                                            if not UnitOfMeasure.FindFirst then
                                                Error(UnitOfMeasureNotExistErr, unitItem."Base Unit of Measure");
                                            unitItem."Base Unit of Measure" := UnitOfMeasure.Code;
                                        end;

                                        ItemUnitOfMeasure.ChangeCompany(recCompany.Name);
                                        if not ItemUnitOfMeasure.Get(unitItem."No.", unitItem."Base Unit of Measure") then begin
                                            ItemUnitOfMeasure.Init();
                                            if IsTemporary then
                                                ItemUnitOfMeasure."Item No." := unitItem."No."
                                            else
                                                ItemUnitOfMeasure.Validate("Item No.", unitItem."No.");
                                            ItemUnitOfMeasure.Validate(Code, unitItem."Base Unit of Measure");
                                            ItemUnitOfMeasure."Qty. per Unit of Measure" := 1;
                                            ItemUnitOfMeasure.Insert();
                                        end else begin
                                            if ItemUnitOfMeasure."Qty. per Unit of Measure" <> 1 then
                                                Error(BaseUnitOfMeasureQtyMustBeOneErr, unitItem."Base Unit of Measure", ItemUnitOfMeasure."Qty. per Unit of Measure");
                                        end;
                                    end;
                                    unitItem."Sales Unit of Measure" := unitItem."Base Unit of Measure";
                                    unitItem."Purch. Unit of Measure" := unitItem."Base Unit of Measure";

                                end;
                            END;
                        UNTIL recCompany.Next() = 0;
                    end;

                    recItemMaster.Reset();
                    recItemMaster.SetRange(No, rec.No);
                    recItemMaster.SetRange(Verified, false);
                    if recItemMaster.FindSet() then begin
                        REPEAT
                            recItemMaster.Verified := true;
                            recItemMaster."Validate date" := System.today;
                            recItemMaster."Validate User" := Database.UserId;
                            recItemMaster.Modify();
                        UNTIL recItemMaster.Next() = 0;
                    end;
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        recItem: Record item;
        recMaster: Record "items Master";
    begin
        // Il faut mettre à jour les inforamtions dans table Master Item From Item
        recItem.Reset();
        recItem.SetRange("No.", rec.No);
        recItem.ChangeCompany(rec.Company);
        IF recItem.FindFirst() THEN BEGIN
            recMaster.Reset();
            recMaster.SetRange(No, recItem."No.");
            recMaster.SetRange(Company, recItem.CurrentCompany);
            IF recMaster.FindSet() then begin
                REPEAT
                    recMaster.Famille := recItem.Groupe;
                    recMaster."Sous Famille" := recItem."Sous Groupe";
                    recMaster.Master := recItem."Reference Origine Lié";
                    recMaster.Modify();
                UNTIL recMaster.Next() = 0;
            END;
        END;

    end;

}