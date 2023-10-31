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
                    recItem, recItem2, tempItem : Record Item;
                    recCompany: Record Company;
                    recItemMaster: Record "items Master";
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

                                    recItem.Description := tempItem.Description;
                                    recItem."Item Product Code" := tempItem."Item Product Code";
                                    recItem."Item Sub Product Code" := tempItem."Item Sub Product Code";
                                    recItem."Champs libre" := tempItem."Champs libre";
                                    recItem.Produit := tempItem.Produit;
                                    recItem."Reference Origine Lié" := tempItem."Reference Origine Lié";
                                    recItem."Manufacturer Code" := tempItem."Manufacturer Code";
                                    recItem."Make Code" := tempItem."Make Code";
                                    recItem.Modify;
                                    // Message('Item Modified : %1 Dans société : %2', recItem."No.", recCompany.Name);
                                end
                                else begin
                                    tempItem.Insert;
                                    // tempItem.Insert(true);
                                    // tempItem.Validate("No.");
                                    // tempitem.Validate("Base Unit of Measure");
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