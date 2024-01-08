page 50135 "Recu Paiement Subpage"
{
    PageType = ListPart;
    Caption = 'Liste Paiements';
    SourceTable = "Recu Caisse Paiement";
    InsertAllowed = true;

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
                    //Visible = false;
                }
                field("Line No"; "Line No")
                {
                    ApplicationArea = all;
                    //Visible = false;
                }
                field(type; type)
                {
                    ApplicationArea = all;
                    trigger OnValidate()
                    begin
                        if (type = type::null) then isEditable := false else isEditable := true;
                    end;
                }

                field(Name; Name)
                {
                    ApplicationArea = all;
                    Editable = isEditable;
                }

                field("Paiment No"; "Paiment No")
                {
                    ApplicationArea = all;
                    Editable = isEditable;

                }

                field(Montant; Montant)
                {
                    ApplicationArea = all;
                    Editable = isEditable;

                }

                field(Echeance; Echeance)
                {
                    ApplicationArea = all;
                    Editable = isEditable;

                }

                field(banque; banque)
                {
                    ApplicationArea = all;
                    Editable = isEditable;
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

    var
        custNo: code[20];
        recuNo: code[10];
        isEditable: Boolean;

    procedure setFilter(recuCaisse: Record "Recu Caisse")

    begin
        SetFilter("No Recu", recuCaisse.No);
        CurrPage.Update();
        recuNo := recuCaisse.No;
    end;



}