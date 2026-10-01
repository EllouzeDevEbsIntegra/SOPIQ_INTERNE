// Le panier des bons de sortie a facturer, celui de la page « Panier BS à facturer » (50140).
//
// CE QU'EST LE PANIER. Ce ne sont pas des lignes dans une table a part : ce sont les lignes
// d'expedition des bons de sortie qui remplissent quatre conditions, exactement celles de la
// page du comptoir :
//   - l'expedition est un bon de sortie ;
//   - la ligne n'est pas encore facturee ;
//   - une quantite a facturer y a ete posee ;
//   - la ligne n'est pas masquee.
// Une ligne entre dans le panier quand sa quantite a facturer devient positive, et en sort
// quand elle est facturee ou masquee.
//
// LIRE LE PANIER D'UN CLIENT
//   GET /api/sopiq/interne/v1.0/companies({id})/SiPanierBsAPI
//       ?$filter=billToCustomerNo eq '41000845'
//
// CHOISIR DES LIGNES
//   PATCH .../SiPanierBsAPI({systemId})   { "selectedLine": true }
//
//   C'est la coche de la page. La selection est portee par la ligne elle-meme, elle survit
//   donc a la fermeture de l'ecran et elle est partagee : deux vendeurs qui preparent le
//   meme client se voient l'un l'autre. C'est ainsi que fonctionne le comptoir, je n'y
//   change rien.
//
// AJUSTER CE QUI SERA FACTURE
//   PATCH .../SiPanierBsAPI({systemId})   { "qtyBsToInvoice": 2, "keepInitPrices": true }
//
//   Une quantite a facturer ramenee a zero fait sortir la ligne du panier.
//
// CE QUE CET APPEL NE FAIT PAS. Il ne transforme pas le panier en bon de livraison. Ce
// traitement appartient a l'extension du verticalisateur, etat 50003 « TransfertBStoBL »,
// dont je n'ai que les symboles et pas le code. Voir la reponse du 01/10/2026 pour ce qui
// reste a decider.
page 25006958 "Si Panier BS API"
{
    PageType = API;
    SourceTable = "Sales Shipment Line";
    SourceTableView = where(BS = const(true),
                            "Quantity Invoiced" = filter(= 0),
                            "Qty BS To Invoice" = filter(> 0),
                            Masque = filter(false));
    APIPublisher = 'sopiq';
    APIGroup = 'interne';
    APIVersion = 'v1.0';
    EntityName = 'SiPanierBsAPI';
    EntitySetName = 'SiPanierBsAPI';
    ODataKeyFields = SystemId;
    DelayedInsert = true;
    Extensible = false;
    InsertAllowed = false;
    DeleteAllowed = false;

    Permissions = tabledata "Sales Shipment Line" = rm,
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
                    Editable = false;
                }
                field(documentNo; Rec."Document No.")
                {
                    Caption = 'N° bon de sortie';
                    Editable = false;
                }
                field(lineNo; Rec."Line No.")
                {
                    Caption = 'N° ligne';
                    Editable = false;
                }
                field(postingDate; Rec."Posting Date")
                {
                    Caption = 'Date';
                    Editable = false;
                }
                field(billToCustomerNo; Rec."Bill-to Customer No.")
                {
                    Caption = 'Client facturé';
                    Editable = false;
                }
                field(sellToCustomerNo; Rec."Sell-to Customer No.")
                {
                    Caption = 'Client';
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
                    Editable = false;
                }
                field(quantity; Rec.Quantity)
                {
                    Caption = 'Quantité du bon de sortie';
                    Editable = false;
                }
                field(qtyBsToInvoice; Rec."Qty BS To Invoice")
                {
                    Caption = 'Quantité à facturer';
                }
                field(selectedLine; Rec."Selected line")
                {
                    Caption = 'Ligne sélectionnée';
                }
                field(keepInitPrices; Rec."Keep Init. Prices")
                {
                    Caption = 'Garder les prix initiaux';
                }
                field(unitOfMeasureCode; Rec."Unit of Measure Code")
                {
                    Caption = 'Unité de mesure';
                    Editable = false;
                }
                field(unitPrice; Rec."Unit Price")
                {
                    Caption = 'Prix unitaire';
                    Editable = false;
                }
                field(lineDiscountPct; Rec."% Discount")
                {
                    Caption = 'Remise en pourcentage';
                    Editable = false;
                }
                field(lineAmountHT; Rec."Line Amount HT")
                {
                    Caption = 'Montant HT';
                    Editable = false;
                }
                field(lineAmount; Rec."Line Amount")
                {
                    Caption = 'Montant TTC';
                    Editable = false;
                }
                field(vatPct; Rec."VAT %")
                {
                    Caption = 'Taux TVA';
                    Editable = false;
                }
                field(documentNoBsInverse; Rec."Document No BS Inverse")
                {
                    Caption = 'N° retour qui annule cette ligne';
                    Editable = false;
                }
                field(lineNoBsInverse; Rec."Line No BS Inverse")
                {
                    Caption = 'N° ligne du retour';
                    Editable = false;
                }
            }
        }
    }
}
