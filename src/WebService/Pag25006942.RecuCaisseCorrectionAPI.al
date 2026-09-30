// Correction d'un recu de caisse deja valide, et lecture de l'historique des corrections.
//
// Le recu garde son numero : c'est le meme recu, corrige, qu'on reimprime ensuite avec
// getPdfRecuCaisse. Il n'y a ni annulation ni suppression par cet appel.
//
// LIRE LE RECU AVANT DE CORRIGER
//   GET /api/sopiq/interne/v1.0/companies({id})/recuCaisseCorrection?$filter=recuNo eq 'RC26-04863'
//   -> { "value": [ { "id": "...", "recuNo": "RC26-04863", "versionCorrection": 2,
//                     "contenuActuel": "{...}", "historiqueCorrections": "[...]" } ] }
//
//   contenuActuel est le contenu du recu au format de la creation : c'est lui que l'on
//   modifie et que l'on renvoie corrige. versionCorrection doit etre renvoye tel quel.
//
// CORRIGER
//   POST /api/sopiq/interne/v1.0/companies({id})/recuCaisseCorrection({systemId})/Microsoft.NAV.corriger
//   {
//     "contenu": "{ ... le contenu complet corrige, format de la creation ... }",
//     "motif": "Chèque saisi en espèces",
//     "auteur": "chef.comptoir@exemple.tn",
//     "idCorrection": "REAPRO-CORR-2026-000042",
//     "version": 2
//   }
//   -> { "value": true }   la correction a ete appliquee
//   -> { "value": false }  cette correction avait deja ete appliquee, le recu n'a pas bouge
//
// LES REFUS, et ce qu'ils veulent dire
//   « L'identifiant de correction est obligatoire. »
//   « Le motif de la correction est obligatoire. »
//   « Le reçu a changé depuis votre lecture : vous corrigez la version X, il en est à la
//     version Y. » : quelqu'un a corrige entre votre lecture et votre envoi. Relire, refaire.
//   « Une correction ne peut pas changer le client du reçu. » : ce serait un autre recu.
//   « Le total des règlements ... ne correspond pas au total des documents ... » : la regle
//     de la creation s'applique a l'identique.
//   Les autres refus sont ceux de la creation : client inconnu, type inconnu, contenu illisible.
//
// En cas de refus, rien n'est ecrit : le recu reste exactement tel qu'il etait.
//
// Un document retire du recu redevient a payer, un document ajoute est solde, exactement
// comme a la creation. C'est le meme code qui en repond.
page 25006942 "Recu Caisse Correction API"
{
    PageType = API;
    SourceTable = "Recu Caisse";
    APIPublisher = 'sopiq';
    APIGroup = 'interne';
    APIVersion = 'v1.0';
    EntityName = 'recuCaisseCorrection';
    EntitySetName = 'recuCaisseCorrection';
    ODataKeyFields = SystemId;
    // Exige par le runtime 5.0 sur toute page d'API, meme fermee a l'ecriture.
    DelayedInsert = true;
    Extensible = false;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;

    Permissions = tabledata "Recu Caisse" = rm,
                  tabledata "Recu Caisse Document" = rimd,
                  tabledata "Recu Caisse Paiement" = rimd;

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
                field(recuNo; Rec.No)
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
                field(versionCorrection; Rec."Version Correction")
                {
                    Caption = 'Version de correction';
                }
                field(contenuActuel; ContenuActuel)
                {
                    Caption = 'Contenu actuel du reçu, en JSON';
                }
                field(historiqueCorrections; HistoriqueCorrections)
                {
                    Caption = 'Historique des corrections, en JSON';
                }
            }
        }
    }

    var
        ContenuActuel: Text;
        HistoriqueCorrections: Text;

    trigger OnAfterGetRecord()
    var
        ValidationRecu: Codeunit "Validation Recu Caisse";
    begin
        ContenuActuel := ValidationRecu.ContenuActuel(Rec);
        HistoriqueCorrections := Rec.LireHistoriqueCorrections();
    end;

    // Rend true si la correction a ete appliquee, false si elle l'avait deja ete. Tout refus
    // remonte en erreur a l'appelant, et rien n'est ecrit.
    [ServiceEnabled]
    procedure corriger(contenu: Text; motif: Text; auteur: Text; idCorrection: Text; version: Integer): Boolean
    var
        ValidationRecu: Codeunit "Validation Recu Caisse";
    begin
        exit(ValidationRecu.CorrigerRecu(Rec, contenu, motif, auteur,
                                         CopyStr(idCorrection, 1, 50), version));
    end;
}
