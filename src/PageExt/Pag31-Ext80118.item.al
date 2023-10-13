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

        addlast(Control1)
        {
            field("stockMagPrincipal"; StockMagPrincipal)
            {
                Caption = 'Stk Mg Principal';
                ApplicationArea = All;
            }
        }

        addafter("Search Description")
        {
            field("Fabricant is Actif"; "Fabricant Is Actif")
            {
                Caption = 'Fabricant est Actif';
                ApplicationArea = All;
            }
            field("NbJourRupture"; "NbJourRupture")
            {
                Caption = 'Nb Jour Rupture';
                ApplicationArea = All;
            }
            field("LastPurchPricePrincipalVendor"; "LastPurchPricePrincipalVendor")
            {

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
                                    recItem."Description structurée" := recItem."Sous Groupe" + ' - ' + recItem."Champs libre";
                                    Modify();
                                end
                                else begin
                                    recItem."Description structurée" := recItem."Sous Groupe";
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

            action("ITEM TRANSACTION") // MAJ des quelques champs sur la fiche article dans toute la table article
            {
                ApplicationArea = All;
                Caption = 'Historique des articles';
                Promoted = true;
                PromotedIsBig = true;
                PromotedCategory = Process;
                ShortcutKey = F9;
                RunObject = page "Specific Item Ledger Entry";
                RunPageLink = "Item No." = field("No.");

            }

            action("Last Default Vendor Price")
            {
                ApplicationArea = all;
                ShortcutKey = F3;
                trigger OnAction()
                var
                    recInvLine: Record "Purch. Inv. Line";
                    recPurchaseLine: Record "Purchase Line";
                    recSetupPurchase: Record "Purchases & Payables Setup";
                    defaultVendor: code[20];
                    defaultProfit: Decimal;
                begin
                    recSetupPurchase.Reset();
                    if recSetupPurchase.FindFirst() then begin
                        defaultVendor := recSetupPurchase."Default Vendor";
                        defaultProfit := recSetupPurchase."DEFAult Profit %";
                    end;


                    recPurchaseLine.Reset();
                    recPurchaseLine.SetRange("No.", "No.");
                    recPurchaseLine.SetRange("Buy-from Vendor No.", defaultVendor);
                    if recPurchaseLine.FindLast() then begin
                        rec.LastPurchPricePrincipalVendor := recPurchaseLine."Direct Unit Cost";
                        rec.Modify();
                    end
                    else
                        rec.LastPurchPricePrincipalVendor := 0;


                end;
            }


        }

    }

    var
        filterDate: text;
        recInventorySetup: Record "Inventory Setup";

    trigger OnAfterGetRecord()
    var
    begin
        recInventorySetup.Reset();
        if recInventorySetup.FindFirst() then begin

            "Mg Principal Filter" := recInventorySetup."Magasin Central";

        end;

        CalcFields(rec.StockMagPrincipal);
    end;

    trigger OnOpenPage()
    begin

    end;

}