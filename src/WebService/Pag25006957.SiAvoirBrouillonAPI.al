// Les avoirs vente non valides, et l'extraction des lignes de reception retour.
//
// CREER UN BROUILLON
//   POST /api/sopiq/interne/v1.0/companies({id})/SiAvoirBrouillonAPI
//   { "customerNo": "41000845" }
//
// LIRE
//   GET .../SiAvoirBrouillonAPI?$filter=customerNo eq '41000845'
//
// EXTRAIRE DES LIGNES
//   POST .../SiAvoirBrouillonAPI({systemId})/Microsoft.NAV.extraireLignes
//   { "lignes": "[{\"documentNo\":\"R+BS26-0012\",\"lineNo\":10000}]" }
//   -> { "value": "{\"avoirNo\":\"AV26-0034\",\"ajoutees\":1,\"refusees\":[]}" }
//
//   C'est le traitement de Business Central qui ajoute les lignes, celui du bouton
//   « Extraire lignes réception retour ».
//
// Les lignes extractibles d'un client se lisent dans SiLigneRetourAExtraire.
page 25006957 "Si Avoir Brouillon API"
{
    PageType = API;
    SourceTable = "Sales Header";
    SourceTableView = where("Document Type" = const("Credit Memo"));
    APIPublisher = 'sopiq';
    APIGroup = 'interne';
    APIVersion = 'v1.0';
    EntityName = 'SiAvoirBrouillonAPI';
    EntitySetName = 'SiAvoirBrouillonAPI';
    ODataKeyFields = SystemId;
    DelayedInsert = true;
    Extensible = false;
    DeleteAllowed = false;

    Permissions = tabledata "Sales Header" = rim,
                  tabledata "Sales Line" = rimd,
                  tabledata "Return Receipt Line" = rm;

    layout
    {
        area(Content)
        {
            repeater(Avoirs)
            {
                field(id; Rec.SystemId)
                {
                    Caption = 'SystemId', Locked = true;
                    Editable = false;
                }
                field(no; Rec."No.")
                {
                    Caption = 'N° avoir';
                    Editable = false;
                }
                field(customerNo; Rec."Sell-to Customer No.")
                {
                    Caption = 'Client';
                }
                field(billToCustomerNo; Rec."Bill-to Customer No.")
                {
                    Caption = 'Client facturé';
                    Editable = false;
                }
                field(customerName; Rec."Sell-to Customer Name")
                {
                    Caption = 'Nom client';
                    Editable = false;
                }
                field(documentDate; Rec."Document Date")
                {
                    Caption = 'Date';
                }
                field(postingDate; Rec."Posting Date")
                {
                    Caption = 'Date comptabilisation';
                }
                field(salespersonCode; Rec."Salesperson Code")
                {
                    Caption = 'Vendeur';
                }
                field(locationCode; Rec."Location Code")
                {
                    Caption = 'Magasin';
                }
                field(amount; Rec.Amount)
                {
                    Caption = 'Montant HT';
                    Editable = false;
                }
                field(amountIncludingVAT; Rec."Amount Including VAT")
                {
                    Caption = 'Montant TTC';
                    Editable = false;
                }
                field(custPrintName; Rec.custNameImprime)
                {
                    Caption = 'Nom client à imprimer';
                }
                field(custPrintAdress; Rec.custAdresseImprime)
                {
                    Caption = 'Adresse client à imprimer';
                }
                field(custPrintMF; Rec.custMFImprime)
                {
                    Caption = 'Matricule fiscal à imprimer';
                }
                field(custPrintVIN; Rec.custVINImprime)
                {
                    Caption = 'VIN à imprimer';
                }
            }
        }
    }

    var
        ClientManquantErr: Label 'Le client est obligatoire pour créer un avoir.';
        LignesManquantesErr: Label 'Aucune ligne à extraire n''a été fournie.';
        LignesIllisiblesErr: Label 'La liste des lignes n''est pas un JSON valide.';

    trigger OnAfterGetRecord()
    begin
        Rec.CalcFields(Amount, "Amount Including VAT");
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        Avoir: Record "Sales Header";
    begin
        if Rec."Sell-to Customer No." = '' then
            Error(ClientManquantErr);

        Avoir.Init();
        Avoir."Document Type" := Avoir."Document Type"::"Credit Memo";
        Avoir."No." := '';
        Avoir.Insert(true);

        Avoir.Validate("Sell-to Customer No.", Rec."Sell-to Customer No.");

        if Rec."Document Date" <> 0D then
            Avoir.Validate("Document Date", Rec."Document Date");
        if Rec."Posting Date" <> 0D then
            Avoir.Validate("Posting Date", Rec."Posting Date");
        if Rec."Salesperson Code" <> '' then
            Avoir.Validate("Salesperson Code", Rec."Salesperson Code");
        if Rec."Location Code" <> '' then
            Avoir.Validate("Location Code", Rec."Location Code");

        Avoir.custNameImprime := Rec.custNameImprime;
        Avoir.custAdresseImprime := Rec.custAdresseImprime;
        Avoir.custMFImprime := Rec.custMFImprime;
        Avoir.custVINImprime := Rec.custVINImprime;

        Avoir.Modify(true);

        Rec := Avoir;
        exit(false);
    end;

    [ServiceEnabled]
    procedure extraireLignes(lignes: Text): Text
    var
        Avoir: Record "Sales Header";
        LigneReception: Record "Return Receipt Line";
        ExtraireRetour: Codeunit "Sales-Get Return Receipts";
        Demandees: JsonArray;
        Jeton: JsonToken;
        Ligne: JsonObject;
        Valeur: JsonToken;
        Refusees: JsonArray;
        Refus: JsonObject;
        Reponse: JsonObject;
        Texte: Text;
        NoDocument: Code[20];
        NoLigne: Integer;
        NbRetenues: Integer;
        NbAvant: Integer;
        NbApres: Integer;
    begin
        if lignes = '' then
            Error(LignesManquantesErr);
        if not Demandees.ReadFrom(lignes) then
            Error(LignesIllisiblesErr);
        if Demandees.Count() = 0 then
            Error(LignesManquantesErr);

        Avoir.Get(Rec."Document Type", Rec."No.");

        LigneReception.Reset();
        LigneReception.ClearMarks();

        foreach Jeton in Demandees do begin
            Ligne := Jeton.AsObject();

            NoDocument := '';
            NoLigne := 0;
            if Ligne.Get('documentNo', Valeur) then
                NoDocument := CopyStr(Valeur.AsValue().AsText(), 1, MaxStrLen(NoDocument));
            if Ligne.Get('lineNo', Valeur) then
                NoLigne := Valeur.AsValue().AsInteger();

            Clear(Refus);
            if not LigneReception.Get(NoDocument, NoLigne) then begin
                Refus.Add('documentNo', NoDocument);
                Refus.Add('lineNo', NoLigne);
                Refus.Add('motif', 'Ligne introuvable');
                Refusees.Add(Refus);
            end else
                if LigneReception."Return Qty. Rcd. Not Invd." = 0 then begin
                    Refus.Add('documentNo', NoDocument);
                    Refus.Add('lineNo', NoLigne);
                    Refus.Add('motif', 'Ligne déjà entièrement facturée');
                    Refusees.Add(Refus);
                end else begin
                    LigneReception.Mark(true);
                    NbRetenues += 1;
                end;
        end;

        NbApres := 0;
        if NbRetenues > 0 then begin
            NbAvant := CompterLignes(Avoir);
            LigneReception.MarkedOnly(true);
            ExtraireRetour.SetSalesHeader(Avoir);
            ExtraireRetour.CreateInvLines(LigneReception);
            NbApres := CompterLignes(Avoir) - NbAvant;
        end;

        Reponse.Add('avoirNo', Avoir."No.");
        Reponse.Add('ajoutees', NbApres);
        Reponse.Add('refusees', Refusees);
        Reponse.WriteTo(Texte);
        exit(Texte);
    end;

    local procedure CompterLignes(var Avoir: Record "Sales Header"): Integer
    var
        LigneAvoir: Record "Sales Line";
    begin
        LigneAvoir.Reset();
        LigneAvoir.SetRange("Document Type", Avoir."Document Type");
        LigneAvoir.SetRange("Document No.", Avoir."No.");
        exit(LigneAvoir.Count());
    end;

    var
        RienAValiderErr: Label 'Le document %1 n''a aucune ligne : il n''y a rien à valider.', Comment = '%1 = numéro du document';
        PasEnregistreErr: Label 'Le document %1 a été traité mais le document enregistré est introuvable.', Comment = '%1 = numéro du brouillon';

    // Valide le brouillon par le traitement de Business Central, celui du bouton
    // « Valider » de la fiche. Rend le numero du document enregistre.
    //
    // Tout refus de Business Central remonte tel quel a l'appelant, et rien n'est valide :
    // periode fermee, client bloque, ligne sans quantite, credit depasse. Le brouillon reste
    // alors exactement tel qu'il etait.
    [ServiceEnabled]
    procedure valider(): Text
    var
        Brouillon: Record "Sales Header";
        Ligne: Record "Sales Line";
        Enregistre: Record "Sales Cr.Memo Header";
        Reponse: JsonObject;
        Texte: Text;
        EchecSignale: Text;
        NoBrouillon: Code[20];
    begin
        Brouillon.Get(Rec."Document Type", Rec."No.");
        NoBrouillon := Brouillon."No.";

        Ligne.Reset();
        Ligne.SetRange("Document Type", Brouillon."Document Type");
        Ligne.SetRange("Document No.", Brouillon."No.");
        if Ligne.IsEmpty() then
            Error(RienAValiderErr, NoBrouillon);

        Brouillon.Receive := true;
        Brouillon.Invoice := true;
        Brouillon.Modify();

        // La modification du brouillon est validee avant d'enregistrer : c'est la condition pour
        // pouvoir piloter l'erreur de l'enregistrement au lieu de la subir.
        Commit();

        // Enregistrement tolerant a l'echec d'affichage. En appel API, du code tente d'ouvrir la
        // page du document enregistre juste apres l'enregistrement : sans interface, cela leve une
        // erreur alors que le document est deja enregistre et valide. On juge donc l'enregistrement
        // sur ce que montre la base, pas sur le retour de l'appel.
        if not Codeunit.Run(Codeunit::"Sales-Post", Brouillon) then
            EchecSignale := GetLastErrorText();

        Enregistre.Reset();
        Enregistre.SetRange("Pre-Assigned No.", NoBrouillon);
        if not Enregistre.FindLast() then begin
            // Rien en base : l'echec est un vrai refus d'enregistrement, on le remonte tel quel.
            if EchecSignale <> '' then
                Error(EchecSignale);
            Error(PasEnregistreErr, NoBrouillon);
        end;

        Reponse.Add('brouillonNo', NoBrouillon);
        Reponse.Add('documentNo', Enregistre."No.");
        if EchecSignale <> '' then
            Reponse.Add('avertissement', EchecSignale);
        Reponse.WriteTo(Texte);
        exit(Texte);
    end;

}
