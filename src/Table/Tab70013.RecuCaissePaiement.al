table 70013 "Recu Caisse Paiement"
{
    DataClassification = ToBeClassified;

    fields
    {
        field(70009; "Date Reçu"; Date)
        {
            CalcFormula = lookup("Recu Caisse".dateRecu where(No = field("No Recu")));
            Caption = 'Date Reçu';
            Editable = false;
            FieldClass = FlowField;
        }
        field(70010; "N° Client"; Code[20])
        {
            CalcFormula = lookup("Recu Caisse"."Customer No" where(No = field("No Recu")));
            Caption = 'Code Client';
            Editable = false;
            FieldClass = FlowField;
        }
        field(70011; "Nom Client"; text[100])
        {
            CalcFormula = lookup("Recu Caisse".custName where(No = field("No Recu")));
            Caption = 'Nom Client';
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
        field(70014; type; Enum "Paiment Caisse Type")
        {
            DataClassification = ToBeClassified;
            trigger OnValidate()

            begin
                if xRec.type = type::null then "Line No" := incrementNo("No Recu");
            end;
        }

        field(70015; "Name"; code[100])
        {
            DataClassification = ToBeClassified;
        }

        field(70016; "Paiment No"; Code[20])
        {
            DataClassification = ToBeClassified;
        }

        field(70017; "Montant"; Decimal)
        {
            DataClassification = ToBeClassified;
            trigger OnValidate()
            begin

                if xRec.type = type::null then "Line No" := incrementNo("No Recu");

            end;
        }

        field(70018; "Echeance"; date)
        {
            DataClassification = ToBeClassified;
        }

        field(70019; banque; Enum "Banque Caisse")
        {
            DataClassification = ToBeClassified;
        }

        field(70020; isDecaissement; Boolean)
        {
            DataClassification = ToBeClassified;
        }

        field(70021; "Montant Calcul"; Decimal)
        {
            DataClassification = ToBeClassified;
        }

        field(70022; "Text For Print"; Text[1000])
        {
            DataClassification = ToBeClassified;
        }

        field(70023; Impaye; Boolean)
        {
            DataClassification = ToBeClassified;
        }
        field(70024; "Date Impaye"; date)
        {
            DataClassification = ToBeClassified;
            Caption = 'Date Impayé';
        }
        field(70025; "Montant reçu caisse"; Decimal)
        {
            Caption = 'Montant reçu caisse';

            FieldClass = FlowField;
            CalcFormula = sum("Recu Caisse Document"."Montant Reglement" WHERE("Document No" = field("No Recu"), "id Ligne Impaye" = field("Line No")));
            Editable = false;
        }
        field(70026; solde; Boolean)
        {
            DataClassification = ToBeClassified;
            Caption = 'Solde';
        }
        field(70027; "Linked Invoice"; Code[20])
        {
            DataClassification = ToBeClassified;
            Caption = 'Facture Liée';
            TableRelation = "Sales Invoice Header"."No.";
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


    // Une ligne creee par l'API doit porter exactement les memes valeurs calculees qu'une
    // ligne saisie dans la fiche. Jusqu'au 28/09/2026, seul OnModify calculait "Montant
    // Calcul" : un paiement cree par l'API entrait dans les totaux du recu avec un montant
    // faux, et "isDecaissement" n'etait meme pas renseigne.
    trigger OnInsert()
    begin
        if type <> type::null then
            isDecaissement := setIsDeciassement(type);

        // Seulement si l'appelant ne l'a pas pose lui-meme. La page 50132 cree la ligne
        // Complement avec un "Montant Calcul" de signe oppose au montant, volontairement :
        // un calcul systematique inverserait ce cas et fausserait le total du recu.
        if "Montant Calcul" = 0 then
            if isDecaissement then
                "Montant Calcul" := -Montant
            else
                "Montant Calcul" := Montant;
    end;

    trigger OnModify()
    begin
        //"Text For Print" := Format(type) + ' ' + Format("Paiment No") + ' ' + Format(Name) + ' ' + Format(Echeance) + ' ' + Format(Montant, 12, 3);
        if isDecaissement = true then
            "Montant Calcul" := -Montant
        else
            "Montant Calcul" := Montant;
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
        recRecuCaisseDoc: Record "Recu Caisse Paiement";
    begin

        recRecuCaisseDoc.SetRange("No Recu", "No Recu");
        if recRecuCaisseDoc.FindLast() then begin
            exit(recRecuCaisseDoc."Line No" + 10000);
        end
        else begin
            exit(10000);
        end;

    end;

    procedure setIsDeciassement(typePaiement: Enum "Paiment Caisse Type"): Boolean
    begin
        if (typePaiement = typePaiement::"AvoirEsp") OR (typePaiement = typePaiement::"Depense") OR (typePaiement = typePaiement::"retourBS") OR (typePaiement = typePaiement::"Transport") OR (typePaiement = typePaiement::"ResteCheque")
        OR (typePaiement = typePaiement::DecCheq) OR (typePaiement = typePaiement::DecEsp) OR (typePaiement = typePaiement::DecTrt) OR (typePaiement = typePaiement::DecVers) OR (typePaiement = typePaiement::DecVir) then
            exit(true)
        else
            exit(false);
    end;


}