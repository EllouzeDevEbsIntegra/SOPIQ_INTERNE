// Les lignes d'un devis : ajout, modification, suppression.
//
// LIRE
//   GET /api/sopiq/interne/v1.0/companies({id})/SiDevisLigneAPI?$filter=documentNo eq 'DV26-00123'
//
// AJOUTER
//   POST /api/sopiq/interne/v1.0/companies({id})/SiDevisLigneAPI
//   { "documentNo": "DV26-00123", "no": "ART001", "quantity": 2,
//     "unitPrice": 45.500, "lineDiscountAmount": 5.000 }
//
//   Le numero de ligne est attribue ici, derniere ligne plus dix mille.
//   Le type vaut Article par defaut.
//
// MODIFIER, SUPPRIMER
//   PATCH  .../SiDevisLigneAPI({systemId})   { "quantity": 3 }
//   DELETE .../SiDevisLigneAPI({systemId})
//
// LE PRIX ET LA REMISE NE SONT PAS RECALCULES. L'appelant envoie ce qu'il a calcule, et
// c'est ce qui est enregistre : le prix unitaire et le montant de remise sont poses
// directement, sans passer par la validation qui irait chercher les tarifs. L'article, la
// quantite et l'unite, eux, sont valides normalement, pour que la ligne reste coherente
// avec la fiche article et le stock.
//
// L'ORDRE COMPTE, et il est tenu ici : l'article d'abord, puis la quantite, puis le prix et
// la remise. Valider l'article apres le prix remettrait le tarif du catalogue.
page 25006949 "Si Devis Ligne API"
{
    PageType = API;
    SourceTable = "Sales Line";
    SourceTableView = where("Document Type" = const(Quote));
    APIPublisher = 'sopiq';
    APIGroup = 'interne';
    APIVersion = 'v1.0';
    EntityName = 'SiDevisLigneAPI';
    EntitySetName = 'SiDevisLigneAPI';
    ODataKeyFields = SystemId;
    DelayedInsert = true;
    Extensible = false;

    Permissions = tabledata "Sales Line" = rimd;

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
                field(documentNo; Rec."Document No.")
                {
                    Caption = 'N° devis';
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
                    Caption = 'N° article';
                }
                field(description; Rec.Description)
                {
                    Caption = 'Désignation';
                }
                field(quantity; Rec.Quantity)
                {
                    Caption = 'Quantité';
                }
                field(unitOfMeasureCode; Rec."Unit of Measure Code")
                {
                    Caption = 'Unité de mesure';
                }
                field(unitPrice; Rec."Unit Price")
                {
                    Caption = 'Prix unitaire';
                }
                field(lineDiscountAmount; Rec."Line Discount Amount")
                {
                    Caption = 'Montant remise';
                }
                field(lineAmount; Rec."Line Amount")
                {
                    Caption = 'Montant ligne';
                    Editable = false;
                }
                field(vatPct; Rec."VAT %")
                {
                    Caption = 'Taux TVA';
                    Editable = false;
                }
                field(locationCode; Rec."Location Code")
                {
                    Caption = 'Magasin';
                }
            }
        }
    }

    var
        DocumentManquantErr: Label 'Le numéro de devis est obligatoire.';
        DevisInconnuErr: Label 'Le devis %1 n''existe pas.', Comment = '%1 = numéro de devis';

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        // Pose avant que l'appel ne renseigne ses champs : la ligne refuse un article sans
        // type, et ce refus tomberait avant l'insertion.
        Rec.Type := Rec.Type::Item;
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        Devis: Record "Sales Header";
        LigneExistante: Record "Sales Line";
    begin
        if Rec."Document No." = '' then
            Error(DocumentManquantErr);

        if not Devis.Get(Devis."Document Type"::Quote, Rec."Document No.") then
            Error(DevisInconnuErr, Rec."Document No.");

        if Rec."Line No." = 0 then begin
            LigneExistante.Reset();
            LigneExistante.SetRange("Document Type", Rec."Document Type");
            LigneExistante.SetRange("Document No.", Rec."Document No.");
            if LigneExistante.FindLast() then
                Rec."Line No." := LigneExistante."Line No." + 10000
            else
                Rec."Line No." := 10000;
        end;

        exit(true);
    end;
}
