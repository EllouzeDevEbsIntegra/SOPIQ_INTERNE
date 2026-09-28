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
// Le reste a payer reprend, type par type, la formule des pages que la fiche recu utilise
// pour proposer ses documents. Elle n'est pas la meme partout, c'est voulu :
//   - factures et avoirs : "Remaining Amount", qui tient compte des reglements comptables,
//     moins ce qui a deja ete encaisse en caisse ;
//   - bons de sortie : "Montant TTC" du document, moins l'encaisse. Un BS ne passe pas par
//     les ecritures client, il n'a donc pas de Remaining Amount ;
//   - bons de livraison, retours : "Line Amount", moins l'encaisse, au signe pres.
//
// Les factures et avoirs d'achat ne sont pas exposes : ce sont des documents fournisseur,
// sans lien avec un client, donc hors du parcours du comptoir. Dites-le si le besoin
// apparait.
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

    layout
    {
        area(Content)
        {
            repeater(Documents)
            {
                field(entryNo; Rec."Entry No.") { Caption = 'N° séquentiel'; }
                field(customerNo; Rec."Customer No") { Caption = 'Client'; }
                field(type; Rec.type) { Caption = 'Type document'; }
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

    trigger OnOpenPage()
    var
        ClientNo: Code[20];
    begin
        ClientNo := CopyStr(Rec.GetFilter("Customer No"), 1, MaxStrLen(ClientNo));
        if ClientNo = '' then
            exit;

        Rec.Reset();
        Rec.DeleteAll();
        NoLigne := 0;

        ChargerBS(ClientNo);
        ChargerFactures(ClientNo);
        ChargerAvoirs(ClientNo);
        ChargerBL(ClientNo);
        ChargerRetours(ClientNo, true);
        ChargerRetours(ClientNo, false);
        ChargerImpayes(ClientNo);

        Rec.SetRange("Customer No", ClientNo);
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
            SalesInvoice.CalcFields("Amount Including VAT", "Remaining Amount", "Montant reçu caisse");
            Ajouter(ClientNo, "Document Caisse Type"::Invoice, SalesInvoice."No.", SalesInvoice."Posting Date",
                    SalesInvoice."Bill-to Name",
                    SalesInvoice."Amount Including VAT" + SalesInvoice."STStamp Amount",
                    SalesInvoice."Montant reçu caisse",
                    SalesInvoice."Remaining Amount" - SalesInvoice."Montant reçu caisse", 1, 0);
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
            SalesCrMemo.CalcFields("Amount Including VAT", "Remaining Amount", "Montant reçu caisse");
            Ajouter(ClientNo, "Document Caisse Type"::CreditMemo, SalesCrMemo."No.", SalesCrMemo."Posting Date",
                    SalesCrMemo."Bill-to Name", SalesCrMemo."Amount Including VAT",
                    SalesCrMemo."Montant reçu caisse",
                    SalesCrMemo."Remaining Amount" - SalesCrMemo."Montant reçu caisse", -1, 0);
        until SalesCrMemo.Next() = 0;
    end;

    local procedure ChargerBL(ClientNo: Code[20])
    var
        SalesShipment: Record "Sales Shipment Header";
    begin
        SalesShipment.Reset();
        SalesShipment.SetRange(BS, false);
        SalesShipment.SetRange(solde, false);
        SalesShipment.SetRange("Bill-to Customer No.", ClientNo);
        if not SalesShipment.FindSet() then
            exit;

        repeat
            SalesShipment.CalcFields("Line Amount", "Montant reçu caisse");
            Ajouter(ClientNo, "Document Caisse Type"::BL, SalesShipment."No.", SalesShipment."Posting Date",
                    SalesShipment."Bill-to Name", SalesShipment."Line Amount",
                    SalesShipment."Montant reçu caisse",
                    SalesShipment."Line Amount" - SalesShipment."Montant reçu caisse", 1, 0);
        until SalesShipment.Next() = 0;
    end;

    // Les retours viennent en deduction : le montant encaisse y est negatif, un retour est
    // solde quand "Line Amount" vaut l'oppose de l'encaisse.
    local procedure ChargerRetours(ClientNo: Code[20]; SurBS: Boolean)
    var
        ReturnReceipt: Record "Return Receipt Header";
        TypeDocument: Enum "Document Caisse Type";
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
            ReturnReceipt.CalcFields("Line Amount", "Montant reçu caisse");
            Ajouter(ClientNo, TypeDocument, ReturnReceipt."No.", ReturnReceipt."Posting Date",
                    ReturnReceipt."Bill-to Name", ReturnReceipt."Line Amount",
                    -ReturnReceipt."Montant reçu caisse",
                    ReturnReceipt."Line Amount" + ReturnReceipt."Montant reçu caisse", -1, 0);
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
        Rec.Insert();
    end;
}
