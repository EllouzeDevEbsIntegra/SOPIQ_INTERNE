page 50131 "Recu de caisse"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "Recu Caisse";
    SourceTableView = sorting(No) order(descending);
    CardPageId = "Recu Caisse Card";
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = false;
    Permissions = tabledata "Recu Caisse Document" = rimd;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                field(No; No)
                {
                    ApplicationArea = All;
                    Caption = 'N° Reçu';
                    Editable = false;
                }

                field("Customer No"; "Customer No")
                {
                    ApplicationArea = all;
                    Caption = 'Client';
                    Editable = false;
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
                    Caption = 'Date d''Ajout';
                    Editable = false;
                }

                field(dateRecu; dateRecu)
                {
                    ApplicationArea = all;
                    Caption = 'Date Reçu';
                    Editable = false;
                }

                field(user; user)
                {
                    ApplicationArea = all;
                    Caption = 'Code Vendeur';
                    Editable = false;
                }

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

                field(totalDepense; totalDepense)
                {
                    ApplicationArea = all;
                    Caption = 'Total Dépense';
                    Editable = false;
                }

                field("totalRéglement"; "totalRéglement")
                {
                    ApplicationArea = all;
                    Caption = 'Total Réglement';
                    Editable = false;
                }

                field(isAcompte; isAcompte)
                {
                    ApplicationArea = all;
                    Caption = 'Is Acompte';
                    Editable = false;
                }

                field(Printed; Printed)
                {
                    ApplicationArea = all;
                    Caption = 'Imprimé';
                    Editable = false;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action("Imprimer Etat Recette")
            {
                ApplicationArea = All;
                Image = Print;

                trigger OnAction()
                var
                    reportRecette: Report "Etat Recu Caisse";
                    recuDocument: Record "Recu Caisse Document";
                begin
                    recuDocument.SetRange(type, 0);
                    recuDocument.SetRange("Customer No", '');
                    if recuDocument.FindSet() then begin
                        repeat
                            recuDocument.Delete();
                        until recuDocument.Next() = 0;
                    end;
                    Commit();
                    reportRecette.Run();
                end;
            }
            action("Liste Paiements Caisse")
            {
                ApplicationArea = all;
                Image = Payment;
                RunObject = page "Liste Paiement Caisse";
            }
            action("Liste Documents Caisse")
            {
                ApplicationArea = all;
                Image = Documents;
                RunObject = page "Liste document Caisse";
            }
            action("Régler Plusieurs BS")
            {
                ApplicationArea = all;
                Image = PaymentJournal;
                RunObject = page "BS Paiement";
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        Rec.CalcFields(totalDocToPay, "totalReçu", totalDepense, "totalRéglement");
    end;

}