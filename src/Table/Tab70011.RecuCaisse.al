table 70011 "Recu Caisse"
{
    DataClassification = ToBeClassified;

    fields
    {
        field(70011; No; code[10])
        {
            DataClassification = ToBeClassified;
        }
        field(70010; "Customer No"; Code[20])
        {
            DataClassification = ToBeClassified;
            TableRelation = Customer;
        }

        field(70009; custName; text[100])
        {
            DataClassification = ToBeClassified;
            Editable = false;
        }

        field(70012; dateTime; DateTime)
        {
            DataClassification = ToBeClassified;
        }
        field(70020; dateRecu; Date)
        {
            DataClassification = ToBeClassified;
        }
        field(70013; user; code[20])
        {
            DataClassification = ToBeClassified;
            TableRelation = "Salesperson/Purchaser";
        }
        field(70014; totalReçu; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = Sum("Recu Caisse Paiement".Montant WHERE("No Recu" = field(No), isDecaissement = filter(false)));
            Caption = 'Total réglement';
            Editable = false;
            FieldClass = FlowField;
        }

        field(70000; totalDepense; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = Sum("Recu Caisse Paiement".Montant WHERE("No Recu" = field(No), isDecaissement = filter(true)));
            Caption = 'Total Dépense';
            Editable = false;
            FieldClass = FlowField;
        }

        field(70001; totalRéglement; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = Sum("Recu Caisse Paiement"."Montant Calcul" WHERE("No Recu" = field(No)));
            Caption = 'Total Réglement';
            Editable = false;
            FieldClass = FlowField;
        }

        field(70015; totalDocToPay; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = Sum("Recu Caisse Document"."Montant Reglement" WHERE("No Recu" = field(No)));
            Caption = 'Total document payé';
            Editable = false;
            FieldClass = FlowField;
        }
        field(70016; isAcompte; Boolean)
        {
            DataClassification = ToBeClassified;
            trigger OnValidate()
            var
                recRecuCaisseDocument: Record "Recu Caisse Document";
            begin
                if xRec.isAcompte = false and Rec.isAcompte = true then begin
                    recRecuCaisseDocument.Reset();
                    recRecuCaisseDocument.SetRange("No Recu", Rec.No);
                    if recRecuCaisseDocument.Count > 1 then begin
                        Error('Vous ne pouvez pas activer Acompte car il y a plusieurs documents liés à ce reçu !');
                    end;
                end;
            end;
        }

        field(70017; Printed; Boolean)
        {
            DataClassification = ToBeClassified;
        }

        // Identifiant du brouillon Reapro a l'origine de ce recu. Il garantit qu'un meme
        // encaissement ne soit pas enregistre deux fois si la reponse n'arrive pas jusqu'a
        // Reapro : un second envoi du meme brouillon rend ce recu au lieu d'en creer un
        // autre. Vide pour les recus saisis dans Business Central.
        //
        // Ce champ reste modifiable : c'est lui que l'appel de creation renseigne, et c'est
        // son affectation qui declenche l'insertion cote Business Central. Declare non
        // modifiable, l'appel repondait un succes sans rien ecrire.
        field(70018; "Id Brouillon Reapro"; Code[50])
        {
            Caption = 'Identifiant brouillon Reapro';
        }

        // Le recu complet envoye par Reapro, conserve tel quel : sans lui, impossible de
        // savoir ce qui avait ete demande le jour ou un recu est conteste. Vide pour les
        // recus saisis dans Business Central.
        field(70019; "Contenu Reapro"; Blob)
        {
            Caption = 'Contenu envoyé par Reapro';
        }

    }

    keys
    {
        key(Key1; No)
        {
            Clustered = true;
        }
        key(Brouillon; "Id Brouillon Reapro")
        {
        }
    }

    fieldgroups
    {
        // Add changes to field groups here
    }

    var
        myInt: Integer;

    trigger OnInsert()
    var

    begin

    end;

    trigger OnModify()
    begin

    end;

    trigger OnDelete()
    var
    begin
        Error('Vous ne pouvez pas supprmier ce document !');
    end;

    trigger OnRename()
    begin

    end;

    procedure setPrinted(recRecuCaisse: Record "Recu Caisse")
    begin
        recRecuCaisse.Printed := true;
        recRecuCaisse.Modify();
        if GuiAllowed() then begin
            Message('Ticket %1 imprimé avec succées ********* ', recRecuCaisse.No);
        end;
    end;

    procedure EcrireContenuReapro(Texte: Text)
    var
        Flux: OutStream;
    begin
        Clear("Contenu Reapro");
        "Contenu Reapro".CreateOutStream(Flux, TextEncoding::UTF8);
        Flux.WriteText(Texte);
    end;

    procedure LireContenuReapro(): Text
    var
        Flux: InStream;
        Texte: Text;
    begin
        // Le blob peut deja porter sa valeur en memoire, juste apres avoir ete ecrit et
        // avant que la fiche ne soit relue : dans ce cas CalcFields l'ecraserait.
        if not "Contenu Reapro".HasValue() then
            CalcFields("Contenu Reapro");
        if not "Contenu Reapro".HasValue() then
            exit('');
        "Contenu Reapro".CreateInStream(Flux, TextEncoding::UTF8);
        Flux.ReadText(Texte);
        exit(Texte);
    end;

}