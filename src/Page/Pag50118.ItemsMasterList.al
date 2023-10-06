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
                        Message('Article Temporaire : %1 --- Article : %2', tempItem."No.", recItem."No.");
                    end;

                    recCompany.Reset();
                    if recCompany.FindSet() then begin
                        REPEAT
                            Message('Parcours de la société : %1', recCompany.Name);
                            IF recCompany.Name <> rec.Company THEN BEGIN
                                tempItem.ChangeCompany(recCompany.Name);
                                // Message('Société : %1 -- Item Temp : %2', recCompany.Name, tempItem."No.");
                                recItem.Reset();
                                recItem.SetFilter("No.", tempItem."No.");
                                recItem.ChangeCompany(recCompany.Name);
                                if recItem.FindFirst() then begin
                                    recItem := tempItem;
                                    recItem.Modify();
                                    // Message('Item Modified : %1 Dans société : %2', recItem."No.", recCompany.Name);
                                end
                                else begin
                                    tempItem.Insert();
                                end;
                            END;
                        UNTIL recCompany.Next() = 0;
                    end;

                    recItemMaster.Reset();
                    recItemMaster.SetRange(No, rec.No);
                    if recItemMaster.FindSet() then begin
                        REPEAT
                            recItemMaster.Verified := true;
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
        if recItem.FindFirst() THEN BEGIN
            recMaster.Reset();
            recMaster.SetRange(No, recItem."No.");
            recMaster.SetRange(Company, recItem.CurrentCompany);
            if recMaster.FindSet() then begin
                repeat
                    recMaster.Famille := recItem.Groupe;
                    recMaster."Sous Famille" := recItem."Sous Groupe";
                    recMaster.Master := recItem."Reference Origine Lié";
                    recMaster.Modify();

                Until recMaster.Next() = 0;
            end;

        END;

    end;

}