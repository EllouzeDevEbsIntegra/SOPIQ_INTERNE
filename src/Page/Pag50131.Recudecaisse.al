page 50131 "Recu de caisse"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "Recu Caisse";
    CardPageId = "Recu Caisse Card";

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
                    Caption = 'Date et Heure';
                    Editable = false;
                }

                field(user; user)
                {
                    ApplicationArea = all;
                    Caption = 'Code Vendeur';
                    Editable = true;
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

                field(isAcompte; isAcompte)
                {
                    ApplicationArea = all;
                    Caption = 'Is Acompte';
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
}