// Les devis, pour Reapro : lecture, modification, archivage d'une version, et transformation
// en commande.
//
// La source est l'en-tete vente filtre sur le type Devis. Aucune table n'est creee.
//
// LIRE
//   GET /api/sopiq/interne/v1.0/companies({id})/SiDevisAPI?$filter=no eq 'DV26-00123'
//   GET ...SiDevisAPI?$filter=customerNo eq '41000845'&$orderby=no desc
//
// MODIFIER
//   PATCH /api/sopiq/interne/v1.0/companies({id})/SiDevisAPI({systemId})
//   { "custPrintName": "TAHA TIRIGUI MEC", "quoteValidUntilDate": "2026-10-31" }
//
// ARCHIVER UNE VERSION
//   POST .../SiDevisAPI({systemId})/Microsoft.NAV.archiver
//   -> { "value": 3 }   le numero de la version creee
//
//   C'est le meme traitement que le bouton « Archiver document » de la fiche.
//
// TRANSFORMER EN COMMANDE
//   POST .../SiDevisAPI({systemId})/Microsoft.NAV.creerCommande
//   -> { "value": "{\"orderNo\":\"CV26-00456\",\"orderId\":\"a1b2...\"}" }
//
//   C'est le meme traitement que le bouton « Créer commande ». Le devis disparait de cette
//   liste : Business Central le supprime, apres l'avoir archive si le parametrage des ventes
//   le demande. Les versions archivees restent lisibles par SiDevisVersionAPI.
//
// LES LIGNES vivent dans SiDevisLigneAPI, filtrees par documentNo.
page 25006948 "Si Devis API"
{
    PageType = API;
    SourceTable = "Sales Header";
    SourceTableView = where("Document Type" = const(Quote));
    APIPublisher = 'sopiq';
    APIGroup = 'interne';
    APIVersion = 'v1.0';
    EntityName = 'SiDevisAPI';
    EntitySetName = 'SiDevisAPI';
    ODataKeyFields = SystemId;
    DelayedInsert = true;
    Extensible = false;
    InsertAllowed = false;
    DeleteAllowed = false;

    Permissions = tabledata "Sales Header" = rm,
                  tabledata "Sales Line" = rimd,
                  tabledata "Sales Header Archive" = rimd,
                  tabledata "Sales Line Archive" = rimd;

    layout
    {
        area(Content)
        {
            repeater(Devis)
            {
                field(id; Rec.SystemId)
                {
                    Caption = 'SystemId', Locked = true;
                    Editable = false;
                }
                field(no; Rec."No.")
                {
                    Caption = 'N° devis';
                    Editable = false;
                }
                field(customerNo; Rec."Sell-to Customer No.")
                {
                    Caption = 'Client';
                    Editable = false;
                }
                field(customerName; Rec."Sell-to Customer Name")
                {
                    Caption = 'Nom client';
                    Editable = false;
                }
                field(billToCustomerNo; Rec."Bill-to Customer No.")
                {
                    Caption = 'Client facturé';
                    Editable = false;
                }
                field(documentDate; Rec."Document Date")
                {
                    Caption = 'Date du devis';
                }
                field(quoteValidUntilDate; Rec."Quote Valid Until Date")
                {
                    Caption = 'Valide jusqu''au';
                }
                field(salespersonCode; Rec."Salesperson Code")
                {
                    Caption = 'Vendeur';
                }
                field(expeditionType; Rec."Expédition type")
                {
                    Caption = 'Type d''expédition';
                }
                field(amount; Rec.Amount)
                {
                    Caption = 'Montant HT';
                    Editable = false;
                }
                field(amountIncludingVAT; Rec."Amount Including VAT")
                {
                    Caption = 'Montant TTC';
                    Editable = false;
                }
                field(nbVersionsArchivees; Rec."No. of Archived Versions")
                {
                    Caption = 'Nombre de versions archivées';
                    Editable = false;
                }
                field(custPrintName; Rec.custNameImprime)
                {
                    Caption = 'Nom client à imprimer';
                }
                field(custPrintAdress; Rec.custAdresseImprime)
                {
                    Caption = 'Adresse client à imprimer';
                }
                field(custPrintMF; Rec.custMFImprime)
                {
                    Caption = 'Matricule fiscal à imprimer';
                }
                field(custPrintVIN; Rec.custVINImprime)
                {
                    Caption = 'VIN à imprimer';
                }
            }
        }
    }

    var
        AucuneCommandeErr: Label 'La commande n''a pas pu être créée à partir du devis %1.', Comment = '%1 = numéro du devis';

    trigger OnAfterGetRecord()
    begin
        Rec.CalcFields(Amount, "Amount Including VAT", "No. of Archived Versions");
    end;

    // Archive une version du devis, comme le bouton de la fiche, et rend le numero de la
    // version creee.
    [ServiceEnabled]
    procedure archiver(): Integer
    var
        Devis: Record "Sales Header";
        VersionArchivee: Record "Sales Header Archive";
        ArchiveManagement: Codeunit ArchiveManagement;
    begin
        Devis.Get(Rec."Document Type", Rec."No.");
        ArchiveManagement.ArchiveSalesDocument(Devis);

        VersionArchivee.Reset();
        VersionArchivee.SetRange("Document Type", Devis."Document Type");
        VersionArchivee.SetRange("No.", Devis."No.");
        if VersionArchivee.FindLast() then
            exit(VersionArchivee."Version No.");

        exit(0);
    end;

    // Transforme le devis en commande, comme le bouton de la fiche. Rend le numero et
    // l'identifiant de la commande creee, pour que l'appelant puisse la valider ensuite.
    [ServiceEnabled]
    procedure creerCommande(): Text
    var
        Devis: Record "Sales Header";
        Commande: Record "Sales Header";
        DevisVersCommande: Codeunit "Sales-Quote to Order";
        Reponse: JsonObject;
        Texte: Text;
    begin
        Devis.Get(Rec."Document Type", Rec."No.");
        DevisVersCommande.Run(Devis);
        DevisVersCommande.GetSalesOrderHeader(Commande);

        if Commande."No." = '' then
            Error(AucuneCommandeErr, Rec."No.");

        Reponse.Add('orderNo', Commande."No.");
        Reponse.Add('orderId', Format(Commande.SystemId, 0, 4));
        Reponse.WriteTo(Texte);
        exit(Texte);
    end;
}
