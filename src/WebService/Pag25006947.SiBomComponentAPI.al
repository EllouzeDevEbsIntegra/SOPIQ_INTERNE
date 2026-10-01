// Nomenclature des kits : les lignes de composants d'un article, en lecture et en ecriture.
//
// Pourquoi cet appel existe. Business Central ne reconnait un article comme kit que s'il
// porte des lignes de nomenclature a son nom : les pages Recherche article et Devis kit
// testent "Parent Item No." sur l'article lui-meme. Rattacher une reference au master d'un
// groupe produit ne suffit donc pas, il faut aussi lui donner sa nomenclature. Aucune API ne
// le permettait, ni la notre ni la standard.
//
// La table est celle de Business Central, aucune table n'est creee : la licence du client
// plafonne les tables a 300 et le compteur est plein.
//
// LIRE les lignes d'un kit
//   GET /api/sopiq/interne/v1.0/companies({id})/SiBomComponentAPI?$filter=parentItemNo eq 'X'
//
// LIRE les kits dont un article est composant
//   GET /api/sopiq/interne/v1.0/companies({id})/SiBomComponentAPI?$filter=no eq 'MASTERC'
//
// AJOUTER une ligne
//   POST /api/sopiq/interne/v1.0/companies({id})/SiBomComponentAPI
//   { "parentItemNo": "X", "no": "MASTERC", "quantityPer": 1 }
//
//   Le numero de ligne est attribue ici, derniere ligne du parent plus dix mille, comme la
//   fiche. Le type vaut Article par defaut. La designation et l'unite sont reprises de
//   l'article, exactement comme une saisie dans la fiche nomenclature.
//
// MODIFIER une ligne
//   PATCH /api/sopiq/interne/v1.0/companies({id})/SiBomComponentAPI({systemId})
//   { "quantityPer": 2 }
//
// SUPPRIMER une ligne
//   DELETE /api/sopiq/interne/v1.0/companies({id})/SiBomComponentAPI({systemId})
//
// LES REFUS
//   « Un article ne peut pas etre son propre composant... » : garde-fou pose ici, Business
//   Central ne l'interdit pas de lui-meme et la boucle rendrait l'article inexploitable.
//   Les autres refus sont ceux de Business Central, mot pour mot : article inexistant,
//   article bloque, unite de mesure inconnue.
page 25006947 "Si Bom Component API"
{
    PageType = API;
    SourceTable = "BOM Component";
    APIPublisher = 'sopiq';
    APIGroup = 'interne';
    APIVersion = 'v1.0';
    EntityName = 'SiBomComponentAPI';
    EntitySetName = 'SiBomComponentAPI';
    ODataKeyFields = SystemId;
    DelayedInsert = true;
    Extensible = false;

    Permissions = tabledata "BOM Component" = rimd;

    layout
    {
        area(Content)
        {
            repeater(Lignes)
            {
                field(id; Rec.SystemId)
                {
                    Caption = 'SystemId', Locked = true;
                    Editable = false;
                }
                field(parentItemNo; Rec."Parent Item No.")
                {
                    Caption = 'Article parent';
                }
                field(lineNo; Rec."Line No.")
                {
                    Caption = 'N° ligne';
                    Editable = false;
                }
                field(type; Rec.Type)
                {
                    Caption = 'Type';
                }
                field(no; Rec."No.")
                {
                    Caption = 'N° composant';
                }
                field(description; Rec.Description)
                {
                    Caption = 'Désignation';
                }
                field(unitOfMeasureCode; Rec."Unit of Measure Code")
                {
                    Caption = 'Unité de mesure';
                }
                field(quantityPer; Rec."Quantity per")
                {
                    Caption = 'Quantité par';
                }
            }
        }
    }

    var
        BoucleErr: Label 'Un article ne peut pas être son propre composant : %1.', Comment = '%1 = numéro de l''article';
        ParentManquantErr: Label 'L''article parent est obligatoire.';
        ComposantManquantErr: Label 'Le composant est obligatoire.';

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        LigneExistante: Record "BOM Component";
    begin
        if Rec."Parent Item No." = '' then
            Error(ParentManquantErr);
        if Rec."No." = '' then
            Error(ComposantManquantErr);
        if Rec."Parent Item No." = Rec."No." then
            Error(BoucleErr, Rec."No.");

        // Le numero de ligne suit la convention de la fiche : dix mille d'ecart, pour
        // pouvoir intercaler plus tard.
        if Rec."Line No." = 0 then begin
            LigneExistante.Reset();
            LigneExistante.SetRange("Parent Item No.", Rec."Parent Item No.");
            if LigneExistante.FindLast() then
                Rec."Line No." := LigneExistante."Line No." + 10000
            else
                Rec."Line No." := 10000;
        end;

        // Type Article par defaut : c'est le seul present dans les donnees du client.
        if Rec.Type = Rec.Type::" " then
            Rec.Type := Rec.Type::Item;

        // La designation et l'unite viennent de l'article, comme une saisie dans la fiche.
        // Validate rend aussi les refus de Business Central, article inexistant ou bloque.
        Rec.Validate(Type);
        Rec.Validate("No.");

        if Rec."Quantity per" = 0 then
            Rec.Validate("Quantity per", 1);

        exit(true);
    end;

    trigger OnModifyRecord(): Boolean
    begin
        if Rec."Parent Item No." = Rec."No." then
            Error(BoucleErr, Rec."No.");
        exit(true);
    end;
}
