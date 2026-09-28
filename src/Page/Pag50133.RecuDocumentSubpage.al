page 50133 "Recu Document Subpage"
{
    PageType = ListPart;
    Caption = 'Document à payer';
    SourceTable = "Recu Caisse Document";

    layout
    {
        area(content)
        {
            repeater(Group)
            {

                field("No Recu"; "No Recu")
                {
                    ApplicationArea = All;
                    TableRelation = "Recu Caisse";
                    Visible = false;
                }
                field("Line No"; "Line No")
                {
                    ApplicationArea = all;
                    Visible = false;
                }
                field(type; type)
                {
                    ApplicationArea = all;
                    ValuesAllowed =;
                    //Editable = false;
                    trigger OnValidate()
                    begin
                        if (type = type::null) then
                            Error('Vous devez spécifier le type de document !') else begin
                            if (rec.type <> xRec.type) then begin
                                "Customer No" := custNo;
                                "Document No" := '';
                                "Montant Reglement" := 0;
                                "Total TTC" := 0;

                                if (type = type::Impaye) then begin
                                    isImpaye := true;
                                end else
                                    isImpaye := false;
                                CurrPage.Update();
                            end
                        end;
                    end;

                }

                field("Customer No"; "Customer No")
                {
                    ApplicationArea = all;
                    Editable = false;
                    Visible = false;
                }

                field("Document No"; "Document No")
                {
                    ApplicationArea = all;
                    Editable = NOT (isDivers);
                    //Visible = NOT (libelleVisible);
                    TableRelation = if (type = const(Invoice)) "Sales Invoice Header" where("Bill-to Customer No." = field("Customer No"), solde = filter('Non'))
                    else
                    if (type = const(BS)) "Entete archive BS" where("Bill-to Customer No." = field("Customer No"), solde = filter('Non'))
                    else
                    if (type = const(CreditMemo)) "Sales Cr.Memo Header" where("Bill-to Customer No." = field("Customer No"), solde = filter('Non'))
                    else
                    if (type = const(RetourBS)) "Return Receipt Header" where("Bill-to Customer No." = field("Customer No"), BS = filter('Oui'), solde = filter('Non'))
                    else
                    if (type = const(BL)) "Sales Shipment Header" where("Bill-to Customer No." = field("Customer No"), solde = filter('Non'))
                    else
                    if (type = const(RetourBL)) "Return Receipt Header" where("Bill-to Customer No." = field("Customer No"), solde = filter('Non'))
                    else
                    if (type = const(Acompte)) "Salesperson/Purchaser"
                    else
                    if (type = const(FA)) "Purch. Inv. Header" where(solde = filter('Non'))
                    else
                    if (type = const(AVA)) "Purch. Cr. Memo Hdr." where(solde = filter('Non'))
                    else
                    if (type = const(Impaye)) "Recu Caisse Paiement"."No Recu" where("N° Client" = field("Customer No"), Impaye = filter('Oui'), solde = filter('Non'));
                    trigger OnValidate()

                    var
                        recBs: Record "Entete archive BS";
                        recInvoice: Record "Sales Invoice Header";
                        recCrMemo: Record "Sales Cr.Memo Header";
                        recRetourBS: Record "Return Receipt Header";
                        recBL: Record "Sales Shipment Header";
                        recRetourBL: Record "Return Receipt Header";
                        recPurchInv: Record "Purch. Inv. Header";
                        recPurchCrMemo: Record "Purch. Cr. Memo Hdr.";
                        recRecuCaissePaiement: Record "Recu Caisse Paiement";

                    begin

                        if (rec."Document No" <> xrec."Document No") then begin
                            "Montant Reglement" := 0;
                            "Total TTC" := 0;
                            Modify();
                            case rec.type of
                                type::BS:
                                    begin
                                        recBs.SetRange("No.", "Document No");

                                        if recBs.FindFirst() then begin
                                            recBs.CalcFields("Montant reçu caisse", "Montant TTC");
                                            "Montant Reglement" := recBs."Montant TTC" - recBs."Montant reçu caisse";
                                            "Total TTC" := recBs."Montant TTC";
                                            Modify();
                                        end;
                                    end;
                                type::Invoice:
                                    begin
                                        recInvoice.SetRange("No.", "Document No");
                                        if recInvoice.FindFirst() then begin
                                            recInvoice.CalcFields("Amount Including VAT", "Montant reçu caisse");
                                            "Montant Reglement" := recInvoice."STStamp Amount" + recInvoice."Amount Including VAT" - recInvoice."Montant reçu caisse";
                                            "Total TTC" := recInvoice."Amount Including VAT" + recInvoice."STStamp Amount";
                                            Modify();
                                        end
                                    end;
                                type::RetourBS:
                                    begin
                                        recRetourBS.SetRange("No.", "Document No");
                                        if recRetourBS.FindFirst() then begin
                                            recRetourBS.CalcFields("Line Amount HT", "Line Amount", "Montant reçu caisse");

                                            // Ce que la caisse a deja rendu est negatif : sans cette
                                            // deduction, un retour rembourse en partie etait propose
                                            // une seconde fois pour sa totalite.
                                            if recRetourBS."Line Amount" + recRetourBS."Montant reçu caisse" = 0 then
                                                Error(DocumentSansResteErr, recRetourBS."No.");

                                            "Montant Reglement" := -(recRetourBS."Line Amount" + recRetourBS."Montant reçu caisse");
                                            "Total TTC" := -recRetourBS."Line Amount";
                                            Modify();
                                        end
                                    end;
                                type::CreditMemo:
                                    begin

                                        recCrMemo.SetRange("No.", "Document No");
                                        if recCrMemo.FindFirst() then begin
                                            recCrMemo.CalcFields("Amount Including VAT", "Montant reçu caisse");

                                            // Meme deduction. Un avoir ne porte pas de timbre fiscal,
                                            // son montant est le TTC seul.
                                            if recCrMemo."Amount Including VAT" + recCrMemo."Montant reçu caisse" = 0 then
                                                Error(DocumentSansResteErr, recCrMemo."No.");

                                            "Montant Reglement" := -(recCrMemo."Amount Including VAT" + recCrMemo."Montant reçu caisse");
                                            "Total TTC" := -recCrMemo."Amount Including VAT";
                                            Modify();
                                        end;
                                    end;
                                type::BL:
                                    begin
                                        recBL.SetRange("No.", "Document No");
                                        if recBL.FindFirst() then begin
                                            recBL.CalcFields("Total line amount", "Line Amount", "Montant Ouvert", "Montant reçu caisse");

                                            // Dans une societe qui fait des bons de sortie, une vente
                                            // facturee produit deux documents : l'expedition et la
                                            // facture. Encaisser les deux ferait payer la vente deux
                                            // fois. Regle du rapport "Etat Solde Client" : le bon de
                                            // livraison ne vaut que ce qui reste a facturer.
                                            if SocieteAvecBS() then
                                                MontantReference := recBL."Montant Ouvert"
                                            else
                                                MontantReference := recBL."Line Amount";

                                            if MontantReference - recBL."Montant reçu caisse" = 0 then
                                                Error(DocumentSansResteErr, recBL."No.");

                                            "Montant Reglement" := MontantReference - recBL."Montant reçu caisse";
                                            "Total TTC" := MontantReference;
                                            Modify();
                                        end;
                                    end;
                                type::RetourBL:
                                    begin
                                        recRetourBL.SetRange("No.", "Document No");
                                        if recRetourBL.FindFirst() then begin
                                            recRetourBL.CalcFields("Line Amount", "Montant Ouvert", "Montant reçu caisse");

                                            if SocieteAvecBS() then
                                                MontantReference := recRetourBL."Montant Ouvert"
                                            else
                                                MontantReference := recRetourBL."Line Amount";

                                            // Le montant deja rendu au client est negatif : on le
                                            // deduit, sinon un retour rembourse en partie serait
                                            // propose une seconde fois pour sa totalite.
                                            if MontantReference + recRetourBL."Montant reçu caisse" = 0 then
                                                Error(DocumentSansResteErr, recRetourBL."No.");

                                            "Montant Reglement" := -(MontantReference + recRetourBL."Montant reçu caisse");
                                            "Total TTC" := -MontantReference;
                                        end;

                                    end;
                                type::FA:
                                    begin
                                        recPurchInv.SetRange("No.", "Document No");
                                        if recPurchInv.FindFirst() then begin
                                            recPurchInv.CalcFields("Amount Including VAT", "Montant reçu caisse");
                                            // Un reglement de facture d'achat est enregistre en negatif :
                                            // "Montant reçu caisse" est donc negatif lui aussi. L'ancienne
                                            // formule le soustrayait, ce qui l'ajoutait au reste du : une
                                            // facture de 100 deja reglee de 30 proposait 130 au lieu de 70.
                                            "Montant Reglement" := -(recPurchInv."Amount Including VAT" + recPurchInv."STStamp Fiscal Amount" + recPurchInv."Montant reçu caisse");
                                            "Total TTC" := (recPurchInv."Amount Including VAT" + recPurchInv."STStamp Fiscal Amount");
                                        end;

                                    end;
                                type::AVA:
                                    begin
                                        recPurchCrMemo.SetRange("No.", "Document No");
                                        if recPurchCrMemo.FindFirst() then begin
                                            recPurchCrMemo.CalcFields("Amount Including VAT", "Montant reçu caisse");
                                            "Montant Reglement" := (recPurchCrMemo."Amount Including VAT" - recPurchCrMemo."Montant reçu caisse");
                                            "Total TTC" := recPurchCrMemo."Amount Including VAT";
                                        end;
                                    end;
                                type::Impaye:
                                    begin
                                        recRecuCaissePaiement.SetRange("N° Client", "Customer No");
                                        recRecuCaissePaiement.SetRange("No Recu", "Document No");
                                        recRecuCaissePaiement.SetRange(Impaye, true);
                                        recRecuCaissePaiement.SetRange(solde, false);
                                        if recRecuCaissePaiement.FindFirst() then begin
                                            recRecuCaissePaiement.CalcFields("Montant reçu caisse");
                                            "Montant Reglement" := 0;
                                            "Total TTC" := 0;
                                            isImpaye := true;
                                            CurrPage.Update();
                                            //Libelle := 'Impaye ' + Format(recRecuCaissePaiement.type) + ' ' + Format(recRecuCaissePaiement.banque) + ' N°' + recRecuCaissePaiement."Paiment No" + ' Montant: ' + Format(recRecuCaissePaiement."Montant", 0, '<Precision,3:3><Standard Format,0>') + ' Echéance : ' + Format(recRecuCaissePaiement.Echeance) + ' ' + recRecuCaissePaiement.Name;
                                        end;
                                    end;
                                else begin

                                end;
                            end;

                        end;
                    end;

                }
                field("id Ligne Impaye"; "id Ligne Impaye")
                {
                    ApplicationArea = all;
                    Visible = isImpaye;
                    TableRelation = if (type = const(Impaye)) "Recu Caisse Paiement"."Line No" where("N° Client" = field("Customer No"), Impaye = filter('Oui'), solde = filter('Non'), "No Recu" = field("Document No"));
                    trigger OnValidate()
                    var
                        recRecuCaissePaiement: Record "Recu Caisse Paiement";
                    begin
                        if (rec."id Ligne Impaye" <> xrec."id Ligne Impaye") then begin
                            "Montant Reglement" := 0;
                            "Total TTC" := 0;
                            Modify();

                            recRecuCaissePaiement.SetRange("N° Client", "Customer No");
                            recRecuCaissePaiement.SetRange("No Recu", "Document No");
                            recRecuCaissePaiement.SetRange("Line No", "id Ligne Impaye");
                            recRecuCaissePaiement.SetRange(Impaye, true);
                            recRecuCaissePaiement.SetRange(solde, false);
                            if recRecuCaissePaiement.FindFirst() then begin
                                recRecuCaissePaiement.CalcFields("Montant reçu caisse");
                                "Montant Reglement" := recRecuCaissePaiement."Montant" - recRecuCaissePaiement."Montant reçu caisse";
                                "Total TTC" := recRecuCaissePaiement."Montant";
                                Libelle := ' Impaye ' + Format(recRecuCaissePaiement.type) + ' ' + Format(recRecuCaissePaiement.banque) + ' N°' + recRecuCaissePaiement."Paiment No" + ' Montant: ' + Format(recRecuCaissePaiement."Montant", 0, '<Precision,3:3><Standard Format,0>') + ' Echéance : ' + Format(recRecuCaissePaiement.Echeance) + ' ' + recRecuCaissePaiement.Name;
                            end;
                        end;
                    end;

                }

                field(Libelle; Libelle)
                {
                    ApplicationArea = all;
                    //Visible = libelleVisible;
                }
                field("Total TTC"; "Total TTC")
                {
                    ApplicationArea = all;
                    Editable = false;
                }

                field("Montant Reglement"; "Montant Reglement")
                {
                    ApplicationArea = all;
                }

            }

        }

    }

    actions
    {
        area(Processing)
        {

        }
    }

    var
        custNo: code[20];
        totalDoc: Decimal;
        nbDoc: Integer;
        isDivers: Boolean;
        TempDocumentNo: Code[20];
        TempLigneImpaye: Integer;
        isImpaye: Boolean;
        InfoSociete: Record "Company Information";
        InfoSocieteLue: Boolean;
        MontantReference: Decimal;
        DocumentSansResteErr: Label 'Le document %1 ne laisse plus rien à encaisser : il est entièrement facturé ou déjà réglé.', Comment = '%1 numéro du document';

    procedure setFilter(recuCaisse: Record "Recu Caisse")
    var
        cust: Record Customer;
    begin
        SetFilter("No Recu", recuCaisse.No);
        SetFilter("Customer No", recuCaisse."Customer No");
        cust.Reset();
        cust.SetRange("No.", recuCaisse."Customer No");
        if cust.FindFirst() then begin
            isDivers := cust."Is Divers";
        end;
        CurrPage.Update();
        custNo := recuCaisse."Customer No";
    end;

    // COPIM est aujourd'hui la seule societe a faire des bons de sortie.
    local procedure SocieteAvecBS(): Boolean
    begin
        if not InfoSocieteLue then begin
            InfoSociete.Get();
            InfoSocieteLue := true;
        end;
        exit(InfoSociete.BS);
    end;

    procedure setDiversCustomer(recuCaisse: Record "Recu Caisse")
    var
        recCust: Record Customer;
    begin
        recCust.Reset();
        recCust.Get(recuCaisse."Customer No");
        if recCust.Find() then begin
            if recCust."Is Divers" = true then begin
                isDivers := true;
                CurrPage.Update();
            end

        end;

    end;

}