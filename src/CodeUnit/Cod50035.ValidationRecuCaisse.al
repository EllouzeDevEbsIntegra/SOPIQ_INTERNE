// Validation d'un recu de caisse, et creation d'un recu complet en un seul appel.
//
// Pourquoi ce codeunit. Jusqu'ici, valider un recu n'existait que dans le bouton Imprimer
// de la page 50132 : proposition Remise ou Complement, report du montant sur l'acompte,
// passage des documents en solde, controle du code vendeur. Par l'API, rien de tout cela ne
// s'executait : un recu cree par Reapro existait, mais ses documents restaient dans les
// impayes du client.
//
// La regle vit desormais ici, et les deux mondes l'appellent :
//   - la page garde ses questions a l'ecran, cree la ligne Remise ou Complement, puis
//     appelle ValiderRecu ;
//   - l'API appelle ValiderRecu directement. Aucune question, aucune ligne ajoutee : si les
//     totaux different et que le recu n'est pas un acompte, le traitement refuse.
//
// Ce codeunit ne fait aucun Commit : l'appel API doit rester tout ou rien. La page, elle,
// garde les siens la ou ils etaient.
codeunit 50035 "Validation Recu Caisse"
{
    Permissions = tabledata "Sales Invoice Header" = rm,
                  tabledata "Entete archive BS" = rm,
                  tabledata "Sales Cr.Memo Header" = rm,
                  tabledata "Return Receipt Header" = rm,
                  tabledata "Sales Shipment Header" = rm,
                  tabledata "Purch. Cr. Memo Hdr." = rm,
                  tabledata "Purch. Inv. Header" = rm,
                  tabledata "Recu Caisse" = rimd,
                  tabledata "Recu Caisse Document" = rimd,
                  tabledata "Recu Caisse Paiement" = rimd;

    var
        VendeurErr: Label 'Vous devez sélectionner le code vendeur !';
        EcartErr: Label 'Le total des règlements (%1) ne correspond pas au total des documents (%2). Écart de %3. Ajoutez une ligne Remise ou Complément, ou marquez le reçu comme acompte.', Comment = '%1 total règlements, %2 total documents, %3 écart';
        BrouillonDejaTraiteInfo: Label 'Ce brouillon a déjà été traité : le reçu %1 existe. Relisez-le avec un filtre sur l''identifiant de brouillon.', Comment = '%1 numéro de reçu';
        BrouillonManquantErr: Label 'L''identifiant de brouillon est obligatoire.';
        ClientInconnuErr: Label 'Le client %1 n''existe pas.', Comment = '%1 numéro client';
        PayloadErr: Label 'Le contenu envoyé n''est pas un JSON valide.';
        AucunDocumentErr: Label 'Le reçu doit comporter au moins un document.';
        AucunPaiementErr: Label 'Le reçu doit comporter au moins un paiement.';
        TypeInconnuErr: Label 'Valeur %1 inconnue pour %2.', Comment = '%1 valeur reçue, %2 nom du champ';

    // =================================================================
    // 1. VALIDATION
    // =================================================================

    // ModeInteractif : appele depuis la page, qui a deja pose ses questions et cree la
    // ligne d'ecart si l'utilisateur l'a acceptee. Le controle d'ecart n'est alors plus
    // qu'un filet.
    procedure ValiderRecu(var RecuCaisse: Record "Recu Caisse"; ModeInteractif: Boolean)
    var
        RecuDocument: Record "Recu Caisse Document";
    begin
        if RecuCaisse.user = '' then
            Error(VendeurErr);

        RecuCaisse.CalcFields(totalDocToPay, "totalRéglement");

        if (RecuCaisse.totalDocToPay <> RecuCaisse."totalRéglement") and (not RecuCaisse.isAcompte) then
            Error(EcartErr,
                  RecuCaisse."totalRéglement", RecuCaisse.totalDocToPay,
                  RecuCaisse."totalRéglement" - RecuCaisse.totalDocToPay);

        // Acompte : le montant du document suit ce qui a ete regle, comme dans la page.
        if RecuCaisse.isAcompte then begin
            RecuDocument.Reset();
            RecuDocument.SetRange("No Recu", RecuCaisse.No);
            if RecuDocument.FindFirst() then begin
                RecuDocument."Montant Reglement" := RecuCaisse."totalRéglement";
                RecuDocument.Modify();
            end;
        end;

        MarquerDocumentsSoldes(RecuCaisse);

        // Jusqu'au 28/09/2026, "Printed" etait pose par le rapport, dans son OnPostReport.
        // Une validation sans impression ne marquait donc rien, et produire un PDF
        // modifiait la donnee. C'est la validation qui en repond desormais.
        RecuCaisse.Printed := true;
        RecuCaisse.Modify();
    end;

    // Reprise a l'identique de la procedure setDocumentSolde de la page 50132, sans les
    // Commit intermediaires : l'appel API doit pouvoir etre annule entierement.
    procedure MarquerDocumentsSoldes(var RecuCaisse: Record "Recu Caisse")
    var
        RecuDocument: Record "Recu Caisse Document";
        ArchiveBS: Record "Entete archive BS";
        SalesInvoice: Record "Sales Invoice Header";
        SalesCrMemo: Record "Sales Cr.Memo Header";
        ReturnReceipt: Record "Return Receipt Header";
        SalesShipment: Record "Sales Shipment Header";
        PurchInvoice: Record "Purch. Inv. Header";
        PurchCrMemo: Record "Purch. Cr. Memo Hdr.";
        RecuPaiement: Record "Recu Caisse Paiement";
    begin
        RecuDocument.Reset();
        RecuDocument.SetRange("No Recu", RecuCaisse.No);
        if not RecuDocument.FindSet() then
            exit;

        repeat
            case RecuDocument.type of
                "Document Caisse Type"::BS:
                    if ArchiveBS.Get(RecuDocument."Document No") then begin
                        ArchiveBS.CalcFields("Montant TTC", "Montant reçu caisse");
                        ArchiveBS.Solde := ArchiveBS."Montant TTC" = ArchiveBS."Montant reçu caisse";
                        ArchiveBS.Modify();
                    end;
                "Document Caisse Type"::Invoice:
                    if SalesInvoice.Get(RecuDocument."Document No") then begin
                        SalesInvoice.CalcFields("Amount Including VAT", "Montant reçu caisse");
                        SalesInvoice.Solde :=
                            SalesInvoice."Amount Including VAT" + SalesInvoice."STStamp Amount"
                            = SalesInvoice."Montant reçu caisse";
                        SalesInvoice.Modify();
                    end;
                "Document Caisse Type"::CreditMemo:
                    if SalesCrMemo.Get(RecuDocument."Document No") then begin
                        SalesCrMemo.CalcFields("Amount Including VAT", "Montant reçu caisse");
                        SalesCrMemo.Solde :=
                            SalesCrMemo."Amount Including VAT" = -SalesCrMemo."Montant reçu caisse";
                        SalesCrMemo.Modify();
                    end;
                "Document Caisse Type"::RetourBS,
                "Document Caisse Type"::RetourBL:
                    if ReturnReceipt.Get(RecuDocument."Document No") then begin
                        ReturnReceipt.CalcFields("Line Amount", "Montant reçu caisse");
                        ReturnReceipt.Solde :=
                            ReturnReceipt."Line Amount" = -ReturnReceipt."Montant reçu caisse";
                        ReturnReceipt.Modify();
                    end;
                "Document Caisse Type"::BL:
                    if SalesShipment.Get(RecuDocument."Document No") then begin
                        SalesShipment.CalcFields("Line Amount", "Montant reçu caisse");
                        SalesShipment.Solde :=
                            SalesShipment."Line Amount" = SalesShipment."Montant reçu caisse";
                        SalesShipment.Modify();
                    end;
                "Document Caisse Type"::FA:
                    if PurchInvoice.Get(RecuDocument."Document No") then begin
                        PurchInvoice.CalcFields("Amount Including VAT", "Montant reçu caisse");
                        PurchInvoice.Solde :=
                            PurchInvoice."Amount Including VAT" + PurchInvoice."STStamp Fiscal Amount"
                            = -PurchInvoice."Montant reçu caisse";
                        PurchInvoice.Modify();
                    end;
                "Document Caisse Type"::AVA:
                    if PurchCrMemo.Get(RecuDocument."Document No") then begin
                        PurchCrMemo.CalcFields("Amount Including VAT", "Montant reçu caisse");
                        PurchCrMemo.Solde :=
                            PurchCrMemo."Amount Including VAT" = PurchCrMemo."Montant reçu caisse";
                        PurchCrMemo.Modify();
                    end;
                "Document Caisse Type"::Impaye:
                    begin
                        RecuPaiement.Reset();
                        RecuPaiement.SetRange("No Recu", RecuDocument."Document No");
                        RecuPaiement.SetRange("Line No", RecuDocument."id Ligne Impaye");
                        if RecuPaiement.FindFirst() then begin
                            RecuPaiement.CalcFields("Montant reçu caisse");
                            RecuPaiement.solde := RecuPaiement.Montant = RecuPaiement."Montant reçu caisse";
                            RecuPaiement.Modify();
                        end;
                    end;
                else begin
                    RecuDocument.Solde := false;
                    RecuDocument.Modify();
                end;
            end;
        until RecuDocument.Next() = 0;
    end;

    // =================================================================
    // 2. CREATION COMPLETE EN UN SEUL APPEL
    // =================================================================

    // Recoit le recu entier et le cree, puis le valide. Tout se joue dans la transaction de
    // l'appel : si quoi que ce soit echoue, rien n'est ecrit et le numero de recu n'est pas
    // consomme.
    //
    // L'en-tete passe en parametre est celui que la page API s'apprete a inserer : on le
    // remplit ici, on cree ses lignes, puis on valide. Il n'y a pas de table tampon, la
    // licence du client ne permettant plus d'en creer.
    //
    // Idempotence : l'identifiant de brouillon fourni par Reapro est enregistre sur
    // l'en-tete. Un second envoi du meme brouillon est refuse, en nommant le recu deja cree ;
    // Reapro le retrouve par un GET filtre sur cet identifiant.
    procedure CreerEtValider(var RecuCaisse: Record "Recu Caisse"; IdBrouillon: Code[50]; Payload: Text)
    var
        RecuExistant: Record "Recu Caisse";
        Racine: JsonObject;
    begin
        if IdBrouillon = '' then
            Error(BrouillonManquantErr);

        RecuExistant.Reset();
        RecuExistant.SetRange("Id Brouillon Reapro", IdBrouillon);
        if RecuExistant.FindFirst() then
            Error(BrouillonDejaTraiteInfo, RecuExistant.No);

        if not Racine.ReadFrom(Payload) then
            Error(PayloadErr);

        RemplirEntete(Racine, IdBrouillon, Payload, RecuCaisse);
        CreerDocuments(Racine, RecuCaisse);
        CreerPaiements(Racine, RecuCaisse);

        ValiderRecu(RecuCaisse, false);
    end;

    local procedure RemplirEntete(Racine: JsonObject; IdBrouillon: Code[50]; Payload: Text; var RecuCaisse: Record "Recu Caisse")
    var
        Client: Record Customer;
        SalesSetup: Record "Sales & Receivables Setup";
        NoSeriesMgt: Codeunit NoSeriesManagement;
        ClientNo: Code[20];
    begin
        ClientNo := CopyStr(LireTexte(Racine, 'customerNo'), 1, MaxStrLen(ClientNo));
        if not Client.Get(ClientNo) then
            Error(ClientInconnuErr, ClientNo);

        SalesSetup.Get();

        RecuCaisse.Init();
        RecuCaisse.dateRecu := LireDate(Racine, 'dateRecu', Today());
        RecuCaisse.dateTime := CurrentDateTime();
        RecuCaisse.No := NoSeriesMgt.GetNextNo(SalesSetup."Reçu Caisse Serie", RecuCaisse.dateRecu, true);
        RecuCaisse."Customer No" := ClientNo;
        if Client."Name 2" <> '' then
            RecuCaisse.custName := Client."Name 2"
        else
            RecuCaisse.custName := Client.Name;
        RecuCaisse.user := CopyStr(LireTexte(Racine, 'codeVendeur'), 1, MaxStrLen(RecuCaisse.user));
        RecuCaisse.isAcompte := LireBooleen(Racine, 'isAcompte');
        RecuCaisse."Id Brouillon Reapro" := IdBrouillon;
        RecuCaisse.Printed := false;
        RecuCaisse.Insert();

        // Le contenu envoye est conserve sur l'en-tete : sans lui, impossible de savoir ce
        // qui avait ete demande le jour ou un recu est conteste.
        RecuCaisse.EcrireContenuReapro(Payload);
        RecuCaisse.Modify();
    end;

    local procedure CreerDocuments(Racine: JsonObject; var RecuCaisse: Record "Recu Caisse")
    var
        RecuDocument: Record "Recu Caisse Document";
        Lignes: JsonArray;
        Jeton: JsonToken;
        Ligne: JsonObject;
        NoLigne: Integer;
        TypeDocument: Enum "Document Caisse Type";
    begin
        Lignes := LireTableau(Racine, 'documents');
        if Lignes.Count() = 0 then
            Error(AucunDocumentErr);

        NoLigne := 0;
        foreach Jeton in Lignes do begin
            Ligne := Jeton.AsObject();
            NoLigne += 10000;

            Evaluer(LireTexte(Ligne, 'type'), 'type document', TypeDocument);

            RecuDocument.Init();
            RecuDocument."No Recu" := RecuCaisse.No;
            RecuDocument."Line No" := NoLigne;
            RecuDocument.type := TypeDocument;
            RecuDocument."Customer No" := RecuCaisse."Customer No";
            RecuDocument."Document No" := CopyStr(LireTexte(Ligne, 'documentNo'), 1, MaxStrLen(RecuDocument."Document No"));
            RecuDocument.Libelle := CopyStr(LireTexte(Ligne, 'libelle'), 1, MaxStrLen(RecuDocument.Libelle));
            RecuDocument."Total TTC" := LireDecimal(Ligne, 'totalTTC');
            RecuDocument."Montant Reglement" := LireDecimal(Ligne, 'montantReglement');
            RecuDocument."id Ligne Impaye" := LireEntier(Ligne, 'idLigneImpaye');
            RecuDocument.Insert();
        end;
    end;

    local procedure CreerPaiements(Racine: JsonObject; var RecuCaisse: Record "Recu Caisse")
    var
        RecuPaiement: Record "Recu Caisse Paiement";
        Lignes: JsonArray;
        Jeton: JsonToken;
        Ligne: JsonObject;
        NoLigne: Integer;
        TypePaiement: Enum "Paiment Caisse Type";
        TypeBanque: Enum "Banque Caisse";
        TexteBanque: Text;
    begin
        Lignes := LireTableau(Racine, 'paiements');
        if Lignes.Count() = 0 then
            Error(AucunPaiementErr);

        NoLigne := 0;
        foreach Jeton in Lignes do begin
            Ligne := Jeton.AsObject();
            NoLigne += 10000;

            Evaluer(LireTexte(Ligne, 'type'), 'type paiement', TypePaiement);

            RecuPaiement.Init();
            RecuPaiement."No Recu" := RecuCaisse.No;
            RecuPaiement."Line No" := NoLigne;
            RecuPaiement.type := TypePaiement;
            RecuPaiement.Name := CopyStr(LireTexte(Ligne, 'name'), 1, MaxStrLen(RecuPaiement.Name));
            RecuPaiement."Paiment No" := CopyStr(LireTexte(Ligne, 'paiementNo'), 1, MaxStrLen(RecuPaiement."Paiment No"));
            RecuPaiement.Montant := LireDecimal(Ligne, 'montant');
            RecuPaiement.Echeance := LireDate(Ligne, 'echeance', 0D);

            TexteBanque := LireTexte(Ligne, 'banque');
            if TexteBanque <> '' then begin
                Evaluer(TexteBanque, 'banque', TypeBanque);
                RecuPaiement.banque := TypeBanque;
            end;

            // Le sens et le montant signe sont deduits du type, jamais recus de l'exterieur :
            // c'est le OnInsert de la table qui s'en charge.
            //
            // Une exception, celle de la fiche : la ligne Complement porte un "Montant
            // Calcul" negatif alors que son montant est positif, et le type Complement
            // n'est pas range parmi les decaissements. Sans ce report, un recu equilibre
            // par un complement serait refuse comme desequilibre.
            if TypePaiement = TypePaiement::Complement then
                RecuPaiement."Montant Calcul" := -RecuPaiement.Montant;

            RecuPaiement.Insert();
        end;
    end;

    // =================================================================
    // 3. LECTURE DU JSON
    // =================================================================

    local procedure LireTexte(Objet: JsonObject; Nom: Text): Text
    var
        Jeton: JsonToken;
    begin
        if not Objet.Get(Nom, Jeton) then
            exit('');
        if Jeton.AsValue().IsNull() then
            exit('');
        exit(Jeton.AsValue().AsText());
    end;

    local procedure LireDecimal(Objet: JsonObject; Nom: Text): Decimal
    var
        Jeton: JsonToken;
    begin
        if not Objet.Get(Nom, Jeton) then
            exit(0);
        if Jeton.AsValue().IsNull() then
            exit(0);
        exit(Jeton.AsValue().AsDecimal());
    end;

    local procedure LireEntier(Objet: JsonObject; Nom: Text): Integer
    var
        Jeton: JsonToken;
    begin
        if not Objet.Get(Nom, Jeton) then
            exit(0);
        if Jeton.AsValue().IsNull() then
            exit(0);
        exit(Jeton.AsValue().AsInteger());
    end;

    local procedure LireBooleen(Objet: JsonObject; Nom: Text): Boolean
    var
        Jeton: JsonToken;
    begin
        if not Objet.Get(Nom, Jeton) then
            exit(false);
        if Jeton.AsValue().IsNull() then
            exit(false);
        exit(Jeton.AsValue().AsBoolean());
    end;

    local procedure LireDate(Objet: JsonObject; Nom: Text; ParDefaut: Date): Date
    var
        Jeton: JsonToken;
        Texte: Text;
        Resultat: Date;
    begin
        Texte := LireTexte(Objet, Nom);
        if Texte = '' then
            exit(ParDefaut);
        if Evaluate(Resultat, Texte, 9) then
            exit(Resultat);
        if Evaluate(Resultat, Texte) then
            exit(Resultat);
        exit(ParDefaut);
    end;

    local procedure LireTableau(Objet: JsonObject; Nom: Text): JsonArray
    var
        Jeton: JsonToken;
        Vide: JsonArray;
    begin
        if not Objet.Get(Nom, Jeton) then
            exit(Vide);
        if not Jeton.IsArray() then
            exit(Vide);
        exit(Jeton.AsArray());
    end;

    // Accepte le nom du membre ou son numero, et refuse clairement le reste.
    local procedure Evaluer(Valeur: Text; NomChamp: Text; var TypeDocument: Enum "Document Caisse Type")
    begin
        if not Evaluate(TypeDocument, Valeur) then
            Error(TypeInconnuErr, Valeur, NomChamp);
    end;

    local procedure Evaluer(Valeur: Text; NomChamp: Text; var TypePaiement: Enum "Paiment Caisse Type")
    begin
        if not Evaluate(TypePaiement, Valeur) then
            Error(TypeInconnuErr, Valeur, NomChamp);
    end;

    local procedure Evaluer(Valeur: Text; NomChamp: Text; var TypeBanque: Enum "Banque Caisse")
    begin
        if not Evaluate(TypeBanque, Valeur) then
            Error(TypeInconnuErr, Valeur, NomChamp);
    end;
}
