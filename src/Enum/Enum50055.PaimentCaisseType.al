enum 50055 "Paiment Caisse Type"
{
    Extensible = true;
    value(0; null)
    {
        Caption = ' ';
    }
    value(1; Espece)
    {
        Caption = 'Espece';
    }
    value(2; "Cheque")
    {
        Caption = 'Cheque';
    }
    value(3; Traite)
    {
        Caption = 'Traite';
    }

    value(4; TPE)
    {
        Caption = 'TPE';
    }

    value(5; Remise)
    {
        Caption = 'Remise';
    }

    value(6; ResteCheque)
    {
        Caption = 'Reste Cheque';
    }

    value(7; Virement)
    {
        Caption = 'Virement';
    }

    value(8; RS)
    {
        Caption = 'Retenue';
    }

}