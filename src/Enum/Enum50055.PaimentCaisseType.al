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
    value(5; Virement)
    {
        Caption = 'Virement';
    }

    value(6; Remise)
    {
        Caption = 'Remise';
    }

    value(7; ResteCheque)
    {
        Caption = 'Reste Cheque';
    }
    value(8; AvoirEsp)
    {
        Caption = 'Avoir Esp/Cheque';
    }
    value(9; RS)
    {
        Caption = 'Retenue';
    }

    value(10; Depense)
    {
        Caption = 'Dépense';
    }

    value(11; retourBS)
    {
        Caption = 'Retour BS / BL';
    }

    value(12; Transport)
    {
        Caption = 'Transport';
    }

    value(13; Complement)
    {
        Caption = 'Complément';
    }

    value(14; Divers)
    {
        Caption = 'Divers';
    }
    value(15; Versement)
    {
        Caption = 'Versement';
    }
    value(16; DecCheq)
    {
        Caption = 'Décaissement Chèque';
    }
    value(17; DecTrt)
    {
        Caption = 'Décaissement Traite';
    }
    value(18; DecEsp)
    {
        Caption = 'Décaissement Espèce';
    }
    value(19; DecVir)
    {
        Caption = 'Décaissement Virement';
    }
    value(20; DecVers)
    {
        Caption = 'Décaissement Versement';
    }

}