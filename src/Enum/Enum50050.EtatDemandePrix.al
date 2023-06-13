enum 50050 "Etat Demande Prix"
{
    Extensible = true;

    value(0; encours)
    {
        Caption = 'Encours de traitement';
    }
    value(1; "En attente Validation")
    {
        Caption = 'En attente validation';
    }
    value(2; Valide)
    {
        Caption = 'Validé';
    }

}