// Impression d'une reception retour de STE COPIM, en PDF encode en base 64, avec les options
// de la fenetre d'impression. C'est le meme etat que le bouton de la fiche, 25006119
// « Retour COPIM ».
//
// Cet appel ne modifie rien : l'ecriture des informations client sur le document, que l'etat
// sait faire quand on coche sa case, est fermee ici.
//
// LIRE
//   GET /api/sopiq/interne/v1.0/companies({id})/getPdfReceptionRetourCopim?$filter=documentNo eq 'R+BS26-0012'
//
// IMPRIMER
//   POST .../getPdfReceptionRetourCopim({systemId})/Microsoft.NAV.imprimer
//   { "afficherReference": false, "afficherRemise": false, "masquerColonneRemise": false }
//   -> { "value": "JVBERi0x..." }
//
// Les trois options valent false par defaut, comme les cases de la fenetre.
page 25006953 "Pdf Reception Retour COPIM"
{
    PageType = API;
    SourceTable = "Return Receipt Header";
    APIPublisher = 'sopiq';
    APIGroup = 'interne';
    APIVersion = 'v1.0';
    EntityName = 'getPdfReceptionRetourCopim';
    EntitySetName = 'getPdfReceptionRetourCopim';
    ODataKeyFields = SystemId;
    DelayedInsert = true;
    Extensible = false;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;

    Permissions = tabledata "Return Receipt Header" = r;

    layout
    {
        area(Content)
        {
            repeater(Receptions)
            {
                field(id; Rec.SystemId)
                {
                    Caption = 'SystemId', Locked = true;
                }
                field(documentNo; Rec."No.")
                {
                    Caption = 'N° réception retour';
                }
                field(customerNo; Rec."Sell-to Customer No.")
                {
                    Caption = 'Client';
                }
                field(bs; Rec.BS)
                {
                    Caption = 'Retour de bon de sortie';
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
        RenduVideErr: Label 'L''impression du retour %1 n''a produit aucun document.', Comment = '%1 = numéro du document';

    [ServiceEnabled]
    procedure imprimer(afficherReference: Boolean; afficherRemise: Boolean; masquerColonneRemise: Boolean): Text
    var
        Document: Record "Return Receipt Header";
        Etat: Report "Retour COPIM";
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
