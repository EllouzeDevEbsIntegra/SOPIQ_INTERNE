page 50149 "Liste Paiement Caisse"
{
    PageType = List;
    Caption = 'Liste Paiements Caisse';
    SourceTable = "Recu Caisse Paiement";
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    Editable = false;

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
                    DrillDown = true;
                    DrillDownPageId = "Recu Caisse View";
                    Visible = true;
                    trigger OnDrillDown()
                    var
                        recuCaisse: Record "Recu Caisse";
                    begin
                        recuCaisse.SetRange(No, rec."No Recu");
                        PAGE.RUN(PAGE::"Recu Caisse View", recuCaisse);
                    end;
                }
                field("Date Reçu"; "Date Reçu")
                {
                    ApplicationArea = all;
                    Editable = false;
                }
                field("Line No"; "Line No")
                {
                    ApplicationArea = all;
                    Visible = true;
                }
                field(type; type)
                {
                    ApplicationArea = all;
                    Visible = true;
                }

                field(Name; Name)
                {
                    ApplicationArea = all;
                    Visible = true;
                }

                field("Paiment No"; "Paiment No")
                {
                    ApplicationArea = all;
                    Visible = true;
                }

                field(Montant; Montant)
                {
                    ApplicationArea = all;
                    Visible = true;
                }

                field(Echeance; Echeance)
                {
                    ApplicationArea = all;
                    Visible = true;
                }

                field(banque; banque)
                {
                    ApplicationArea = all;
                    Visible = true;
                }

                field("Montant Calcul"; "Montant Calcul")
                {
                    ApplicationArea = all;
                    Caption = 'Mnt Calculé';
                    Visible = true;
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


}