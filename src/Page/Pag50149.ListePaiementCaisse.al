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
                field("N° Client"; "N° Client")
                {
                    ApplicationArea = all;
                    Caption = 'Code Client';
                    Editable = false;
                    TableRelation = Customer;
                    Visible = true;
                }
                field("Nom Client"; "Nom Client")
                {
                    ApplicationArea = all;
                    Caption = 'Nom Client';
                    Editable = false;
                    Visible = true;
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
                field(Impaye; Impaye)
                {
                    ApplicationArea = all;
                    Caption = 'Impaye';
                    Visible = true;
                }
                field("Date Impaye"; "Date Impaye")
                {
                    ApplicationArea = all;
                    Caption = 'Date Impayé';
                    Visible = true;
                }
                field("Montant reçu caisse"; "Montant reçu caisse")
                {
                    ApplicationArea = all;
                    Caption = 'Montant reçu caisse';
                    Visible = true;
                    trigger OnDrillDown()
                    begin
                        DoDrillDown;
                    end;
                }
                field(solde; solde)
                {
                    ApplicationArea = all;
                    Caption = 'Solde';
                    Visible = true;
                }

            }

        }
    }

    actions
    {
        area(Processing)
        {
            action(setImpaye)
            {
                ApplicationArea = All;
                Caption = 'Marquer Impayé';
                Image = Undo;
                trigger OnAction()
                begin
                    if Confirm('Voulez vous marquer ces paiements comme impayés ?') then begin
                        rec.Impaye := true;
                        rec."Date Impaye" := WorkDate();
                        rec.Modify(true);
                    end;
                end;
            }

        }
    }
    local procedure DoDrillDown()
    var
        recuCaisseDoc: Record "Recu Caisse Document";
    begin
        recuCaisseDoc.SetRange("Document No", rec."No Recu");
        recuCaisseDoc.SetRange("id Ligne Impaye", rec."Line No");
        PAGE.Run(PAGE::"Recu Document List", recuCaisseDoc);
    end;

    trigger OnAfterGetRecord()
    begin
        rec.CalcFields("Montant reçu caisse");
    end;

}