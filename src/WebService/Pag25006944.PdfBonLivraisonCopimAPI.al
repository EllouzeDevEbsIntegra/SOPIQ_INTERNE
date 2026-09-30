// Impression d'un bon de livraison de STE COPIM, en PDF encode en base 64, avec les options de la
// fenetre d'impression de Business Central. C'est le meme etat que le bouton de la fiche,
// l'etat 50235 : le comptoir et Reapro impriment donc le meme document.
//
// Cet appel ne modifie rien. L'etat sait reecrire les informations client sur le document
// quand on coche « Modifier information client » dans sa fenetre ; cette ecriture est fermee
// ici. L'appel imprime ce qui est deja enregistre sur le document, et rien d'autre.
//
// LIRE LE DOCUMENT
//   GET /api/sopiq/interne/v1.0/companies({id})/getPdfBonLivraisonCopim?$filter=documentNo eq 'BL26-001631'
//   Rend l'identite du document et les informations client enregistrees, sans produire de PDF.
//
// IMPRIMER
//   POST /api/sopiq/interne/v1.0/companies({id})/getPdfBonLivraisonCopim({systemId})/Microsoft.NAV.imprimer
//   { "afficherReference": false, "afficherRemise": false, "masquerColonneRemise": false }
//   -> { "value": "JVBERi0x..." }   le PDF, encode en base 64
//
// Les trois options valent false par defaut, comme les cases de la fenetre d'impression.
//
// Un document inexistant rend une liste vide sur la lecture, et l'action n'est pas joignable :
// jamais de PDF blanc.
page 25006944 "Pdf Bon Livraison COPIM API"
{
    PageType = API;
    SourceTable = "Sales Shipment Header";
    APIPublisher = 'sopiq';
    APIGroup = 'interne';
    APIVersion = 'v1.0';
    EntityName = 'getPdfBonLivraisonCopim';
    EntitySetName = 'getPdfBonLivraisonCopim';
    ODataKeyFields = SystemId;
    // Exige par le runtime 5.0 sur toute page d'API, meme fermee a l'ecriture.
    DelayedInsert = true;
    Extensible = false;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;

    Permissions = tabledata "Sales Shipment Header" = r;

    layout
    {
        area(Content)
        {
            repeater(Documents)
            {
                field(id; Rec.SystemId)
                {
                    Caption = 'SystemId', Locked = true;
                }
                field(documentNo; Rec."No.")
                {
                    Caption = 'N° document';
                }
                field(customerNo; Rec."Sell-to Customer No.")
                {
                    Caption = 'Client';
                }
                field(custNameImprime; Rec.custNameImprime)
                {
                    Caption = 'Nom client imprimé';
                }
                field(custAdresseImprime; Rec.custAdresseImprime)
                {
                    Caption = 'Adresse client imprimée';
                }
                field(custMFImprime; Rec.custMFImprime)
                {
                    Caption = 'Matricule fiscal imprimé';
                }
                field(custVINImprime; Rec.custVINImprime)
                {
                    Caption = 'VIN imprimé';
                }
            }
        }
    }

    var
        RenduVideErr: Label 'L''impression du document %1 n''a produit aucun document.', Comment = '%1 = numéro du document';

    // Rend le document imprime, en base 64. Aucune ecriture.
    [ServiceEnabled]
    procedure imprimer(afficherReference: Boolean; afficherRemise: Boolean; masquerColonneRemise: Boolean): Text
    var
        Document: Record "Sales Shipment Header";
        Etat: Report "BL COPIM";
        TempBlob: Codeunit "Temp Blob";
        FileManagement: Codeunit "File Management";
        Base64Convert: Codeunit "Base64 Convert";
        NomFichier: Text;
        FluxEntree: InStream;
    begin
        Document := Rec;
        Document.SetRecFilter();

        Etat.SetTableView(Document);
        Etat.DefinirOptionsImpression(afficherReference, afficherRemise, masquerColonneRemise);
        Etat.DefinirInfoClientImprimee(Rec.custNameImprime, Rec.custAdresseImprime,
                                       Rec.custMFImprime, Rec.custVINImprime);
        Etat.UseRequestPage(false);

        // Passage par un fichier temporaire du serveur : c'est le seul chemin qui accepte a
        // la fois les options de l'etat et un rendu en memoire. Le fichier est efface juste
        // apres, qu'il ait servi ou non.
        NomFichier := FileManagement.ServerTempFileName('pdf');
        Etat.SaveAsPdf(NomFichier);
        FileManagement.BLOBImportFromServerFile(TempBlob, NomFichier);
        Erase(NomFichier);

        if not TempBlob.HasValue() then
            Error(RenduVideErr, Rec."No.");

        TempBlob.CreateInStream(FluxEntree);
        exit(Base64Convert.ToBase64(FluxEntree));
    end;
}
