enum 50051 "Quote Line Reason"
{
    Extensible = true;

    value(0; " ")
    {
        Caption = ' ';
    }

    value(1; Price)
    {
        Caption = 'Prix augmenté';
    }
    value(2; "Replaced")
    {
        Caption = 'Remplacé autre fabricant';
    }
    value(3; History)
    {
        Caption = 'Mouvement lent';
    }
    value(4; New)
    {
        Caption = 'Nouveau article';
    }

    value(5; Waiting)
    {
        Caption = 'En attente devis autre fabricant';
    }
    value(6; SurStock)
    {
        Caption = 'Sur Stockage';
    }


}