// Les factures vente non validees, et l'extraction des lignes d'expedition.
//
// CREER UN BROUILLON
//   POST /api/sopiq/interne/v1.0/companies({id})/SiFactureBrouillonAPI
//   { "customerNo": "41000845" }
//   -> la facture creee, avec son numero. La souche, les dates, le vendeur, le magasin et les
//      conditions viennent de la fiche client, comme le bouton « Nouveau ».
//
// LIRE
//   GET .../SiFactureBrouillonAPI?$filter=customerNo eq '41000845'
//
// EXTRAIRE DES LIGNES
//   POST .../SiFactureBrouillonAPI({systemId})/Microsoft.NAV.extraireLignes
//   { "lignes": "[{\"documentNo\":\"BL26-001631\",\"lineNo\":10000},
//                 {\"documentNo\":\"BL26-001631\",\"lineNo\":20000}]" }
//   -> { "value": "{\"ajoutees\":2,\"refusees\":[]}" }
//
//   C'est le traitement de Business Central qui ajoute les lignes, celui du bouton
//   « Extraire lignes expédition » : quantites a facturer, lien vers l'expedition, prix,
//   remises et lignes de commentaire sont les siens. Rien n'est recopie a la main ici.
//
//   Une ligne deja entierement facturee est refusee et nommee dans la reponse, le reste
//   passe. C'est ce qui arrive quand deux vendeurs extraient la meme ligne : le second
//   obtient un refus pour cette ligne, pas une erreur.
//
// Les lignes extractibles d'un client se lisent dans SiLigneExpeditionAExtraire.
page 25006956 "Si Facture Brouillon API"
{
    PageType = API;
    SourceTable = "Sales Header";
    SourceTableView = where("Document Type" = const(Invoice));
    APIPublisher = 'sopiq';
    APIGroup = 'interne';
    APIVersion = 'v1.0';
    EntityName = 'SiFactureBrouillonAPI';
    EntitySetName = 'SiFactureBrouillonAPI';
    ODataKeyFields = SystemId;
    DelayedInsert = true;
    Extensible = false;
    DeleteAllowed = false;

    Permissions = tabledata "Sales Header" = rim,
                  tabledata "Sales Line" = rimd,
                  tabledata "Sales Shipment Line" = rm;

    layout
    {
        area(Content)
        {
            repeater(Factures)
            {
                field(id; Rec.SystemId)
                {
                    Caption = 'SystemId', Locked = true;
                    Editable = false;
                }
                field(no; Rec."No.")
                {
                    Caption = 'N° facture';
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
        ClientManquantErr: Label 'Le client est obligatoire pour créer une facture.';
        LignesManquantesErr: Label 'Aucune ligne à extraire n''a été fournie.';
        LignesIllisiblesErr: Label 'La liste des lignes n''est pas un JSON valide.';

    trigger OnAfterGetRecord()
    begin
        Rec.CalcFields(Amount, "Amount Including VAT");
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        Facture: Record "Sales Header";
    begin
        if Rec."Sell-to Customer No." = '' then
            Error(ClientManquantErr);

        Facture.Init();
        Facture."Document Type" := Facture."Document Type"::Invoice;
        Facture."No." := '';
        Facture.Insert(true);

        Facture.Validate("Sell-to Customer No.", Rec."Sell-to Customer No.");

        if Rec."Document Date" <> 0D then
            Facture.Validate("Document Date", Rec."Document Date");
        if Rec."Posting Date" <> 0D then
            Facture.Validate("Posting Date", Rec."Posting Date");
        if Rec."Salesperson Code" <> '' then
            Facture.Validate("Salesperson Code", Rec."Salesperson Code");
        if Rec."Location Code" <> '' then
            Facture.Validate("Location Code", Rec."Location Code");

        Facture.custNameImprime := Rec.custNameImprime;
        Facture.custAdresseImprime := Rec.custAdresseImprime;
        Facture.custMFImprime := Rec.custMFImprime;
        Facture.custVINImprime := Rec.custVINImprime;

        Facture.Modify(true);

        Rec := Facture;
        exit(false);
    end;

    // Ajoute au brouillon les lignes d'expedition designees, par le traitement de Business
    // Central. Rend le nombre de lignes ajoutees et la liste de celles qui ont ete refusees.
    [ServiceEnabled]
    procedure extraireLignes(lignes: Text): Text
    var
        Facture: Record "Sales Header";
        LigneExpedition: Record "Sales Shipment Line";
        ExtraireExpedition: Codeunit "Sales-Get Shipment";
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

        Facture.Get(Rec."Document Type", Rec."No.");

        LigneExpedition.Reset();
        LigneExpedition.ClearMarks();

        foreach Jeton in Demandees do begin
            Ligne := Jeton.AsObject();

            NoDocument := '';
            NoLigne := 0;
            if Ligne.Get('documentNo', Valeur) then
                NoDocument := CopyStr(Valeur.AsValue().AsText(), 1, MaxStrLen(NoDocument));
            if Ligne.Get('lineNo', Valeur) then
                NoLigne := Valeur.AsValue().AsInteger();

            Clear(Refus);
            if not LigneExpedition.Get(NoDocument, NoLigne) then begin
                Refus.Add('documentNo', NoDocument);
                Refus.Add('lineNo', NoLigne);
                Refus.Add('motif', 'Ligne introuvable');
                Refusees.Add(Refus);
            end else
                if LigneExpedition."Qty. Shipped Not Invoiced" = 0 then begin
                    Refus.Add('documentNo', NoDocument);
                    Refus.Add('lineNo', NoLigne);
                    Refus.Add('motif', 'Ligne déjà entièrement facturée');
                    Refusees.Add(Refus);
                end else begin
                    LigneExpedition.Mark(true);
                    NbRetenues += 1;
                end;
        end;

        NbApres := 0;
        if NbRetenues > 0 then begin
            NbAvant := CompterLignes(Facture);
            LigneExpedition.MarkedOnly(true);
            ExtraireExpedition.SetSalesHeader(Facture);
            ExtraireExpedition.CreateInvLines(LigneExpedition);
            NbApres := CompterLignes(Facture) - NbAvant;
        end;

        Reponse.Add('factureNo', Facture."No.");
        Reponse.Add('ajoutees', NbApres);
        Reponse.Add('refusees', Refusees);
        Reponse.WriteTo(Texte);
        exit(Texte);
    end;

    local procedure CompterLignes(var Facture: Record "Sales Header"): Integer
    var
        LigneFacture: Record "Sales Line";
    begin
        LigneFacture.Reset();
        LigneFacture.SetRange("Document Type", Facture."Document Type");
        LigneFacture.SetRange("Document No.", Facture."No.");
        exit(LigneFacture.Count());
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
        Enregistre: Record "Sales Invoice Header";
        Reponse: JsonObject;
        Texte: Text;
        NoBrouillon: Code[20];
    begin
        Brouillon.Get(Rec."Document Type", Rec."No.");
        NoBrouillon := Brouillon."No.";

        Ligne.Reset();
        Ligne.SetRange("Document Type", Brouillon."Document Type");
        Ligne.SetRange("Document No.", Brouillon."No.");
        if Ligne.IsEmpty() then
            Error(RienAValiderErr, NoBrouillon);

        Brouillon.Ship := true;
        Brouillon.Invoice := true;
        Brouillon.Modify();

        Codeunit.Run(Codeunit::"Sales-Post", Brouillon);

        Enregistre.Reset();
        Enregistre.SetRange("Pre-Assigned No.", NoBrouillon);
        if not Enregistre.FindLast() then
            Error(PasEnregistreErr, NoBrouillon);

        Reponse.Add('brouillonNo', NoBrouillon);
        Reponse.Add('documentNo', Enregistre."No.");
        Reponse.WriteTo(Texte);
        exit(Texte);
    end;

}
