pageextension 80118 "item" extends "Item List" //31
{

    layout
    {
        addafter(InventoryField) // Ajout du champ prix initial dans ligne vente
        {
            field("ImportQty"; ImportQty)
            {
                Caption = 'Qté Import';
                ApplicationArea = All;
            }
            field("StockQty"; StockQty)
            {
                Caption = 'Qté Stock';
                ApplicationArea = All;
            }
        }
    }

    actions
    {


        addafter(SendApprovalRequest)
        {

            action("UPDATE ITEM INFO") // MAJ des quelques champs sur la fiche article dans toute la table article
            {
                ApplicationArea = All;
                Caption = 'Mettre à jour informations article';
                Promoted = true;
                PromotedIsBig = true;
                PromotedCategory = Process;


                trigger OnAction()

                var
                    messageValidate: Label 'Voulez vous exécuter la mise à jour';
                    messageSuccees: Label 'Mise à jour info article terminée avec succées';
                    RecCategory: Record "Item Category";
                    RecManufacturer: Record Manufacturer;
                    RecItem: Record Item;

                begin
                    if Confirm(messageValidate) then begin
                        recItem.reset();

                        if recItem.FindFirst() then begin
                            repeat
                                // MAJ libellé groupe
                                if RecCategory.Get(recItem."Item Product Code") then begin
                                    recItem."Groupe" := RecCategory.Description;
                                    Modify();
                                end;

                                // MAJ libellé sous groupe 
                                if RecCategory.Get(recItem."Item Sub Product Code") then begin
                                    recItem."Sous Groupe" := RecCategory.Description;
                                    Modify();
                                end;

                                // MAJ description structuré
                                if (recItem."Champs libre" <> '') then begin
                                    ;
                                    recItem."Description structurée" := recItem."Sous Groupe" + ' - ' + recItem."Champs libre";
                                    Modify();
                                end;

                                // MAJ nom fabricant
                                if RecManufacturer.Get(recItem."Manufacturer Code") then begin
                                    recItem."Manufacturer Name" := RecManufacturer.Name;
                                    Modify();
                                end;

                                // MAJ du champ description de recherche
                                recItem."Search Description2" := recItem."No." + ' - ' + recItem."Description structurée" + ' - ' + recItem."Manufacturer Name";
                                Modify();

                                recItem.Modify();
                            until recItem.Next() = 0;

                            Message(messageSuccees);
                        end
                    end

                end;

            }
        }
        addafter("UPDATE ITEM INFO")
        {
            action("ITEM OLD TRANSACTION") // MAJ des quelques champs sur la fiche article dans toute la table article
            {
                ApplicationArea = All;
                Caption = 'Historique des articles 2021';
                Promoted = true;
                PromotedIsBig = true;
                PromotedCategory = Process;
                ShortcutKey = F9;
                RunObject = page "Item Transaction 2021";
                RunPageLink = "Item N°" = field("No."), Year = CONST('2021');
            }


        }

    }

    var
        myInt: Integer;
}