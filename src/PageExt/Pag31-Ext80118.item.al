
pageextension 80118 "item" extends "Item List" //31
{
    layout
    {
        addafter("No.")
        {
            field("No. 2"; "No. 2")
            {
                ApplicationArea = all;
                Caption = 'Réf. Imp.';
            }
        }
        addafter(InventoryField)
        {
            field("ImportQty"; ImportQty)
            {
                Caption = 'Qté Import';
                ApplicationArea = All;
            }
            field("Available Inventory"; "Available Inventory")
            {
                Caption = 'Qté Disponible';
                ApplicationArea = All;
            }
            field("Default Bin"; "Default Bin")
            {
                Caption = 'Emplacement par défaut';
                ApplicationArea = All;
            }
            field("Count Item Manual "; "Count Item Manual ")
            {
                Caption = 'Occurrence';
                ApplicationArea = All;
            }
            field("Small Parts"; "Small Parts")
            {
                Caption = 'Petite Fourniture';
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

            field("Last. Pursh. Date"; "Last. Pursh. Date")
            {
                Caption = 'Date Dernier Achat';
                ApplicationArea = all;
            }
            field("LastPurchPricePrincipalVendor"; "LastPurchPricePrincipalVendor")
            {

            }
            field("Total Vendu"; "Total Vendu")
            {
                Caption = 'Total Vente';
                ApplicationArea = all;
            }
            field("Last Purch Price Devise"; "Last Purch Price Devise")
            {
                Caption = 'Dernier Prix Achat (Devise)';
                ApplicationArea = all;
            }

            // field(etatStkFrsBase; etatStkFrsBase)
            // {
            //     StyleExpr = FieldEtatStyle;
            //     CaptionClass = '3,' + 'Etat Stock (' + Parvente."Société base analyseur prix" + ' )';

            // }

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

            action("Purchase Vendor price Compare")
            {
                ApplicationArea = All;
                Caption = 'Comparateur Prix Fournisseur';
                RunObject = page "PurchaseItemCompare";
                Image = CompareCost;
            }

            // Test de consommer un API configurer déja dans code unit API
            action("Test API")
            {
                trigger OnAction()
                var
                    API: Codeunit API;
                    jObject: JsonObject;
                    jtitleToken: JsonToken;
                begin
                    jObject.ReadFrom(API.GetRequest());
                    if jObject.Get('title', jtitleToken) then Message(jtitleToken.AsValue().AsText());
                end;
            }

            action("Rechercher dans TecDoc")
            {
                ApplicationArea = All;
                Caption = 'Recherche TecDoc';
                Image = AboutNav;
                trigger OnAction()
                var
                    TecDocAPI: Codeunit "TecDoc Connector";
                    Mrfid: Text; // Variable locale pour récupérer le mrfid calculé dans la procédure ValiderReference
                begin
                    TecDocAPI.RechercherArticleTecdoc(Rec."No.", Mrfid);
                end;
            }


        }

    }

    var
        filterDate: text;
        recItem: Record Item;
        Parvente: Record "Sales & Receivables Setup";
        FieldEtatStyle: Text[50];
        Location: Record Location;



    trigger OnAfterGetRecord()
    var
        entredOnce: Boolean;
        textFiltreExclureStock: Text;
        textFilterMagasinImport: Text;
        StartingDate: Date;
    begin
        // recInventorySetup.Reset();
        // if recInventorySetup.FindFirst() then begin
        //     "Mg Principal Filter" := recInventorySetup."Magasin Central";
        // end;
        rec.setMgPrincipalFilter(rec);

        CalcFields(rec."Available Inventory", rec."Default Bin", rec."Total Vendu", rec."Last Purch Price Devise");






        // recItem.ChangeCompany(Parvente."Société base analyseur prix");
        // IF recItem.GET("No.") then begin
        //     recItem.CalcFields(StockQty, ImportQty);
        //     if (recItem.StockQty > 0) then rec.etatStkFrsBase := etatStkFrsBase::"En Stock";
        //     if (recItem.StockQty = 0) AND (recItem.ImportQty = 0) then rec.etatStkFrsBase := etatStkFrsBase::Rupture;
        //     if (recItem.StockQty = 0) AND (recItem.ImportQty > 0) then rec.etatStkFrsBase := etatStkFrsBase::"En arrivage";
        //     // rec.Modify();
        // end;
        // SetEtatStyle();
    end;

    trigger OnOpenPage()

    begin
        Parvente.get;
        if Parvente."Activer analyseur de prix" then begin
            Parvente.TestField("Société base analyseur prix");
        end;

    end;

    // procedure SetEtatStyle()
    // begin
    //     IF etatStkFrsBase = etatStkFrsBase::Rupture THEN begin
    //         FieldEtatStyle := 'Attention';
    //     end else begin
    //         if etatStkFrsBase = etatStkFrsBase::"En arrivage" THEN begin
    //             FieldEtatStyle := 'StandardAccent';
    //         end else begin
    //             FieldEtatStyle := 'Favorable';
    //         end;

    //     end;
    // end;



}
