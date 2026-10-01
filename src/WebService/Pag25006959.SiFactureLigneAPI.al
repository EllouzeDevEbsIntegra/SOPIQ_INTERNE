// Les lignes d'une facture vente non validee, pour les ajuster avant de valider.
//
//   GET    .../SiFactureLigneAPI?$filter=documentNo eq 'F26-001603'
//   PATCH  .../SiFactureLigneAPI({systemId})   { "quantity": 3 }
//   DELETE .../SiFactureLigneAPI({systemId})
//
// CE QUI SE MODIFIE, ET CE QUI NE SE MODIFIE PAS. Trois champs sont ouverts : la quantite,
// le prix unitaire et le montant de remise. C'est ce que le comptoir ajuste sur une facture
// issue d'une extraction.
//
// Le lien vers l'expedition est en lecture seule, et il doit le rester : c'est lui qui dit
// a Business Central ce qui a deja ete livre, et combien il reste a facturer. Le defaire
// laisserait des lignes d'expedition eternellement a facturer.
//
// SUR LA QUANTITE. La baisser laisse le reste a facturer sur la ligne d'expedition, qui
// reviendra donc dans la liste des lignes extractibles. La monter au-dela de ce qui a ete
// livre est refuse par Business Central.
//
// SUR LE PRIX. Il est repris de l'expedition. Le modifier est un geste commercial, pas une
// correction technique, et il n'a rien a voir avec le garde-fou des prix des bons de sortie,
// qui agit a la validation du bon de sortie et non ici. Si vous constatez un prix a zero sur
// une ligne issue d'un bon de sortie, ne le corrigez pas ici : c'est le bon de sortie qui est
// en cause, et il faut le signaler.
//
// L'ajout d'une ligne n'est pas ouvert par cet appel : une facture de panier BS se remplit
// par extraction. Dites-le si vous avez besoin d'ajouter des lignes libres.
page 25006959 "Si Facture Ligne API"
{
    PageType = API;
    SourceTable = "Sales Line";
    SourceTableView = where("Document Type" = const(Invoice));
    APIPublisher = 'sopiq';
    APIGroup = 'interne';
    APIVersion = 'v1.0';
    EntityName = 'SiFactureLigneAPI';
    EntitySetName = 'SiFactureLigneAPI';
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
                    Caption = 'N° facture';
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
                field(shipmentNo; Rec."Shipment No.")
                {
                    Caption = 'N° expédition d''origine';
                    Editable = false;
                }
                field(shipmentLineNo; Rec."Shipment Line No.")
                {
                    Caption = 'N° ligne d''expédition';
                    Editable = false;
                }
            }
        }
    }
}
