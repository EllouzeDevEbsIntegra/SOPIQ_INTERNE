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
                            end;
                        end;


                        recCust.Reset();
                        if recCust.get("Customer No") then rec.custName := recCust.Name;
                        modifCustomer := false;
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

                field(user; user)
                {
                    ApplicationArea = all;
                    Caption = 'Code Vendeur';
                    Editable = modifCustomer;
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
                Visible = NOT (modifCustomer);
            }

            part("Paiement"; "Recu Paiement Subpage")
            {
                Caption = 'Liste Paiements';
                UpdatePropagation = SubPart;
                ApplicationArea = All;
                Visible = NOT (modifCustomer);
            }

            group(Totaux)
            {
                Visible = NOT (modifCustomer);
                field(totalDocToPay; totalDocToPay)
                {
                    ApplicationArea = all;
                    Caption = 'Total document à payer';
                    Editable = false;
                }
                field("totalReçu"; "totalReçu")
                {
                    ApplicationArea = all;
                    Caption = 'Total Paiement';
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
                    CurrPage.SETSELECTIONFILTER(recuCaisse);
                    REPORT.RUNMODAL(REPORT::"Recu Caisse", TRUE, FALSE, recuCaisse);
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
        }
    }

    var
        modifCustomer: Boolean;

    trigger OnOpenPage()
    begin
        CurrPage.Document.Page.setFilter(rec);
        CurrPage.Paiement.Page.setFilter(rec);
        modifCustomer := true;
        if (rec."Customer No" <> '') then modifCustomer := false;
    end;

    trigger OnAfterGetRecord()
    begin
        CurrPage.Document.Page.setFilter(rec);
        CurrPage.Paiement.Page.setFilter(rec);
    end;
}