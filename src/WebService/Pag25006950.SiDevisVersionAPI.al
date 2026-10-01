// Les versions archivees d'un devis : l'en-tete de chaque version.
//
// LIRE LES VERSIONS D'UN DEVIS
//   GET /api/sopiq/interne/v1.0/companies({id})/SiDevisVersionAPI?$filter=no eq 'DV26-00123'
//
// Les lignes d'une version se lisent dans SiDevisVersionLigneAPI, filtrees sur le numero du
// devis ET le numero de version : une version sans son filtre de version rendrait les lignes
// de toutes les versions melangees.
//
// Lecture seule. Une version archivee ne se modifie pas.
page 25006950 "Si Devis Version API"
{
    PageType = API;
    SourceTable = "Sales Header Archive";
    SourceTableView = where("Document Type" = const(Quote));
    APIPublisher = 'sopiq';
    APIGroup = 'interne';
    APIVersion = 'v1.0';
    EntityName = 'SiDevisVersionAPI';
    EntitySetName = 'SiDevisVersionAPI';
    ODataKeyFields = SystemId;
    DelayedInsert = true;
    Extensible = false;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;

    Permissions = tabledata "Sales Header Archive" = r;

    layout
    {
        area(Content)
        {
            repeater(Versions)
            {
                field(id; Rec.SystemId)
                {
                    Caption = 'SystemId', Locked = true;
                }
                field(no; Rec."No.")
                {
                    Caption = 'N° devis';
                }
                field(versionNo; Rec."Version No.")
                {
                    Caption = 'N° version';
                }
                field(archivedOn; Rec."Date Archived")
                {
                    Caption = 'Date d''archivage';
                }
                field(archivedAt; Rec."Time Archived")
                {
                    Caption = 'Heure d''archivage';
                }
                field(archivedBy; Rec."Archived By")
                {
                    Caption = 'Archivé par';
                }
                field(customerNo; Rec."Sell-to Customer No.")
                {
                    Caption = 'Client';
                }
                field(customerName; Rec."Sell-to Customer Name")
                {
                    Caption = 'Nom client';
                }
                field(documentDate; Rec."Document Date")
                {
                    Caption = 'Date du devis';
                }
                field(salespersonCode; Rec."Salesperson Code")
                {
                    Caption = 'Vendeur';
                }
            }
        }
    }
}
