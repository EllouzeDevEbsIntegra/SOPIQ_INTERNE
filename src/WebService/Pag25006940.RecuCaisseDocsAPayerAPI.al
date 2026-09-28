// Documents non soldes d'un client, tous types confondus.
//
// Le vendeur du comptoir choisit, parmi les documents non soldes de son client, ceux qu'il
// encaisse. Ces documents vivent dans huit tables differentes ; une page API n'ayant qu'une
// seule source, la table 70014 est declaree temporaire et remplie a chaque appel. C'est le
// patron des pages d'etat de Business Central.
//
// Appel :
//   GET /api/sopiq/interne/v1.0/companies({id})/recuCaisseDocsAPayer?$filter=customerNo eq 'C00123'
//
// Le filtre sur le client est OBLIGATOIRE : sans lui, rien n'est renvoye.
//
// LA REGLE DU RESTE A PAYER, decidee le 28/09/2026 : le recu de caisse et la comptabilite
// sont deux circuits separes. Un document est solde, et son reste calcule, a partir des
// seuls recus de caisse. Les reglements comptables, "Remaining Amount" et les lettrages
// n'entrent jamais dans ce calcul.
//
//     reste a payer = montant du document - montant encaisse en caisse
//
// Le montant du document est celui que la regle du solde compare deja, type par type :
//   - facture de vente : "Amount Including VAT" + timbre fiscal ;
//   - avoir, bon de sortie, bon de livraison, retours : le montant du document ;
//   - facture d'achat : "Amount Including VAT" + timbre, en decaissement.
//
// Avant cette decision, les factures et avoirs passaient par "Remaining Amount", comme les
// listes de la fiche. Les deux sources comptaient alors le meme paiement deux fois des que
// la caisse comptabilisait son encaissement : un recu de 100 sur une facture de 100
// affichait un reste de -100, soit un avoir qui n'existe pas.
//
// Les factures et avoirs d'achat sont exposes sous le filtre estFournisseur : la fiche recu
// les propose sans aucun filtre de tiers, on fait pareil.
page 25006940 "Recu Caisse Docs A Payer API"
{
    PageType = API;
    SourceTable = "Recu Caisse Doc A Payer";
    SourceTableTemporary = true;
    APIPublisher = 'sopiq';
    APIGroup = 'interne';
    APIVersion = 'v1.0';
    EntityName = 'recuCaisseDocAPayer';
    EntitySetName = 'recuCaisseDocsAPayer';
    ODataKeyFields = "Entry No.";
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    DelayedInsert = true;
    Extensible = false;

    // Les documents a payer sont lus dans les tables de vente et d'achat. En declarant ces
    // droits ici, le compte utilise par l'API n'a besoin d'aucune permission directe sur les
    // documents : il ne peut les lire qu'a travers cette page, et en lecture seule.
    Permissions = tabledata "Sales Invoice Header" = R,
                  tabledata "Sales Cr.Memo Header" = R,
                  tabledata "Sales Shipment Header" = R,
                  tabledata "Return Receipt Header" = R,
                  tabledata "Entete archive BS" = R,
                  tabledata "Purch. Inv. Header" = R,
                  tabledata "Purch. Cr. Memo Hdr." = R,
                  tabledata "Recu Caisse Paiement" = R,
                  tabledata "Company Information" = R;

    layout
    {
        area(Content)
        {
            repeater(Documents)
            {
                field(entryNo; Rec."Entry No.") { Caption = 'N° séquentiel'; }
                field(customerNo; Rec."Customer No") { Caption = 'Client'; }
                field(type; Rec.type) { Caption = 'Type document'; }
                field(typeCode; Rec."Type Nom") { Caption = 'Nom du type'; }
                field(estFournisseur; Rec."Est Fournisseur") { Caption = 'Document fournisseur'; }
                field(documentNo; Rec."Document No") { Caption = 'N° document'; }
                field(dateDocument; Rec."Date Document") { Caption = 'Date document'; }
                field(libelle; Rec.Libelle) { Caption = 'Libellé'; }
                field(totalTTC; Rec."Total TTC") { Caption = 'Montant TTC'; }
                field(dejaRegle; Rec."Deja Regle") { Caption = 'Déjà réglé'; }
                field(resteAPayer; Rec."Reste A Payer") { Caption = 'Reste à payer'; }
                field(signe; Rec.Signe) { Caption = 'Signe'; }
                field(idLigneImpaye; Rec."Id Ligne Impaye") { Caption = 'N° ligne impayé'; }
            }
        }
    }

    var
        NoLigne: Integer;
        InfoSociete: Record "Company Information";
        InfoSocieteLue: Boolean;

    // COPIM est aujourd'hui la seule societe a faire des bons de sortie.
    local procedure SocieteAvecBS(): Boolean
    begin
        if not InfoSocieteLue then begin
            InfoSociete.Get();
            InfoSocieteLue := true;
        end;
        exit(InfoSociete.BS);
    end;

    // Deux usages, deux filtres, jamais les deux ensemble :
    //   ?$filter=customerNo eq 'C00123'   les documents du client
    //   ?$filter=estFournisseur eq true   les factures et avoirs d'achat, qui n'ont pas de
    //                                     client : la fiche recu les propose tels quels,
    //                                     toutes pieces non soldees confondues.
    trigger OnOpenPage()
    var
        ClientNo: Code[20];
        FiltreFournisseur: Text;
    begin
        ClientNo := CopyStr(Rec.GetFilter("Customer No"), 1, MaxStrLen(ClientNo));
        FiltreFournisseur := Rec.GetFilter("Est Fournisseur");

        Rec.Reset();
        Rec.DeleteAll();
        NoLigne := 0;

        if ClientNo <> '' then begin
            ChargerBS(ClientNo);
            ChargerFactures(ClientNo);
            ChargerAvoirs(ClientNo);
            ChargerBL(ClientNo);
            ChargerRetours(ClientNo, true);
            ChargerRetours(ClientNo, false);
            ChargerImpayes(ClientNo);
            Rec.SetRange("Customer No", ClientNo);
            exit;
        end;

        if (FiltreFournisseur = '1') or (LowerCase(FiltreFournisseur) = 'true') or (LowerCase(FiltreFournisseur) = 'yes') then begin
            ChargerFacturesAchat();
            ChargerAvoirsAchat();
            Rec.SetRange("Est Fournisseur", true);
        end;
    end;

    local procedure ChargerBS(ClientNo: Code[20])
    var
        ArchiveBS: Record "Entete archive BS";
    begin
        ArchiveBS.Reset();
        ArchiveBS.SetRange(Solde, false);
        ArchiveBS.SetRange("Bill-to Customer No.", ClientNo);
        if not ArchiveBS.FindSet() then
            exit;

        repeat
            ArchiveBS.CalcFields("Montant TTC", "Montant reçu caisse");
            Ajouter(ClientNo, "Document Caisse Type"::BS, ArchiveBS."No.", ArchiveBS."Posting Date",
                    ArchiveBS."Bill-to Name", ArchiveBS."Montant TTC", ArchiveBS."Montant reçu caisse",
                    ArchiveBS."Montant TTC" - ArchiveBS."Montant reçu caisse", 1, 0);
        until ArchiveBS.Next() = 0;
    end;

    local procedure ChargerFactures(ClientNo: Code[20])
    var
        SalesInvoice: Record "Sales Invoice Header";
    begin
        SalesInvoice.Reset();
        SalesInvoice.SetRange(solde, false);
        SalesInvoice.SetRange("Bill-to Customer No.", ClientNo);
        if not SalesInvoice.FindSet() then
            exit;

        repeat
            SalesInvoice.CalcFields("Amount Including VAT", "Montant reçu caisse");
            Ajouter(ClientNo, "Document Caisse Type"::Invoice, SalesInvoice."No.", SalesInvoice."Posting Date",
                    SalesInvoice."Bill-to Name",
                    SalesInvoice."Amount Including VAT" + SalesInvoice."STStamp Amount",
                    SalesInvoice."Montant reçu caisse",
                    SalesInvoice."Amount Including VAT" + SalesInvoice."STStamp Amount"
                        - SalesInvoice."Montant reçu caisse", 1, 0);
        until SalesInvoice.Next() = 0;
    end;

    local procedure ChargerAvoirs(ClientNo: Code[20])
    var
        SalesCrMemo: Record "Sales Cr.Memo Header";
    begin
        SalesCrMemo.Reset();
        SalesCrMemo.SetRange(solde, false);
        SalesCrMemo.SetRange("Bill-to Customer No.", ClientNo);
        if not SalesCrMemo.FindSet() then
            exit;

        repeat
            SalesCrMemo.CalcFields("Amount Including VAT", "Montant reçu caisse");
            Ajouter(ClientNo, "Document Caisse Type"::CreditMemo, SalesCrMemo."No.", SalesCrMemo."Posting Date",
                    SalesCrMemo."Bill-to Name", SalesCrMemo."Amount Including VAT",
                    -SalesCrMemo."Montant reçu caisse",
                    SalesCrMemo."Amount Including VAT" + SalesCrMemo."Montant reçu caisse", -1, 0);
        until SalesCrMemo.Next() = 0;
    end;

    // Dans une societe qui fait des bons de sortie, COPIM aujourd'hui, une vente facturee au
    // comptoir produit deux documents : l'expedition et la facture. Les compter tous les deux
    // ferait encaisser la vente deux fois.
    //
    // La regle est celle du rapport "Etat Solde Client", la reference de la caisse : pour une
    // telle societe, un bon de livraison vaut son "Montant Ouvert", qui ne somme que les
    // lignes restant a facturer. Un BL entierement facture tombe a zero, c'est la facture qui
    // porte la dette, et il sort de la liste. Ailleurs, le montant du document fait foi.
    local procedure ChargerBL(ClientNo: Code[20])
    var
        SalesShipment: Record "Sales Shipment Header";
        Reference: Decimal;
        Reste: Decimal;
    begin
        SalesShipment.Reset();
        SalesShipment.SetRange(BS, false);
        SalesShipment.SetRange(solde, false);
        SalesShipment.SetRange("Bill-to Customer No.", ClientNo);
        if not SalesShipment.FindSet() then
            exit;

        repeat
            SalesShipment.CalcFields("Line Amount", "Montant Ouvert", "Montant reçu caisse");

            if SocieteAvecBS() then
                Reference := SalesShipment."Montant Ouvert"
            else
                Reference := SalesShipment."Line Amount";

            Reste := Reference - SalesShipment."Montant reçu caisse";

            if Reste <> 0 then
                Ajouter(ClientNo, "Document Caisse Type"::BL, SalesShipment."No.", SalesShipment."Posting Date",
                        SalesShipment."Bill-to Name", Reference,
                        SalesShipment."Montant reçu caisse", Reste, 1, 0);
        until SalesShipment.Next() = 0;
    end;

    // Les retours viennent en deduction : le montant encaisse y est negatif, un retour est
    // solde quand "Line Amount" vaut l'oppose de l'encaisse.
    local procedure ChargerRetours(ClientNo: Code[20]; SurBS: Boolean)
    var
        ReturnReceipt: Record "Return Receipt Header";
        TypeDocument: Enum "Document Caisse Type";
        Reference: Decimal;
        Reste: Decimal;
    begin
        if SurBS then
            TypeDocument := "Document Caisse Type"::RetourBS
        else
            TypeDocument := "Document Caisse Type"::RetourBL;

        ReturnReceipt.Reset();
        ReturnReceipt.SetRange(BS, SurBS);
        ReturnReceipt.SetRange(solde, false);
        ReturnReceipt.SetRange("Bill-to Customer No.", ClientNo);
        if not ReturnReceipt.FindSet() then
            exit;

        repeat
            ReturnReceipt.CalcFields("Line Amount", "Montant Ouvert", "Montant reçu caisse");

            // Meme regle que pour les bons de livraison, et pour la meme raison : un retour
            // deja repris sur un avoir ne doit plus etre rembourse au comptoir.
            if (not SurBS) and SocieteAvecBS() then
                Reference := ReturnReceipt."Montant Ouvert"
            else
                Reference := ReturnReceipt."Line Amount";

            // Le montant encaisse est negatif sur un retour : la caisse a rendu de l'argent.
            Reste := Reference + ReturnReceipt."Montant reçu caisse";

            if Reste <> 0 then
                Ajouter(ClientNo, TypeDocument, ReturnReceipt."No.", ReturnReceipt."Posting Date",
                        ReturnReceipt."Bill-to Name", Reference,
                        -ReturnReceipt."Montant reçu caisse", Reste, -1, 0);
        until ReturnReceipt.Next() = 0;
    end;

    // Un impaye est une ligne de paiement d'un recu anterieur, marquee impayee et non
    // soldee : le client doit la regler a nouveau.
    local procedure ChargerImpayes(ClientNo: Code[20])
    var
        RecuPaiement: Record "Recu Caisse Paiement";
    begin
        RecuPaiement.Reset();
        RecuPaiement.SetRange(Impaye, true);
        RecuPaiement.SetRange(solde, false);
        if not RecuPaiement.FindSet() then
            exit;

        repeat
            RecuPaiement.CalcFields("N° Client", "Montant reçu caisse");
            if RecuPaiement."N° Client" = ClientNo then
                Ajouter(ClientNo, "Document Caisse Type"::Impaye, RecuPaiement."No Recu",
                        RecuPaiement."Date Impaye", Format(RecuPaiement.type) + ' ' + RecuPaiement.Name,
                        RecuPaiement.Montant, RecuPaiement."Montant reçu caisse",
                        RecuPaiement.Montant - RecuPaiement."Montant reçu caisse", 1,
                        RecuPaiement."Line No");
        until RecuPaiement.Next() = 0;
    end;

    // Factures d'achat reglees au comptoir. La fiche recu ne les filtre par aucun tiers :
    // elle propose toutes les pieces non soldees, le caissier choisit son numero. On fait
    // pareil, sinon la liste de l'API et celle de la fiche ne diraient pas la meme chose.
    //
    // Sens : un decaissement. La fiche enregistre un montant de reglement negatif, et le
    // document est solde quand son TTC vaut l'oppose de ce qui est sorti de la caisse.
    local procedure ChargerFacturesAchat()
    var
        PurchInvoice: Record "Purch. Inv. Header";
        TotalTTC: Decimal;
    begin
        PurchInvoice.Reset();
        PurchInvoice.SetRange(solde, false);
        if not PurchInvoice.FindSet() then
            exit;

        repeat
            PurchInvoice.CalcFields("Amount Including VAT", "Montant reçu caisse");
            TotalTTC := PurchInvoice."Amount Including VAT" + PurchInvoice."STStamp Fiscal Amount";
            AjouterFournisseur("Document Caisse Type"::FA, PurchInvoice."No.", PurchInvoice."Posting Date",
                               PurchInvoice."Buy-from Vendor Name", TotalTTC,
                               -PurchInvoice."Montant reçu caisse",
                               TotalTTC + PurchInvoice."Montant reçu caisse", -1);
        until PurchInvoice.Next() = 0;
    end;

    local procedure ChargerAvoirsAchat()
    var
        PurchCrMemo: Record "Purch. Cr. Memo Hdr.";
    begin
        PurchCrMemo.Reset();
        PurchCrMemo.SetRange(solde, false);
        if not PurchCrMemo.FindSet() then
            exit;

        repeat
            PurchCrMemo.CalcFields("Amount Including VAT", "Montant reçu caisse");
            AjouterFournisseur("Document Caisse Type"::AVA, PurchCrMemo."No.", PurchCrMemo."Posting Date",
                               PurchCrMemo."Buy-from Vendor Name", PurchCrMemo."Amount Including VAT",
                               PurchCrMemo."Montant reçu caisse",
                               PurchCrMemo."Amount Including VAT" - PurchCrMemo."Montant reçu caisse", 1);
        until PurchCrMemo.Next() = 0;
    end;

    local procedure AjouterFournisseur(TypeDocument: Enum "Document Caisse Type"; DocumentNo: Code[20]; DateDocument: Date; Libelle: Text; TotalTTC: Decimal; DejaRegle: Decimal; RestePayer: Decimal; Signe: Integer)
    begin
        Ajouter('', TypeDocument, DocumentNo, DateDocument, Libelle, TotalTTC, DejaRegle, RestePayer, Signe, 0);
        Rec."Est Fournisseur" := true;
        Rec.Modify();
    end;

    local procedure Ajouter(ClientNo: Code[20]; TypeDocument: Enum "Document Caisse Type"; DocumentNo: Code[20]; DateDocument: Date; Libelle: Text; TotalTTC: Decimal; DejaRegle: Decimal; RestePayer: Decimal; Signe: Integer; IdLigneImpaye: Integer)
    begin
        NoLigne += 1;

        Rec.Init();
        Rec."Entry No." := NoLigne;
        Rec."Customer No" := ClientNo;
        Rec.type := TypeDocument;
        Rec."Document No" := DocumentNo;
        Rec."Date Document" := DateDocument;
        Rec.Libelle := CopyStr(Libelle, 1, MaxStrLen(Rec.Libelle));
        Rec."Total TTC" := TotalTTC;
        Rec."Deja Regle" := DejaRegle;
        Rec."Reste A Payer" := RestePayer;
        Rec.Signe := Signe;
        Rec."Id Ligne Impaye" := IdLigneImpaye;
        Rec."Type Nom" := CopyStr(NomDuType(TypeDocument), 1, MaxStrLen(Rec."Type Nom"));
        Rec.Insert();
    end;

    // Le nom du membre, celui que l'appel de creation attend, et non le libelle affiche.
    local procedure NomDuType(TypeDocument: Enum "Document Caisse Type"): Text
    var
        Position: Integer;
    begin
        Position := TypeDocument.Ordinals().IndexOf(TypeDocument.AsInteger());
        if Position = 0 then
            exit('');
        exit(TypeDocument.Names().Get(Position));
    end;
}
