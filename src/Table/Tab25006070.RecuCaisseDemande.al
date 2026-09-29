// Demande de creation d'un recu de caisse, envoyee en un seul appel par Reapro.
//
// Reapro tient son recu en brouillon chez lui et n'ecrit dans Business Central qu'une fois,
// au clic Valider. Cette table recoit la demande entiere, en-tete, documents et paiements,
// et garde la trace de ce qu'elle est devenue.
//
// L'identifiant de brouillon est la clef de tout : c'est lui qui evite d'encaisser deux
// fois le meme client si la reponse n'arrive pas jusqu'a Reapro. Il est unique, il est
// recopie sur l'en-tete du recu, et un second envoi du meme brouillon rend le recu deja
// cree au lieu d'en creer un autre.
table 25006656 "Recu Caisse Demande"
{
    Caption = 'Demande de reçu de caisse';
    DataClassification = ToBeClassified;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'N° séquentiel';
            AutoIncrement = true;
        }
        field(10; "Id Brouillon"; Code[50])
        {
            Caption = 'Identifiant brouillon Reapro';
            NotBlank = true;
        }
        field(20; "Recu No"; Code[20])
        {
            Caption = 'N° reçu créé';
            Editable = false;
            TableRelation = "Recu Caisse".No;
        }
        field(30; Statut; Option)
        {
            Caption = 'Statut';
            Editable = false;
            OptionMembers = "En attente",Validé,"Déjà traité",Erreur;
            OptionCaption = 'En attente,Validé,Déjà traité,Erreur';
        }
        field(40; Message; Text[250])
        {
            Caption = 'Message';
            Editable = false;
        }
        field(50; "Date Heure"; DateTime)
        {
            Caption = 'Date et heure';
            Editable = false;
        }
        field(60; Utilisateur; Code[50])
        {
            Caption = 'Compte appelant';
            Editable = false;
        }
        // Le contenu envoye, conserve tel quel : sans lui, impossible de savoir ce que
        // Reapro avait demande le jour ou un recu est conteste.
        field(70; Contenu; Blob)
        {
            Caption = 'Contenu reçu';
        }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
        key(Brouillon; "Id Brouillon") { Unique = true; }
    }

    trigger OnInsert()
    begin
        "Date Heure" := CurrentDateTime();
        Utilisateur := CopyStr(UserId(), 1, MaxStrLen(Utilisateur));
    end;

    procedure EcrireContenu(Texte: Text)
    var
        Flux: OutStream;
    begin
        Clear(Contenu);
        Contenu.CreateOutStream(Flux, TextEncoding::UTF8);
        Flux.WriteText(Texte);
    end;

    procedure LireContenu(): Text
    var
        Flux: InStream;
        Texte: Text;
    begin
        CalcFields(Contenu);
        if not Contenu.HasValue() then
            exit('');
        Contenu.CreateInStream(Flux, TextEncoding::UTF8);
        Flux.ReadText(Texte);
        exit(Texte);
    end;
}
