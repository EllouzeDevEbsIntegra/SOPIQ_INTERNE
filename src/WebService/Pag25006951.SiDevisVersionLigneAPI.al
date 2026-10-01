// Les lignes d'une version archivee de devis.
//
// LIRE
//   GET /api/sopiq/interne/v1.0/companies({id})/SiDevisVersionLigneAPI
//       ?$filter=documentNo eq 'DV26-00123' and versionNo eq 3
//
// LE FILTRE SUR LA VERSION EST INDISPENSABLE. Sans lui, la lecture rend les lignes de toutes
// les versions du devis, melangees. C'est le defaut de l'etat « Devis PDR Archive », qui
// n'est pas reproduit ici : l'appel laisse l'appelant filtrer, et c'est a lui de toujours
// preciser la version.
//
// Lecture seule.
page 25006951 "Si Devis Version Ligne API"
{
    PageType = API;
    SourceTable = "Sales Line Archive";
    SourceTableView = where("Document Type" = const(Quote));
    APIPublisher = 'sopiq';
    APIGroup = 'interne';
    APIVersion = 'v1.0';
    EntityName = 'SiDevisVersionLigneAPI';
    EntitySetName = 'SiDevisVersionLigneAPI';
    ODataKeyFields = SystemId;
    DelayedInsert = true;
    Extensible = false;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;

    Permissions = tabledata "Sales Line Archive" = r;

    layout
    {
        area(Content)
        {
            repeater(Lignes)
            {
                field(id; Rec.SystemId)
                {
                    Caption = 'SystemId', Locked = true;
                }
                field(documentNo; Rec."Document No.")
                {
                    Caption = 'N° devis';
                }
                field(versionNo; Rec."Version No.")
                {
                    Caption = 'N° version';
                }
                field(lineNo; Rec."Line No.")
                {
                    Caption = 'N° ligne';
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
                }
            }
        }
    }
}
