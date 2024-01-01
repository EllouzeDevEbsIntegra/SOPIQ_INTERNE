page 50135 "Recu Paiement Subpage"
{
    PageType = ListPart;
    Caption = 'Liste Paiements';
    SourceTable = "Recu Caisse Paiement";
    InsertAllowed = false;

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
                }
                field("Line No"; "Line No")
                {
                    ApplicationArea = all;
                }
                field(type; type)
                {
                    ApplicationArea = all;
                }

                field(Name; Name)
                {
                    ApplicationArea = all;
                }

                field("Paiment No"; "Paiment No")
                {
                    ApplicationArea = all;
                }

                field(Montant; Montant)
                {
                    ApplicationArea = all;
                }

                field(Echeance; Echeance)
                {
                    ApplicationArea = all;
                }

                field(banque; banque)
                {

                }



            }

        }
    }

    actions
    {
        area(Processing)
        {
            action("Ajouter Paiement")
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    rec."No Recu" := recuNo;
                    rec."Line No" := rec.incrementNo(recuNo);
                    rec.Insert();
                    CurrPage.Update();
                end;

            }
        }
    }

    var
        custNo: code[20];
        recuNo: code[10];

    procedure setFilter(recuCaisse: Record "Recu Caisse")
    begin
        SetFilter("No Recu", recuCaisse.No);
        CurrPage.Update();
        recuNo := recuCaisse.No;
    end;



}