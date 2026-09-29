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
//     "contenu": "{ ... voir plus bas ... }",
//     "idBrouillon": "REAPRO-2026-000123"
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
//
// Attention, sur idBrouillon : il est branche sur le champ de la table, pas sur une variable
// de page. C'est volontaire. Avec DelayedInsert, Business Central n'insere que si un champ
// de l'enregistrement a ete renseigne ; quand les deux champs de l'appel etaient des
// variables de page, rien n'etait modifie, aucune insertion n'etait tentee, OnInsertRecord
// n'etait jamais appele et l'appel repondait 200 avec un recu vide sans rien ecrire.
// contenu reste une variable de page faute de pouvoir exposer un blob, et il est declare
// avant idBrouillon pour etre deja renseigne au moment ou l'insertion part.
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
                field(contenu; ContenuTexte)
                {
                    Caption = 'Contenu du reçu, en JSON';
                }
                field(idBrouillon; Rec."Id Brouillon Reapro")
                {
                    Caption = 'Identifiant brouillon';
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

    trigger OnAfterGetRecord()
    begin
        ContenuTexte := Rec.LireContenuReapro();
    end;

    // Tout se joue ici, dans la transaction de l'appel. Le codeunit insere le recu lui-meme,
    // avec ses documents et ses paiements, puis le valide ; l'insertion de la page n'a donc
    // plus lieu d'etre, d'ou exit(false). Toute erreur remonte telle quelle a l'appelant.
    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        ValidationRecu: Codeunit "Validation Recu Caisse";
        IdBrouillon: Code[50];
    begin
        // Releve avant l'appel : le codeunit repart d'un enregistrement vierge.
        IdBrouillon := Rec."Id Brouillon Reapro";
        ValidationRecu.CreerEtValider(Rec, IdBrouillon, ContenuTexte);
        exit(false);
    end;
}
