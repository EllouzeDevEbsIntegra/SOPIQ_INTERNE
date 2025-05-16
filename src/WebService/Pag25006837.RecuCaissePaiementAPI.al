page 25006837 "Recu Caisse Paiement API"
{
    Caption = 'Recu Caisse Paiement API';
    PageType = API;
    SourceTable = "Recu Caisse Paiement";
    APIPublisher = 'sopiq';
    APIGroup = 'interne';
    APIVersion = 'v1.0';
    EntityName = 'recuCaissePaiementAPI';
    EntitySetName = 'recuCaissePaiementAPI';
    DelayedInsert = true;
    ODataKeyFields = "No Recu", "Line No";

    layout
    {
        area(Content)
        {
            group("Paiement")
            {
                field(NoRecu; "No Recu") { Caption = 'N° Reçu'; }
                field(LineNo; "Line No") { Caption = 'N° Ligne'; }
                field(type; type)
                {
                    Caption = 'Type Paiement';
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
                field(Name; Name) { Caption = 'Nom'; }
                field(PaimentNo; "Paiment No") { Caption = 'N° Paiement'; }
                field(Montant; Montant)
                {
                    Caption = 'Montant';
                    trigger OnValidate()
                    begin
                        if (type = type::AvoirEsp) OR (type = type::Depense) OR (type = type::retourBS)
                         OR (type = type::ResteCheque) OR (type = type::Transport)
                         then
                            "Montant Calcul" := -Montant
                        else
                            "Montant Calcul" := Montant;
                        //Modify();
                    end;
                }
                field(Echeance; Echeance) { Caption = 'Échéance'; }
                field(banque; banque) { Caption = 'Banque'; }
                field(MontantCalcul; "Montant Calcul") { Caption = 'Montant Calculé'; }
            }
        }
    }
    var

        isEditable: Boolean;
}
