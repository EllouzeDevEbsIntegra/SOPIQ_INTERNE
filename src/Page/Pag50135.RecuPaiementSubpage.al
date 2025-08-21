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
                        if type = type::RS then begin
                            if Confirm('Cette retenue est-il sur Plateforme TEJ ?') then begin
                                Name := SupprimerSTR(Name, ' ** TEJ **');
                                Name := Name + ' ** TEJ **';
                            end
                            else
                                Name := SupprimerSTR(Name, ' ** TEJ **');

                            rec.Modify();
                        end;
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
                field("Linked Invoice"; "Linked Invoice")
                {
                    ApplicationArea = all;
                    Caption = 'Facture liée';
                    ToolTip = 'Facture liée à ce paiement';
                }



            }

        }
    }

    actions
    {
        area(Processing)
        {
            action("Copier Nom")
            {
                ApplicationArea = All;
                Caption = 'Copier Nom';
                Image = Copy;
                ToolTip = 'Copier le nom du client dans le champ Nom';
                trigger OnAction()
                var
                    recuCaisse: Record "Recu Caisse";
                begin
                    if recuCaisse.Get(recuNo) then begin
                        Name := recuCaisse.custName;
                        Modify(true);
                    end else
                        Error('Reçu non trouvé !');
                end;
            }

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

    procedure SupprimerSTR(TexteOriginal: Text; textASupp: Text): Text
    var
        PositionDebut: Integer;
        PositionFin: Integer;
        PartieAvant: Text;
        PartieApres: Text;
    begin
        PositionDebut := STRPOS(TexteOriginal, textASupp);
        if PositionDebut > 0 then begin
            // Calculer la position après la chaîne
            PositionFin := PositionDebut + STRLEN(textASupp);
            PartieAvant := COPYSTR(TexteOriginal, 1, PositionDebut - 1);
            PartieApres := COPYSTR(TexteOriginal, PositionFin, STRLEN(TexteOriginal));
            exit(PartieAvant + PartieApres);
        end else
            exit(TexteOriginal); // Rien à supprimer
    end;

}