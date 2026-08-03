// =====================================================================
//  SOPIQ INTERNE - Codeunit 50031 "SIStock Data Integrity"
//  ---------------------------------------------------------------------
//  FILET DE SECURITE.
//  Empêche définitivement qu'une référence externe (5717) ou une fiche
//  fournisseur article (99) survive à son article, quelle que soit
//  l'origine : suppression manuelle, API, renommage, code tiers.
//
//  Les événements de table se déclenchent même quand le code appelle
//  Delete() ou Rename() sans exécuter les triggers : c'est ce qui rend
//  ce filet étanche là où un trigger OnDelete passerait à côté.
//
//  NOUVEAU FICHIER. Ne modifie aucun objet existant.
// =====================================================================

codeunit 50031 "SIStock Data Integrity"
{
    Permissions = tabledata "Item Cross Reference" = rimd,
                  tabledata "Item Vendor" = rimd;

    // =================================================================
    //  SUPPRESSION D'UN ARTICLE
    //  -> on purge ses références externes et ses fiches fournisseur
    // =================================================================
    [EventSubscriber(ObjectType::Table, Database::Item, 'OnAfterDeleteEvent', '', false, false)]
    local procedure PurgerLiensApresSuppressionArticle(var Rec: Record Item; RunTrigger: Boolean)
    var
        ItemCrossReference: Record "Item Cross Reference";
        ItemVendor: Record "Item Vendor";
    begin
        if Rec.IsTemporary() then
            exit;
        if Rec."No." = '' then
            exit;

        ItemCrossReference.SetRange("Item No.", Rec."No.");
        if not ItemCrossReference.IsEmpty() then
            ItemCrossReference.DeleteAll();

        ItemVendor.SetRange("Item No.", Rec."No.");
        if not ItemVendor.IsEmpty() then
            ItemVendor.DeleteAll();
    end;

    // =================================================================
    //  RENOMMAGE D'UN ARTICLE
    //  -> les liens suivent le nouveau n° au lieu de rester orphelins
    //
    //  Le n° d'article fait partie de la clé primaire des deux tables :
    //  un ModifyAll est donc impossible, il faut recréer chaque ligne.
    //  A chaque tour, l'enregistrement traité sort du filtre : la boucle
    //  se termine forcément.
    // =================================================================
    [EventSubscriber(ObjectType::Table, Database::Item, 'OnAfterRenameEvent', '', false, false)]
    local procedure ReporterLiensApresRenommageArticle(var Rec: Record Item; var xRec: Record Item; RunTrigger: Boolean)
    var
        ItemCrossReference: Record "Item Cross Reference";
        ItemCrossRefCible: Record "Item Cross Reference";
        ItemVendor: Record "Item Vendor";
        ItemVendorCible: Record "Item Vendor";
    begin
        if Rec.IsTemporary() then
            exit;
        if (xRec."No." = '') or (xRec."No." = Rec."No.") then
            exit;

        // ---- Références externes (table 5717)
        ItemCrossReference.SetRange("Item No.", xRec."No.");
        while ItemCrossReference.FindFirst() do
            if ItemCrossRefCible.Get(Rec."No.",
                                     ItemCrossReference."Variant Code",
                                     ItemCrossReference."Unit of Measure",
                                     ItemCrossReference."Cross-Reference Type",
                                     ItemCrossReference."Cross-Reference Type No.",
                                     ItemCrossReference."Cross-Reference No.")
            then
                // La référence existe déjà sur le nouveau n° : on jette l'ancienne
                ItemCrossReference.Delete()
            else
                ItemCrossReference.Rename(Rec."No.",
                                          ItemCrossReference."Variant Code",
                                          ItemCrossReference."Unit of Measure",
                                          ItemCrossReference."Cross-Reference Type",
                                          ItemCrossReference."Cross-Reference Type No.",
                                          ItemCrossReference."Cross-Reference No.");

        // ---- Fiches fournisseur article (table 99)
        // Copie / suppression / réinsertion : indépendant de l'ordre de la clé
        ItemVendor.SetRange("Item No.", xRec."No.");
        while ItemVendor.FindFirst() do begin
            ItemVendorCible := ItemVendor;
            ItemVendorCible."Item No." := Rec."No.";
            ItemVendor.Delete();
            if ItemVendorCible.Insert() then;
        end;
    end;
}
