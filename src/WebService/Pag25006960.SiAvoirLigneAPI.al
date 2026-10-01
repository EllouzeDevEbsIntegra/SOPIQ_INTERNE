// Les lignes d'un avoir vente non valide, pour les ajuster avant de valider.
//
//   GET    .../SiAvoirLigneAPI?$filter=documentNo eq 'AV26-0034'
//   PATCH  .../SiAvoirLigneAPI({systemId})   { "quantity": 3 }
//   DELETE .../SiAvoirLigneAPI({systemId})
//
// CE QUI SE MODIFIE, ET CE QUI NE SE MODIFIE PAS. Trois champs sont ouverts : la quantite,
// le prix unitaire et le montant de remise. C'est ce que le comptoir ajuste sur une facture
// issue d'une extraction.
//
// Le lien vers la reception retour est en lecture seule, et il doit le rester : c'est lui
// qui dit a Business Central ce qui a deja ete recu, et combien il reste a facturer.
//
// SUR LA QUANTITE. La baisser laisse le reste a facturer sur la ligne de reception, qui
// reviendra donc dans la liste des lignes extractibles. La monter au-dela de ce qui a ete
// recu est refuse par Business Central.
//
// SUR LE PRIX. Il est repris de la reception retour. Le modifier est un geste commercial.
//
// L'ajout d'une ligne n'est pas ouvert par cet appel : un avoir se remplit par extraction.
// Dites-le si vous avez besoin d'ajouter des lignes libres.
page 25006960 "Si Avoir Ligne API"
{
    PageType = API;
    SourceTable = "Sales Line";
    SourceTableView = where("Document Type" = const("Credit Memo"));
    APIPublisher = 'sopiq';
    APIGroup = 'interne';
    APIVersion = 'v1.0';
    EntityName = 'SiAvoirLigneAPI';
    EntitySetName = 'SiAvoirLigneAPI';
    ODataKeyFields = SystemId;
    DelayedInsert = true;
    Extensible = false;
    InsertAllowed = false;

    Permissions = tabledata "Sales Line" = rmd;

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
                    Caption = 'N° avoir';
                    Editable = false;
                }
                field(lineNo; Rec."Line No.")
                {
                    Caption = 'N° ligne';
                    Editable = false;
                }
                field(type; Rec.Type)
                {
                    Caption = 'Type';
                    Editable = false;
                }
                field(no; Rec."No.")
                {
                    Caption = 'N° article';
                    Editable = false;
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
                    Editable = false;
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
                field(returnReceiptNo; Rec."Return Receipt No.")
                {
                    Caption = 'N° réception retour d''origine';
                    Editable = false;
                }
                field(returnReceiptLineNo; Rec."Return Receipt Line No.")
                {
                    Caption = 'N° ligne de réception';
                    Editable = false;
                }
            }
        }
    }
}
