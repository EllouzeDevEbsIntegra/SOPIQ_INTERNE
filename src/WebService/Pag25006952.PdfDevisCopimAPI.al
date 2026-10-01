// Impression d'un devis de STE COPIM, en PDF encode en base 64, avec les options de la
// fenetre d'impression. C'est le meme etat que le bouton de la fiche, 25006030 « DEVIS
// COPIM ».
//
// Cet appel ne modifie rien : l'ecriture des informations client sur le devis, que l'etat
// sait faire quand on coche sa case, est fermee ici.
//
// LIRE LE DEVIS
//   GET /api/sopiq/interne/v1.0/companies({id})/getPdfDevisCopim?$filter=documentNo eq 'DV26-00123'
//
// IMPRIMER
//   POST .../getPdfDevisCopim({systemId})/Microsoft.NAV.imprimer
//   { "afficherCodeArticle": true, "masquerColonneRemise": false }
//   -> { "value": "JVBERi0x..." }
//
// Les deux options valent false par defaut, comme les cases de la fenetre.
page 25006952 "Pdf Devis COPIM API"
{
    PageType = API;
    SourceTable = "Sales Header";
    SourceTableView = where("Document Type" = const(Quote));
    APIPublisher = 'sopiq';
    APIGroup = 'interne';
    APIVersion = 'v1.0';
    EntityName = 'getPdfDevisCopim';
    EntitySetName = 'getPdfDevisCopim';
    ODataKeyFields = SystemId;
    DelayedInsert = true;
    Extensible = false;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;

    Permissions = tabledata "Sales Header" = r;

    layout
    {
        area(Content)
        {
            repeater(Devis)
            {
                field(id; Rec.SystemId)
                {
                    Caption = 'SystemId', Locked = true;
                }
                field(documentNo; Rec."No.")
                {
                    Caption = 'N° devis';
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
        RenduVideErr: Label 'L''impression du devis %1 n''a produit aucun document.', Comment = '%1 = numéro du devis';

    [ServiceEnabled]
    procedure imprimer(afficherCodeArticle: Boolean; masquerColonneRemise: Boolean): Text
    var
        Devis: Record "Sales Header";
        Etat: Report "DEVIS COPIM";
        TempBlob: Codeunit "Temp Blob";
        FileManagement: Codeunit "File Management";
        Base64Convert: Codeunit "Base64 Convert";
        NomFichier: Text;
        FluxEntree: InStream;
    begin
        Devis := Rec;
        Devis.SetRecFilter();

        Etat.SetTableView(Devis);
        Etat.DefinirOptionsImpression(afficherCodeArticle, masquerColonneRemise);
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
