page 50151 "Liste Document Caisse"
{
    PageType = List;
    Caption = 'Liste Paiements Caisse';
    SourceTable = "Recu Caisse Document";
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

                field("Customer No"; "Customer No")
                {
                    ApplicationArea = all;
                    Visible = true;
                }

                field("Document No"; "Document No")
                {
                    ApplicationArea = all;
                    Visible = true;
                }

                field("Libelle"; "Libelle")
                {
                    ApplicationArea = all;
                    Visible = true;
                }

                field("Total TTC"; "Total TTC")
                {
                    ApplicationArea = all;
                    Visible = true;
                }

                field("Montant Reglement"; "Montant Reglement")
                {
                    ApplicationArea = all;
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