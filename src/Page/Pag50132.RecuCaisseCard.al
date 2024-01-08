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
                        isCreated := true;
                        CurrPage.Document.Page.setFilter(rec);
                        CurrPage.Paiement.Page.setFilter(rec);

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
                    Editable = isCreated;
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
                begin
                    Message('%1 - %2 - %3', rec.totalDocToPay, rec."totalReçu", rec.totalDepense);
                    //CurrPage.SetTableView(recuCaisse);
                    if (user = '') then
                        Error('Vous devez sélectionner le code vendeur !') else begin
                        CurrPage.SETSELECTIONFILTER(recuCaisse);
                        CurrPage.Update(true);
                        REPORT.RUNMODAL(REPORT::"Recu Caisse", TRUE, FALSE, recuCaisse);
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
        if (Printed = true) then CurrPage.Editable := false;

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

}