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
                    Visible = false;
                }
                field("Line No"; "Line No")
                {
                    ApplicationArea = all;
                    Visible = false;
                }
                field(type; type)
                {
                    ApplicationArea = all;
                    trigger OnValidate()
                    begin
                        if (type = type::null) then begin
                            Error('Vous devez spécifier le type de règlement !');
                            isEditable := false;
                        end else begin
                            isEditable := true;
                            if (isDecaissement = true) then "Montant Calcul" := -Montant else "Montant Calcul" := Montant;
                        end;
                        Montant := 0;
                        "Montant Calcul" := 0;
                        isDecaissement := setIsDeciassement(type);
                        // Modify(true);
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
                    trigger OnValidate()
                    begin
                        if (type = type::AvoirEsp) OR (type = type::Depense) OR (type = type::retourBS)
                         OR (type = type::ResteCheque) OR (type = type::Transport)
                         then
                            "Montant Calcul" := -Montant
                        else
                            "Montant Calcul" := Montant;
                        Modify();
                    end;
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

                field("Montant Calcul"; "Montant Calcul")
                {
                    ApplicationArea = all;
                    Caption = 'Mnt Calculé';
                    Editable = false;
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