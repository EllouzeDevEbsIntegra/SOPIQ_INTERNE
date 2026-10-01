// Le panier des bons de sortie a facturer, celui de la page « Panier BS à facturer » (50140).
//
// CE QU'EST LE PANIER. Ce ne sont pas des lignes dans une table a part : ce sont les lignes
// d'expedition des bons de sortie qui remplissent quatre conditions, exactement celles de la
// page du comptoir :
//   - l'expedition est un bon de sortie ;
//   - la ligne n'est pas encore facturee ;
//   - une quantite a facturer y a ete posee ;
//   - la ligne n'est pas masquee.
// Une ligne entre dans le panier quand sa quantite a facturer devient positive, et en sort
// quand elle est facturee ou masquee.
//
// LIRE LE PANIER D'UN CLIENT
//   GET /api/sopiq/interne/v1.0/companies({id})/SiPanierBsAPI
//       ?$filter=billToCustomerNo eq '41000845'
//
// CHOISIR DES LIGNES
//   PATCH .../SiPanierBsAPI({systemId})   { "selectedLine": true }
//
//   C'est la coche de la page. La selection est portee par la ligne elle-meme, elle survit
//   donc a la fermeture de l'ecran et elle est partagee : deux vendeurs qui preparent le
//   meme client se voient l'un l'autre. C'est ainsi que fonctionne le comptoir, je n'y
//   change rien.
//
// AJUSTER CE QUI SERA FACTURE
//   PATCH .../SiPanierBsAPI({systemId})   { "qtyBsToInvoice": 2, "keepInitPrices": true }
//
//   Une quantite a facturer ramenee a zero fait sortir la ligne du panier.
//
// TRANSFORMER EN BON DE LIVRAISON
//   POST .../SiPanierBsAPI({systemId})/Microsoft.NAV.transformerEnBL
//   { "customerNo": "41000010",
//     "lignes": "[{\"documentNo\":\"BS26-5025\",\"lineNo\":10000}]" }
//
//   C'est l'etat 50003 « TransfertBStoBL » de l'extension du verticalisateur qui travaille,
//   le meme que le bouton de la page 50140. Le garde-fou des prix, codeunit 50033, reste en
//   place puisqu'il s'applique a la validation.
//
//   Les lignes transformees sont exactement celles que l'appel designe, et elles sont
//   passees par un filtre sur leur identifiant : les coches laissees par un autre vendeur
//   dans la base ne sont ni lues ni touchees.
//
//   accepterAutreClient a faux, le defaut, refuse les lignes qui ne sont pas au client
//   annonce. A vrai, elles sont confiees a l'etat malgre tout : c'est le cas du bon de
//   sortie fait au client de passage et facture a un client en compte. Ce que l'etat fait
//   alors du client reste a eprouver, voir la reponse du 01/10/2026.
page 25006958 "Si Panier BS API"
{
    PageType = API;
    SourceTable = "Sales Shipment Line";
    SourceTableView = where(BS = const(true),
                            "Quantity Invoiced" = filter(= 0),
                            "Qty BS To Invoice" = filter(> 0),
                            Masque = filter(false));
    APIPublisher = 'sopiq';
    APIGroup = 'interne';
    APIVersion = 'v1.0';
    EntityName = 'SiPanierBsAPI';
    EntitySetName = 'SiPanierBsAPI';
    ODataKeyFields = SystemId;
    DelayedInsert = true;
    Extensible = false;
    InsertAllowed = false;
    DeleteAllowed = false;

    Permissions = tabledata "Sales Shipment Line" = rm,
                  tabledata "Sales Shipment Header" = r;

    layout
    {
        area(Content)
        {
            repeater(Lignes)
            {
                field(id; Rec.SystemId)
                {
                    Caption = 'SystemId', Locked = true;
                    Editable = false;
                }
                field(documentNo; Rec."Document No.")
                {
                    Caption = 'N° bon de sortie';
                    Editable = false;
                }
                field(lineNo; Rec."Line No.")
                {
                    Caption = 'N° ligne';
                    Editable = false;
                }
                field(postingDate; Rec."Posting Date")
                {
                    Caption = 'Date';
                    Editable = false;
                }
                field(billToCustomerNo; Rec."Bill-to Customer No.")
                {
                    Caption = 'Client facturé';
                    Editable = false;
                }
                field(sellToCustomerNo; Rec."Sell-to Customer No.")
                {
                    Caption = 'Client';
                    Editable = false;
                }
                field(no; Rec."No.")
                {
                    Caption = 'N° article';
                    Editable = false;
                }
                field(description; Rec.Description)
                {
                    Caption = 'Désignation';
                    Editable = false;
                }
                field(quantity; Rec.Quantity)
                {
                    Caption = 'Quantité du bon de sortie';
                    Editable = false;
                }
                field(qtyBsToInvoice; Rec."Qty BS To Invoice")
                {
                    Caption = 'Quantité à facturer';
                }
                field(selectedLine; Rec."Selected line")
                {
                    Caption = 'Ligne sélectionnée';
                }
                field(keepInitPrices; Rec."Keep Init. Prices")
                {
                    Caption = 'Garder les prix initiaux';
                }
                field(unitOfMeasureCode; Rec."Unit of Measure Code")
                {
                    Caption = 'Unité de mesure';
                    Editable = false;
                }
                field(unitPrice; Rec."Unit Price")
                {
                    Caption = 'Prix unitaire';
                    Editable = false;
                }
                field(lineDiscountPct; Rec."% Discount")
                {
                    Caption = 'Remise en pourcentage';
                    Editable = false;
                }
                field(lineAmountHT; Rec."Line Amount HT")
                {
                    Caption = 'Montant HT';
                    Editable = false;
                }
                field(lineAmount; Rec."Line Amount")
                {
                    Caption = 'Montant TTC';
                    Editable = false;
                }
                field(vatPct; Rec."VAT %")
                {
                    Caption = 'Taux TVA';
                    Editable = false;
                }
                field(documentNoBsInverse; Rec."Document No BS Inverse")
                {
                    Caption = 'N° retour qui annule cette ligne';
                    Editable = false;
                }
                field(lineNoBsInverse; Rec."Line No BS Inverse")
                {
                    Caption = 'N° ligne du retour';
                    Editable = false;
                }
            }
        }
    }

    var
        LignesManquantesErr: Label 'Aucune ligne à transformer n''a été fournie.';
        LignesIllisiblesErr: Label 'La liste des lignes n''est pas un JSON valide.';
        ClientManquantErr: Label 'Le client est obligatoire : c''est lui que la fenêtre de l''état demande.';
        AucuneLigneRetenueErr: Label 'Aucune des lignes fournies n''est transformable. Voir le détail des refus.';

    // Transforme en bon de livraison les lignes de panier designees, par l'etat 50003 de
    // l'extension du verticalisateur, celui du bouton « Transformer en BL ».
    //
    // Comment les lignes sont designees. L'etat travaille sur le jeu de lignes qu'on lui
    // passe, et non sur la case « Ligne sélectionnée » : celle-ci ne sert qu'aux totaux
    // affiches par la page. Le jeu est ici construit a partir des identifiants des lignes
    // demandees, ce qui laisse intactes les coches posees par d'autres.
    //
    // Le client est passe par les parametres de la fenetre de l'etat, son seul champ.
    //
    // Rend le ou les documents produits, le compte des lignes transformees, et la liste des
    // lignes refusees avec leur motif.
    [ServiceEnabled]
    procedure transformerEnBL(customerNo: Text; lignes: Text; accepterAutreClient: Boolean): Text
    var
        Ligne: Record "Sales Shipment Line";
        Expedition: Record "Sales Shipment Header";
        Reference: RecordRef;
        Demandees: JsonArray;
        Jeton: JsonToken;
        Element: JsonObject;
        Valeur: JsonToken;
        Refusees: JsonArray;
        Refus: JsonObject;
        Produits: JsonArray;
        Reponse: JsonObject;
        Texte: Text;
        FiltreIds: Text;
        ExpeditionsAvant: List of [Code[20]];
        NoDocument: Code[20];
        NoLigne: Integer;
        NoClient: Code[20];
        NbRetenues: Integer;
        NbTransformees: Integer;
    begin
        NoClient := CopyStr(customerNo, 1, MaxStrLen(NoClient));
        if NoClient = '' then
            Error(ClientManquantErr);
        if lignes = '' then
            Error(LignesManquantesErr);
        if not Demandees.ReadFrom(lignes) then
            Error(LignesIllisiblesErr);
        if Demandees.Count() = 0 then
            Error(LignesManquantesErr);

        foreach Jeton in Demandees do begin
            Element := Jeton.AsObject();

            NoDocument := '';
            NoLigne := 0;
            if Element.Get('documentNo', Valeur) then
                NoDocument := CopyStr(Valeur.AsValue().AsText(), 1, MaxStrLen(NoDocument));
            if Element.Get('lineNo', Valeur) then
                NoLigne := Valeur.AsValue().AsInteger();

            Clear(Refus);
            Refus.Add('documentNo', NoDocument);
            Refus.Add('lineNo', NoLigne);

            if not Ligne.Get(NoDocument, NoLigne) then begin
                Refus.Add('motif', 'Ligne introuvable');
                Refusees.Add(Refus);
            end else
                if not Ligne.BS then begin
                    Refus.Add('motif', 'Cette ligne n''appartient pas à un bon de sortie');
                    Refusees.Add(Refus);
                end else
                    if Ligne."Quantity Invoiced" <> 0 then begin
                        Refus.Add('motif', 'Ligne déjà facturée');
                        Refusees.Add(Refus);
                    end else
                        if Ligne."Qty BS To Invoice" <= 0 then begin
                            Refus.Add('motif', 'Aucune quantité à facturer sur cette ligne');
                            Refusees.Add(Refus);
                        end else
                            if Ligne.Masque then begin
                                Refus.Add('motif', 'Ligne masquée');
                                Refusees.Add(Refus);
                            end else
                                if (Ligne."Bill-to Customer No." <> NoClient) and (not accepterAutreClient) then begin
                                    Refus.Add('motif', 'Cette ligne est au client ' + Ligne."Bill-to Customer No." +
                                                       '. Passez accepterAutreClient à vrai pour facturer quand même.');
                                    Refusees.Add(Refus);
                                end else begin
                                    if FiltreIds <> '' then
                                        FiltreIds += '|';
                                    FiltreIds += Format(Ligne.SystemId, 0, 4);
                                    NbRetenues += 1;
                                end;
        end;

        if NbRetenues = 0 then begin
            Reponse.Add('transformees', 0);
            Reponse.Add('documents', Produits);
            Reponse.Add('refusees', Refusees);
            Reponse.WriteTo(Texte);
            exit(Texte);
        end;

        // Les expeditions du client avant le traitement : ce qui apparaitra en plus sera
        // l'oeuvre de l'etat. Business Central 16 ne donne pas de date de creation sur ces
        // enregistrements, c'est donc une comparaison avant et apres.
        Expedition.Reset();
        Expedition.SetRange("Sell-to Customer No.", NoClient);
        if Expedition.FindSet() then
            repeat
                ExpeditionsAvant.Add(Expedition."No.");
            until Expedition.Next() = 0;

        // Le jeu de lignes passe a l'etat : uniquement celles qui ont ete retenues.
        Ligne.Reset();
        Ligne.SetRange(BS, true);
        Ligne.SetFilter(SystemId, FiltreIds);
        Reference.GetTable(Ligne);
        Reference.SetView(Ligne.GetView());

        Report.Execute(50003, ParametresClient(NoClient), Reference);

        // Ce qui a ete produit : les expeditions de ce client qui n'existaient pas avant.
        Expedition.Reset();
        Expedition.SetRange("Sell-to Customer No.", NoClient);
        if Expedition.FindSet() then
            repeat
                if not ExpeditionsAvant.Contains(Expedition."No.") then
                    Produits.Add(Expedition."No.");
            until Expedition.Next() = 0;

        // Ce qui a quitte le panier : les lignes retenues qui n'y figurent plus.
        Ligne.Reset();
        Ligne.SetFilter(SystemId, FiltreIds);
        if Ligne.FindSet() then
            repeat
                if (Ligne."Quantity Invoiced" <> 0) or (Ligne."Qty BS To Invoice" <= 0) then
                    NbTransformees += 1;
            until Ligne.Next() = 0;

        Reponse.Add('transformees', NbTransformees);
        Reponse.Add('retenues', NbRetenues);
        Reponse.Add('documents', Produits);
        Reponse.Add('refusees', Refusees);
        Reponse.WriteTo(Texte);
        exit(Texte);
    end;

    // La fenetre de l'etat ne porte qu'un champ, le client. Il lui est passe par les
    // parametres, sous la forme que Business Central attend pour une fenetre de demande.
    local procedure ParametresClient(NoClient: Code[20]): Text
    begin
        exit('<?xml version="1.0" standalone="yes"?>' +
             '<ReportParameters name="TransfertBStoBL" id="50003">' +
             '<Options>' +
             '<Field name="CustNo">' + NoClient + '</Field>' +
             '</Options>' +
             '<DataItems>' +
             '<DataItem name="DataItemName"></DataItem>' +
             '</DataItems>' +
             '</ReportParameters>');
    end;

}
