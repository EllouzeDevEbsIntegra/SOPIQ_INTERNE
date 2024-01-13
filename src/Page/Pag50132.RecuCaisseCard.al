page 50132 "Recu Caisse Card"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "Recu Caisse";

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
                    begin
                        if (xRec."Customer No" = '') then begin
                            recSalesSetup.Get;
                            recSeries.Reset();
                            recSeries.SetRange("Series Code", recSalesSetup."Reçu Caisse Serie");
                            if recSeries.FindLast() then begin
                                rec.No := recSeries.GetNextSequenceNo(true);
                                rec.dateTime := System.CurrentDateTime;
                                rec.dateRecu := System.Today;
                            end;
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
                end;
            }

            action("Modifier Reçu")
            {
                ApplicationArea = All;
                Image = DocumentEdit;
                Visible = false;

                trigger OnAction()

                begin
                    Printed := false;
                    CurrPage.Update(true);
                end;
            }
        }
    }

    var
        modifCustomer, isCreated : Boolean;

    trigger OnOpenPage()
    begin
        if (Printed = true) then begin
            CurrPage.Editable := false;
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
                                recbs.Solde := true;
                                recBs.Modify();
                            end;
                            Commit();
                        end;
                    "Document Caisse Type"::Invoice:
                        begin
                            recInvoice.Reset();
                            recInvoice.get(recRecuDoc."Document No");
                            if recInvoice.Find() then begin
                                recInvoice.Solde := true;
                                recInvoice.Modify();
                            end;
                            Commit();
                        end;
                    "Document Caisse Type"::CreditMemo:
                        begin
                            recCrMemo.Reset();
                            recCrMemo.get(recRecuDoc."Document No");
                            if recCrMemo.Find() then begin
                                recCrMemo.Solde := true;
                                recCrMemo.Modify();
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