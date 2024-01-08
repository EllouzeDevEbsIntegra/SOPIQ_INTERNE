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
                    reportRecette: Report 50238;
                begin
                    reportRecette.Run();
                end;
            }
        }
    }

    var
        myInt: Integer;

    trigger OnAfterGetRecord()
    begin
        rec.CalcFields(totalDocToPay, "totalReçu", totalDepense, "totalRéglement");
    end;
}