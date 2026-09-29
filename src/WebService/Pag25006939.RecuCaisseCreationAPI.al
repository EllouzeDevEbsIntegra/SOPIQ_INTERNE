// Creation d'un recu de caisse complet en un seul appel, puis validation.
//
// Reapro tient son recu en brouillon chez lui et n'ecrit qu'une fois, au clic Valider. Cet
// appel recoit l'en-tete, les documents et les paiements ensemble, cree le tout et le
// valide dans la meme transaction : si quoi que ce soit echoue, rien n'est ecrit et le
// numero de recu n'est pas consomme.
//
// La source est la table des recus elle-meme : l'enregistrement que cet appel insere EST le
// recu. Il n'y a pas de table tampon, la licence du client plafonnant les tables a 300 et le
// compteur etant plein.
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
//     "dateRecu": "2026-09-29",
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
// La reponse rend le recu cree, avec son numero. Un second envoi du meme identifiant de
// brouillon est refuse en nommant le recu deja cree : c'est le garde-fou contre le double
// encaissement quand la reponse ne parvient pas jusqu'a Reapro. Pour retrouver ce recu :
//   GET /recuCaisseAPI?$filter=idBrouillonReapro eq 'REAPRO-2026-000123'
page 25006939 "Recu Caisse Creation API"
{
    PageType = API;
    SourceTable = "Recu Caisse";
    APIPublisher = 'sopiq';
    APIGroup = 'interne';
    APIVersion = 'v1.0';
    EntityName = 'recuCaisseCreation';
    EntitySetName = 'recuCaisseCreation';
    ODataKeyFields = SystemId;
    DelayedInsert = true;
    Extensible = false;
    ModifyAllowed = false;
    DeleteAllowed = false;

    Permissions = tabledata "Recu Caisse" = rim,
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
                    Editable = false;
                }
                field(idBrouillon; IdBrouillon)
                {
                    Caption = 'Identifiant brouillon';
                }
                field(contenu; ContenuTexte)
                {
                    Caption = 'Contenu du reçu, en JSON';
                }
                field(recuNo; Rec.No)
                {
                    Caption = 'N° reçu créé';
                    Editable = false;
                }
                field(customerNo; Rec."Customer No")
                {
                    Caption = 'Client';
                    Editable = false;
                }
                field(dateRecu; Rec.dateRecu)
                {
                    Caption = 'Date reçu';
                    Editable = false;
                }
                field(printed; Rec.Printed)
                {
                    Caption = 'Imprimé';
                    Editable = false;
                }
            }
        }
    }

    var
        ContenuTexte: Text;
        IdBrouillon: Code[50];

    trigger OnAfterGetRecord()
    begin
        IdBrouillon := Rec."Id Brouillon Reapro";
        ContenuTexte := Rec.LireContenuReapro();
    end;

    // Tout se joue ici, dans la transaction de l'appel.
    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        ValidationRecu: Codeunit "Validation Recu Caisse";
    begin
        ValidationRecu.CreerEtValider(Rec, IdBrouillon, ContenuTexte);
        exit(false);
    end;
}
