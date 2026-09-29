table 70012 "Recu Caisse Document"
{
    DataClassification = ToBeClassified;

    fields
    {
        field(70011; "Date Reçu"; Date)
        {
            CalcFormula = lookup("Recu Caisse".dateRecu where(No = field("No Recu")));
            Caption = 'Date Reçu';
            Editable = false;
            FieldClass = FlowField;
        }
        field(70012; "No Recu"; code[10])
        {
            DataClassification = ToBeClassified;
            TableRelation = "Recu Caisse";
        }
        field(70013; "Line No"; Integer)
        {
            DataClassification = ToBeClassified;
        }
        field(70014; type; Enum "Document Caisse Type")
        {
            DataClassification = ToBeClassified;
            trigger OnValidate()

            begin
                if xRec.type = type::null then "Line No" := incrementNo("No Recu");
            end;
        }

        field(70015; "Customer No"; code[20])
        {
            DataClassification = ToBeClassified;
            TableRelation = Customer;
        }

        field(70016; "Document No"; Code[20])
        {
            DataClassification = ToBeClassified;

        }

        field(70017; "Libelle"; Text[250])
        {
            DataClassification = ToBeClassified;
        }

        field(70019; "Total TTC"; Decimal)
        {
            DataClassification = ToBeClassified;
        }

        field(70020; "Montant Reglement"; Decimal)
        {
            DataClassification = ToBeClassified;
        }
        field(70021; "id Ligne Impaye"; integer)
        {
            DataClassification = ToBeClassified;
        }
        field(70022; solde; Boolean)
        {
            DataClassification = ToBeClassified;
        }

        // Les champs qui suivent ne servent qu'a l'API des documents a payer, qui utilise
        // cette table en mode temporaire : elle n'ecrit donc jamais ces valeurs en base, et
        // la fiche recu ne les affiche pas.
        //
        // Ils vivent ici plutot que dans une table dediee parce que la licence du client
        // plafonne les tables a 300 et que le compteur est plein. Ajouter un champ a une
        // table existante ne coute rien, creer une table est refuse a la publication.
        field(70030; "Date Document"; Date)
        {
            Caption = 'Date du document';
            DataClassification = ToBeClassified;
        }
        field(70031; "Reste A Payer"; Decimal)
        {
            Caption = 'Reste à payer';
            DecimalPlaces = 0 : 3;
            DataClassification = ToBeClassified;
        }
        // -1 pour un avoir ou un retour, qui viennent en deduction, 1 sinon.
        field(70032; Signe; Integer)
        {
            Caption = 'Signe';
            DataClassification = ToBeClassified;
        }
        field(70033; "Est Fournisseur"; Boolean)
        {
            Caption = 'Document fournisseur';
            DataClassification = ToBeClassified;
        }
        // Le nom du membre d'enumeration, pas son libelle traduit : c'est lui que l'appel de
        // creation attend en retour.
        field(70034; "Type Nom"; Text[30])
        {
            Caption = 'Nom du type';
            DataClassification = ToBeClassified;
        }

    }

    keys
    {
        key(Key1; "No Recu", "Line No")
        {
            Clustered = true;
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
        recRecuCaisse: Record "Recu Caisse";
    begin
        recRecuCaisse.Reset();
        recRecuCaisse.Get("No Recu");
        if recRecuCaisse.isAcompte = true then begin
            if rec."Line No" > 10000 then begin
                Error('Vous ne pouvez pas ajouter plus qu''un document à un reçu de type acompte !');
            end;
        end;


    end;

    trigger OnModify()
    begin

    end;

    trigger OnDelete()
    var
        recUserSetup: Record "User Setup";
        recuCaisse: Record "Recu Caisse";
        PeutModifier: Boolean;
    begin
        // Le compte utilise par l'API n'a pas forcement de fiche utilisateur : sans ce
        // test, Get plantait sur une erreur technique au lieu de refuser proprement.
        PeutModifier := false;
        if recUserSetup.Get(UserId) then
            PeutModifier := recUserSetup.isRCModify;

        recuCaisse.Reset();
        recuCaisse.get(rec."No Recu");
        if (not PeutModifier) AND (recuCaisse.Printed = true) then begin
            Error('Vous ne pouvez pas supprmier la ligne !');
        end

    end;

    trigger OnRename()
    begin

    end;

    procedure incrementNo("No Recu": code[20]): Integer
    var
        recRecuCaisseDoc: Record "Recu Caisse Document";
    begin

        recRecuCaisseDoc.SetRange("No Recu", "No Recu");
        if recRecuCaisseDoc.FindLast() then begin
            exit(recRecuCaisseDoc."Line No" + 10000);
        end
        else begin
            exit(10000);
        end;

    end;



}