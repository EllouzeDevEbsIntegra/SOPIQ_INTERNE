// Creation d'un recu de caisse complet en un seul appel, puis validation.
//
// Reapro tient son recu en brouillon chez lui et n'ecrit qu'une fois, au clic Valider. Cet
// appel recoit l'en-tete, les documents et les paiements ensemble, cree le tout et le
// valide dans la meme transaction : si quoi que ce soit echoue, rien n'est ecrit et le
// numero de recu n'est pas consomme.
//
// Appel :
//   POST /api/sopiq/interne/v1.0/companies({id})/recuCaisseCreation
//   {
//     "idBrouillon": "REAPRO-2026-000123",
//     "contenu": "{ ... voir plus bas ... }"
//   }
//
// Le champ contenu porte le recu, en JSON, sous forme de texte :
//   {
//     "customerNo": "C00123",
//     "dateRecu": "2026-09-28",
//     "codeVendeur": "V12",
//     "isAcompte": false,
//     "documents": [
//       { "type": "BS", "documentNo": "BS25-5276", "libelle": "Bon de sortie",
//         "totalTTC": 120.500, "montantReglement": 120.500, "idLigneImpaye": 0 }
//     ],
//     "paiements": [
//       { "type": "Espece", "name": "", "paiementNo": "", "montant": 120.500,
//         "echeance": "", "banque": "" }
//     ]
//   }
//
// Les types acceptent le nom du membre ou son numero. Types de document : BS, Invoice,
// CreditMemo, RetourBS, Divers, BL, RetourBL, Acompte, FA, AVA, Impaye.
//
// La reponse rend recuNo, statut et message. Statut vaut Validé, ou "Déjà traité" si le
// meme identifiant de brouillon a deja ete envoye : dans ce cas rien n'est cree et recuNo
// designe le recu existant. C'est le garde-fou contre le double encaissement quand la
// reponse ne parvient pas jusqu'a Reapro.
//
// Pour savoir si un envoi a abouti :
//   GET /recuCaisseCreation?$filter=idBrouillon eq 'REAPRO-2026-000123'
page 25006939 "Recu Caisse Creation API"
{
    PageType = API;
    SourceTable = "Recu Caisse Demande";
    APIPublisher = 'sopiq';
    APIGroup = 'interne';
    APIVersion = 'v1.0';
    EntityName = 'recuCaisseCreation';
    EntitySetName = 'recuCaisseCreation';
    ODataKeyFields = SystemId;
    DelayedInsert = true;
    Extensible = false;

    Permissions = tabledata "Recu Caisse Demande" = rim;

    layout
    {
        area(Content)
        {
            repeater(Demandes)
            {
                field(id; Rec.SystemId)
                {
                    Caption = 'SystemId', Locked = true;
                    Editable = false;
                }
                field(idBrouillon; Rec."Id Brouillon")
                {
                    Caption = 'Identifiant brouillon';
                }
                field(contenu; ContenuTexte)
                {
                    Caption = 'Contenu du reçu, en JSON';
                }
                field(recuNo; Rec."Recu No")
                {
                    Caption = 'N° reçu créé';
                    Editable = false;
                }
                field(statut; Rec.Statut)
                {
                    Caption = 'Statut';
                    Editable = false;
                }
                field(message; Rec.Message)
                {
                    Caption = 'Message';
                    Editable = false;
                }
                field(dateHeure; Rec."Date Heure")
                {
                    Caption = 'Date et heure';
                    Editable = false;
                }
            }
        }
    }

    var
        ContenuTexte: Text;

    trigger OnAfterGetRecord()
    begin
        ContenuTexte := Rec.LireContenu();
    end;

    // Tout se joue ici, dans la transaction de l'appel.
    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        ValidationRecu: Codeunit "Validation Recu Caisse";
    begin
        Rec.EcrireContenu(ContenuTexte);
        ValidationRecu.CreerEtValider(Rec, ContenuTexte);
    end;
}
