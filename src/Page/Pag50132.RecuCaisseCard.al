page 50132 "Recu Caisse Card"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "Recu Caisse";
    Permissions = tabledata "Sales Invoice Header" = rm,
                    tabledata "Entete archive BS" = rm,
                    tabledata "Sales Cr.Memo Header" = rm,
                    tabledata "Return Receipt Header" = rm,
                    tabledata "Sales Shipment Header" = rm,
                    tabledata "Purch. Cr. Memo Hdr." = rm,
                    tabledata "Purch. Inv. Header" = rm;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Editable = NOT (Printed);
                field(No; No)
                {
                    Caption = 'N° Reçu';
                    Editable = false;
                    ApplicationArea = All;
                }


                field("Customer No"; "Customer No")
                {
                    ApplicationArea = all;
                    Caption = 'Client';
                    Editable = modifCustomer;
                    trigger OnValidate()
                    var
                        recSalesSetup: Record "Sales & Receivables Setup";
                        recSeries: Record "No. Series Line";
                        recCust: Record Customer;
                        serieNoMgt: Codeunit NoSeriesManagement;
                        recuDocument: Record "Recu Caisse Document";
                        recuPaiment: Record "Recu Caisse Paiement";
                    begin
                        if (xRec."Customer No" = '') then begin
                            recSalesSetup.Get;
                            // recSeries.Reset();
                            // recSeries.SetRange("Series Code", recSalesSetup."Reçu Caisse Serie");
                            // if recSeries.FindLast() then begin
                            //     rec.No := recSeries.GetNextSequenceNo(true);
                            //     rec.dateTime := System.CurrentDateTime;
                            //     rec.dateRecu := System.Today;
                            // end;
                            rec.dateTime := System.CurrentDateTime;
                            rec.dateRecu := System.Today;
                            rec.No := serieNoMgt.GetNextNo(recSalesSetup."Reçu Caisse Serie", dateRecu, true);


                        end
                        else
                            if (xRec."Customer No" <> rec."Customer No") then begin
                                recuDocument.Reset();
                                recuDocument.SetRange("No Recu", rec.No);
                                if recuDocument.FindSet() then begin
                                    repeat
                                        recuDocument.Delete();
                                    until recuDocument.Next() = 0;
                                end;

                                recuPaiment.Reset();
                                recuPaiment.SetRange("No Recu", rec.No);
                                if recuPaiment.FindSet() then begin
                                    repeat
                                        recuPaiment.Delete();
                                    until recuPaiment.Next() = 0;
                                end;

                                CurrPage.Document.Page.setFilter(rec);
                                CurrPage.Paiement.Page.setFilter(rec);
                            end;


                        recCust.Reset();
                        if recCust.get("Customer No") then rec.custName := recCust.Name;
                        modifCustomer := false;


                    end;
                }

                field(custName; custName)
                {
                    ApplicationArea = all;
                    Caption = 'Nom Client';
                    Editable = false;
                }
                field(Printed; Printed)
                {
                    ApplicationArea = all;
                    Caption = 'Imprimé';
                    Editable = false;
                }



                field(dateTime; dateTime)
                {
                    ApplicationArea = all;
                    Caption = 'Date et Heure';
                    Editable = false;
                }

                field(dateRecu; dateRecu)
                {
                    ApplicationArea = all;
                    Caption = 'Date Reçu';
                    Editable = modifCustomer;
                }

                field(user; user)
                {
                    ApplicationArea = all;
                    Caption = 'Code Vendeur';
                    trigger OnValidate()
                    begin
                        CurrPage.Document.Page.setDiversCustomer(rec);
                        CurrPage.Document.Page.setFilter(rec);
                        CurrPage.Paiement.Page.setFilter(rec);
                        isCreated := true;

                    end;
                }
                field(isAcompte; isAcompte)
                {
                    Caption = 'Is Acompte';
                }

            }

            part("Document"; "Recu Document Subpage")
            {
                Caption = 'Document à payer';
                UpdatePropagation = SubPart;
                ApplicationArea = All;
                Visible = isCreated;
                Editable = NOT (Printed);

            }

            part("Paiement"; "Recu Paiement Subpage")
            {
                Caption = 'Liste Paiements';
                UpdatePropagation = SubPart;
                ApplicationArea = All;
                Visible = isCreated;
                Editable = NOT (Printed);

            }

            group(Totaux)
            {
                Editable = NOT (Printed);
                Visible = NOT (modifCustomer);

                field("totalReçu"; "totalReçu")
                {
                    ApplicationArea = all;
                    Caption = 'Total Paiement';
                    Editable = false;
                }
                field(totalDepense; totalDepense)
                {
                    ApplicationArea = all;
                    Caption = 'Total Dépense';
                    Editable = false;
                }
                field(totalDocToPay; totalDocToPay)
                {
                    ApplicationArea = all;
                    Caption = 'Total document à payer';
                    Editable = false;
                }
                field("totalRéglement"; "totalRéglement")
                {
                    ApplicationArea = all;
                    Caption = 'Total Réglement';
                    Editable = false;
                }
            }


        }
    }

    actions
    {
        area(Processing)
        {

            action(Imprimer)
            {
                ApplicationArea = All;
                Image = Print;
                trigger OnAction()
                VAR
                    recuCaisse: Record "Recu Caisse";
                    recuPaiement: Record "Recu Caisse Paiement";
                begin
                    CurrPage.Update(true);
                    if (totalDocToPay <> "totalRéglement") AND (isAcompte = false)
                    then begin
                        if (totalDocToPay > "totalRéglement") then begin
                            if Confirm('Une différence de paiement de %1 TND, voulez vous considèrer cette différence comme remise ?', false, "totalRéglement" - totalDocToPay) then begin
                                recuPaiement.Reset();
                                recuPaiement."No Recu" := No;
                                recuPaiement."Line No" := recuPaiement.incrementNo(No);
                                recuPaiement.type := recuPaiement.type::"Remise";
                                recuPaiement.Montant := totalDocToPay - "totalRéglement";
                                recuPaiement."Montant Calcul" := totalDocToPay - "totalRéglement";
                                recuPaiement.Insert();
                                CurrPage.Paiement.Page.Update();
                                Commit();
                                setDocumentSolde(rec);
                                if (user = '') then
                                    Error('Vous devez sélectionner le code vendeur !') else begin
                                    CurrPage.Update(true);
                                    CurrPage.SETSELECTIONFILTER(recuCaisse);
                                    REPORT.RUNMODAL(REPORT::"Recu Caisse", TRUE, TRUE, recuCaisse);
                                end;
                            end
                            else begin
                                Error('Veuillez vérifier le montant total des règlements (doit être égal à %1)', totalDocToPay);
                            end;

                        end
                        else begin
                            if Confirm('Une différence de paiement de %1 TND, voulez vous considèrer cette différence comme complément de paiement ?', false, "totalRéglement" - totalDocToPay) then begin
                                recuPaiement.Reset();
                                recuPaiement."No Recu" := No;
                                recuPaiement."Line No" := recuPaiement.incrementNo(No);
                                recuPaiement.type := recuPaiement.type::"Complement";
                                recuPaiement.Montant := "totalRéglement" - totalDocToPay;
                                recuPaiement."Montant Calcul" := totalDocToPay - "totalRéglement";
                                recuPaiement.Insert();
                                CurrPage.Paiement.Page.Update();
                                Commit();
                                setDocumentSolde(rec);
                                if (user = '') then
                                    Error('Vous devez sélectionner le code vendeur !') else begin
                                    CurrPage.Update(true);
                                    CurrPage.SETSELECTIONFILTER(recuCaisse);
                                    REPORT.RUNMODAL(REPORT::"Recu Caisse", TRUE, TRUE, recuCaisse);
                                end;
                            end
                            else begin
                                Error('Veuillez vérifier le montant total des règlements (doit être égal à %1)', totalDocToPay);
                            end;
                        end;
                    end else begin
                        Commit();
                        setDocumentSolde(rec);
                        if (user = '') then
                            Error('Vous devez sélectionner le code vendeur !') else begin
                            CurrPage.Update(true);
                            CurrPage.SETSELECTIONFILTER(recuCaisse);
                            REPORT.RUNMODAL(REPORT::"Recu Caisse", TRUE, TRUE, recuCaisse);
                        end;
                    end;
                end;
            }

            action("Modifier Client")
            {
                ApplicationArea = All;
                Image = Customer;

                trigger OnAction()

                begin
                    modifCustomer := true;
                    if (Printed = true) then begin
                        if (testForModifPrinted < 3) then begin
                            testForModifPrinted := testForModifPrinted + 1;
                        end
                        else
                            if (testForModifPrinted = 3) then begin
                                Printed := false;
                                CurrPage.Update(true);
                                testForModifPrinted := 0;
                            end;
                    end;

                end;
            }

            action("Modifier Reçu")
            {
                ApplicationArea = All;
                Image = DocumentEdit;
                Visible = userSetupModifRC;

                trigger OnAction()

                begin
                    Printed := false;
                    CurrPage.Update(true);
                end;
            }

            action("Update Totaux")
            {
                ApplicationArea = all;
                Image = NewSum;
                trigger OnAction()
                begin
                    rec.CalcFields(totalDocToPay, "totalReçu", totalDepense, "totalRéglement");
                    CurrPage.Update();
                end;
            }
        }
    }

    var
        modifCustomer, isCreated, userSetupModifRC : Boolean;
        testForModifPrinted: Integer;

    trigger OnOpenPage()
    var
        recUserSetup: Record "User Setup";
    begin
        testForModifPrinted := 0;
        recUserSetup.Reset();
        // recUserSetup.SetFilter("User ID", UserId);
        recUserSetup.Get(UserId);
        userSetupModifRC := recUserSetup.isRCModify;
        CurrPage.Update();
        if (Printed = true) then begin
            // if recUserSetup.isRCModify = false then
            CurrPage.Editable := recUserSetup.isRCModify;
            isCreated := true;
        end;
        CurrPage.Document.Page.setFilter(rec);
        CurrPage.Paiement.Page.setFilter(rec);
        modifCustomer := true;
        if (rec."Customer No" <> '') then modifCustomer := false;
        rec.CalcFields(totalDocToPay, "totalReçu", totalDepense, "totalRéglement");

        if (No <> '') then isCreated := true;
    end;

    trigger OnAfterGetRecord()
    begin
        CurrPage.Document.Page.setFilter(rec);
        CurrPage.Paiement.Page.setFilter(rec);
        rec.CalcFields(totalDocToPay, "totalReçu", totalDepense, "totalRéglement");
    end;

    procedure setDocumentSolde(recRecu: Record "Recu Caisse")
    var
        recRecuDoc: Record "Recu Caisse Document";
        recBs: Record "Entete archive BS";
        recInvoice: Record "Sales Invoice Header";
        recCrMemo: Record "Sales Cr.Memo Header";
        recRetourBS: Record "Return Receipt Header";
        recBL: Record "Sales Shipment Header";
        recRetourBL: Record "Return Receipt Header";
        recPurchInvHead: Record "Purch. Inv. Header";
        recCrMemoHead: Record "Purch. Cr. Memo Hdr.";
    begin
        recRecuDoc.Reset();
        recRecuDoc.SetRange("No Recu", recRecu.No);
        if recRecuDoc.FindSet() then begin
            repeat
                case recRecuDoc.type of
                    "Document Caisse Type"::BS:
                        begin
                            recBs.Reset();
                            recbs.get(recRecuDoc."Document No");
                            if recBs.Find() then begin
                                recBs.CalcFields("Montant TTC", "Montant reçu caisse");
                                if recBs."Montant TTC" = recBs."Montant reçu caisse" then begin
                                    recbs.Solde := true;

                                end
                                else
                                    recBs.Solde := false;
                                recBs.Modify();
                            end;
                            Commit();
                        end;
                    "Document Caisse Type"::Invoice:
                        begin
                            recInvoice.Reset();
                            recInvoice.get(recRecuDoc."Document No");
                            if recInvoice.Find() then begin
                                recInvoice.CalcFields("Amount Including VAT", "Montant reçu caisse");
                                if recInvoice."Amount Including VAT" + recInvoice."STStamp Amount" = recInvoice."Montant reçu caisse" then begin
                                    recInvoice.Solde := true;

                                end
                                else
                                    recInvoice.solde := false;
                                recInvoice.Modify();
                            end;
                            Commit();
                        end;
                    "Document Caisse Type"::CreditMemo:
                        begin
                            recCrMemo.Reset();
                            recCrMemo.get(recRecuDoc."Document No");
                            if recCrMemo.Find() then begin
                                recCrMemo.CalcFields("Amount Including VAT", "Montant reçu caisse");
                                if recCrMemo."Amount Including VAT" = -recCrMemo."Montant reçu caisse" then begin
                                    recCrMemo.Solde := true;

                                end
                                else
                                    recCrMemo.solde := false;
                                recCrMemo.Modify();
                            end;
                            Commit();
                        end;
                    "Document Caisse Type"::RetourBS:
                        begin
                            recRetourBS.Reset();
                            recRetourBS.get(recRecuDoc."Document No");
                            if recRetourBS.Find() then begin
                                recRetourBS.CalcFields("Line Amount", "Montant reçu caisse");
                                if recRetourBS."Line Amount" = -recRetourBS."Montant reçu caisse" then begin
                                    recRetourBS.Solde := true;

                                end
                                else
                                    recRetourBS.solde := false;
                                recRetourBS.Modify();

                            end;
                            Commit();
                        end;
                    "Document Caisse Type"::BL:
                        begin
                            recBL.Reset();
                            recBL.get(recRecuDoc."Document No");
                            if recBL.Find() then begin
                                recBL.CalcFields("Line Amount", "Montant reçu caisse");
                                if recBL."Line Amount" = recBL."Montant reçu caisse" then begin
                                    recBL.Solde := true;
                                end
                                else
                                    recBL.solde := false;
                                recBL.Modify();

                            end;
                            Commit();
                        end;
                    "Document Caisse Type"::RetourBL:
                        begin
                            recRetourBL.Reset();
                            recRetourBL.get(recRecuDoc."Document No");
                            if recRetourBL.Find() then begin
                                recRetourBL.CalcFields("Line Amount", "Montant reçu caisse");
                                if recRetourBL."Line Amount" = -recRetourBL."Montant reçu caisse" then begin
                                    recRetourBL.Solde := true;

                                end
                                else
                                    recRetourBL.solde := false;
                                recRetourBL.Modify();

                            end;
                            Commit();
                        end;
                    "Document Caisse Type"::FA:
                        begin
                            recPurchInvHead.Reset();
                            recPurchInvHead.Get(recRecuDoc."Document No");
                            if recPurchInvHead.Find() then begin
                                recPurchInvHead.CalcFields("Amount Including VAT", "Montant reçu caisse");
                                if ((recPurchInvHead."Amount Including VAT" + recPurchInvHead."STStamp Fiscal Amount") = -recPurchInvHead."Montant reçu caisse") then begin
                                    recPurchInvHead.solde := true;
                                end
                                else
                                    recPurchInvHead.solde := false;
                                recPurchInvHead.Modify();
                            end;
                            Commit();
                        end;
                    "Document Caisse Type"::AVA:
                        begin
                            recCrMemoHead.Reset();
                            recCrMemoHead.get(recRecuDoc."Document No");
                            if recCrMemoHead.Find() then begin
                                recCrMemoHead.CalcFields("Amount Including VAT", "Montant reçu caisse");
                                if (recCrMemoHead."Amount Including VAT" = recCrMemoHead."Montant reçu caisse") then begin
                                    recCrMemoHead.solde := true;
                                end
                                else
                                    recCrMemoHead.solde := false;
                                recCrMemoHead.Modify();
                            end;
                            Commit();
                        end;
                end;
            until recRecuDoc.Next() = 0;
        end
    end;

    procedure setSubPartVisible(recuPage: page "Recu Caisse Card")
    begin
        isCreated := true;
        recuPage.Update();
    end;

}