// Les lignes d'expedition que Business Central proposerait a l'extraction sur une facture
// brouillon, pour un client donne.
//
// C'est la meme selection que la page « Extraire lignes expedition » du bouton : les lignes
// d'expedition du client facture qu'il reste a facturer. Le filtre sur le reste a facturer
// est pose ici, vous n'avez donc qu'a filtrer sur le client.
//
//   GET /api/sopiq/interne/v1.0/companies({id})/SiLigneExpeditionAExtraire
//       ?$filter=billToCustomerNo eq '41000845'
//
// Les bons de sortie en font partie : un BS est une expedition comme une autre, seul
// l'indicateur de son en-tete le distingue. Le champ bs permet de les reconnaitre, et de les
// ecarter si besoin.
//
// Pour ajouter des lignes a un brouillon, voir l'action extraireLignes de SiFactureBrouillon.
//
// Lecture seule.
page 25006954 "Si Ligne Expedition A Extraire"
{
    PageType = API;
    SourceTable = "Sales Shipment Line";
    APIPublisher = 'sopiq';
    APIGroup = 'interne';
    APIVersion = 'v1.0';
    EntityName = 'SiLigneExpeditionAExtraire';
    EntitySetName = 'SiLigneExpeditionAExtraire';
    ODataKeyFields = SystemId;
    DelayedInsert = true;
    Extensible = false;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;

    Permissions = tabledata "Sales Shipment Line" = r,
                  tabledata "Sales Shipment Header" = r;

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
                    Caption = 'N° expédition';
                }
                field(lineNo; Rec."Line No.")
                {
                    Caption = 'N° ligne';
                }
                field(postingDate; Rec."Posting Date")
                {
                    Caption = 'Date';
                }
                field(billToCustomerNo; Rec."Bill-to Customer No.")
                {
                    Caption = 'Client facturé';
                }
                field(sellToCustomerNo; Rec."Sell-to Customer No.")
                {
                    Caption = 'Client';
                }
                field(bs; EstBonDeSortie)
                {
                    Caption = 'Bon de sortie';
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
                    Caption = 'Quantité expédiée';
                }
                field(qtyShippedNotInvoiced; Rec."Qty. Shipped Not Invoiced")
                {
                    Caption = 'Reste à facturer';
                }
                field(unitOfMeasureCode; Rec."Unit of Measure Code")
                {
                    Caption = 'Unité de mesure';
                }
                field(unitPrice; Rec."Unit Price")
                {
                    Caption = 'Prix unitaire';
                }
                field(lineDiscountPct; Rec."Line Discount %")
                {
                    Caption = 'Remise en pourcentage';
                }
                field(lineAmount; Rec."Line Amount")
                {
                    Caption = 'Montant ligne';
                }
                field(locationCode; Rec."Location Code")
                {
                    Caption = 'Magasin';
                }
            }
        }
    }

    var
        EstBonDeSortie: Boolean;
        FiltreClientErr: Label 'Précisez le client, par exemple $filter=billToCustomerNo eq ''41000845''.';

    trigger OnOpenPage()
    begin
        // Sans filtre, la lecture parcourrait toutes les expeditions de la societe.
        if Rec.GetFilters() = '' then
            Error(FiltreClientErr);

        // La regle de la page du bouton : seules les lignes qu'il reste a facturer.
        Rec.SetFilter("Qty. Shipped Not Invoiced", '<>0');
    end;

    trigger OnAfterGetRecord()
    var
        Expedition: Record "Sales Shipment Header";
    begin
        EstBonDeSortie := false;
        if Expedition.Get(Rec."Document No.") then
            EstBonDeSortie := Expedition.BS;
    end;
}
