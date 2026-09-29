// Rend un recu de caisse imprime, en PDF encode en base 64, tel que la fiche l'imprime :
// c'est le meme rapport 25006029 que le bouton de la fiche, appele de la meme facon. Il
// sert aussi bien a l'impression qui suit la validation qu'a une reimpression plus tard,
// sur n'importe quel recu de la societe, y compris ceux saisis dans Business Central.
//
// Appel :
//   GET /api/sopiq/interne/v1.0/companies({id})/getPdfRecuCaisse?$filter=No eq 'RC26-04863'
//   -> { "value": [ { "No": "RC26-04863", "pdfBase64": "JVBERi0x..." } ] }
//
// Un recu inexistant rend une liste vide, jamais un PDF blanc.
//
// Cet appel ne modifie rien. Le rapport posait "Imprimé" en fin d'execution ; il ne le fait
// plus, c'est la validation qui s'en charge dans le codeunit 50035. Une reimpression est
// donc sans effet sur la donnee, et l'insertion, la modification et la suppression sont
// fermees sur cette page.
//
// Le filtre sur le numero est obligatoire : sans lui, l'appel rendrait un PDF par recu de la
// societe, soit plusieurs milliers de rendus pour un seul appel.
//
// A propos du format : le contrat ne depend pas de la mise en page. Le jour ou le ticket
// 80 mm existera, soit il remplace la mise en page du rapport et cet appel rend le ticket
// sans que rien ne change chez l'appelant, soit les deux formats doivent coexister et une
// seconde entite sera publiee a cote de celle-ci.
page 25006941 "Recu Caisse PDF API"
{
    PageType = API;
    SourceTable = "Recu Caisse";
    APIPublisher = 'sopiq';
    APIGroup = 'interne';
    APIVersion = 'v1.0';
    EntityName = 'getPdfRecuCaisse';
    EntitySetName = 'getPdfRecuCaisse';
    ODataKeyFields = No;
    // Exige par le runtime 5.0 sur toute page d'API, meme fermee a l'ecriture. Sans effet
    // ici, l'insertion etant interdite.
    DelayedInsert = true;
    Extensible = false;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;

    Permissions = tabledata "Recu Caisse" = r,
                  tabledata "Recu Caisse Document" = r,
                  tabledata "Recu Caisse Paiement" = r;

    layout
    {
        area(Content)
        {
            repeater(Recus)
            {
                field(id; Rec.SystemId)
                {
                    Caption = 'SystemId', Locked = true;
                }
                field(No; Rec.No)
                {
                    Caption = 'N° reçu';
                }
                field(customerNo; Rec."Customer No")
                {
                    Caption = 'Client';
                }
                field(dateRecu; Rec.dateRecu)
                {
                    Caption = 'Date reçu';
                }
                field(printed; Rec.Printed)
                {
                    Caption = 'Imprimé';
                }
                field(pdfBase64; PdfBase64)
                {
                    Caption = 'Reçu imprimé, en base 64';
                }
            }
        }
    }

    var
        PdfBase64: Text;
        FiltreObligatoireErr: Label 'Précisez le reçu à imprimer, par exemple $filter=No eq ''RC26-04863''.';
        RenduErr: Label 'Le reçu %1 n''a pas pu être imprimé.', Comment = '%1 = numéro du reçu';
        RenduVideErr: Label 'L''impression du reçu %1 n''a produit aucun document.', Comment = '%1 = numéro du reçu';

    trigger OnOpenPage()
    begin
        // N'importe quel filtre convient, y compris l'acces direct par le numero en cle :
        // ce qui est refuse, c'est l'appel sans aucun filtre, qui rendrait un PDF par recu.
        if Rec.GetFilters() = '' then
            Error(FiltreObligatoireErr);
    end;

    trigger OnAfterGetRecord()
    var
        RecuAImprimer: Record "Recu Caisse";
        TempBlob: Codeunit "Temp Blob";
        Base64Convert: Codeunit "Base64 Convert";
        ReferenceRecu: RecordRef;
        FluxSortie: OutStream;
        FluxEntree: InStream;
    begin
        Clear(PdfBase64);

        // Le rapport attend un seul recu : on lui passe celui de la ligne, filtre sur lui.
        // SaveAs prend une reference, d'ou la conversion ; le filtre est reporte dessus
        // explicitement, pour ne pas dependre de ce que GetTable transmet.
        RecuAImprimer := Rec;
        RecuAImprimer.SetRecFilter();
        ReferenceRecu.GetTable(RecuAImprimer);
        ReferenceRecu.SetView(RecuAImprimer.GetView());

        // Le PDF est rendu directement dans le blob, sans fichier temporaire sur le serveur :
        // rien a nettoyer, et rien qui reste derriere si l'appel echoue en cours de route.
        TempBlob.CreateOutStream(FluxSortie);
        if not Report.SaveAs(Report::"Recu Caisse", '', ReportFormat::Pdf, FluxSortie, ReferenceRecu) then
            Error(RenduErr, Rec.No);

        if not TempBlob.HasValue() then
            Error(RenduVideErr, Rec.No);

        TempBlob.CreateInStream(FluxEntree);
        PdfBase64 := Base64Convert.ToBase64(FluxEntree);
    end;
}
