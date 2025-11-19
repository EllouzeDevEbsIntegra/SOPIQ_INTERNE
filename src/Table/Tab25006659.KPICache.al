table 25006659 "KPI Cache" //25006600       25006659       TableData 
{
    Caption = 'KPI Cache';
    DataClassification = ToBeClassified;

    fields
    {
        field(1; "Entry No."; BigInteger)
        {
            Caption = 'N° séquentiel';
            AutoIncrement = true;
        }

        field(2; "Date"; Date)
        {
            Caption = 'Date';
        }

        // === FACTURES & AVOIRS (comptabilité) ===
        field(10; "Total Factures Non Réglées"; Decimal)
        {
            Caption = 'Total Factures Non Réglées';
            DecimalPlaces = 0 : 2;
        }
        field(11; "Nb Factures Non Réglées"; Integer)
        {
            Caption = 'Nb Factures Non Réglées';
        }

        field(12; "Total Avoirs Non Réglés"; Decimal)
        {
            Caption = 'Total Avoirs Non Réglés';
            DecimalPlaces = 0 : 2;
        }
        field(13; "Nb Avoirs Non Réglés"; Integer)
        {
            Caption = 'Nb Avoirs Non Réglés';
        }

        // === RÈGLEMENTS CAISSE (RC) ===
        field(20; "Total Fact RC Non Réglées"; Decimal)
        {
            Caption = 'Factures RC Non Réglées';
            DecimalPlaces = 0 : 2;
        }
        field(21; "Total Avoir RC Non Réglés"; Decimal)
        {
            Caption = 'Avoirs RC Non Réglés';
            DecimalPlaces = 0 : 2;
        }
        field(22; "Total BL Non Réglés RC"; Decimal)
        {
            Caption = 'BL Non Réglés RC';
            DecimalPlaces = 0 : 2;
        }
        field(23; "Total BS Non Réglés RC"; Decimal)
        {
            Caption = 'BS Non Réglés RC';
            DecimalPlaces = 0 : 2;
        }
        field(24; "Total Retour BL RC"; Decimal)
        {
            Caption = 'Retour BL Non Réglés RC';
            DecimalPlaces = 0 : 2;
        }
        field(25; "Total Retour BS RC"; Decimal)
        {
            Caption = 'Retour BS Non Réglés RC';
            DecimalPlaces = 0 : 2;
        }

        // === LITIGES & AJUSTEMENTS ===
        field(30; "Valeur Litige +"; Decimal)
        {
            Caption = 'Litige + (valeur)';
            DecimalPlaces = 0 : 2;
        }
        field(31; "Valeur Litige -"; Decimal)
        {
            Caption = 'Litige - (valeur)';
            DecimalPlaces = 0 : 2;
        }
        field(32; "Valeur Endommagé"; Decimal)
        {
            Caption = 'Endommagé (valeur)';
            DecimalPlaces = 0 : 2;
        }
        field(33; "Ajustement Positif"; Decimal)
        {
            Caption = 'Ajust. positif (coût)';
            DecimalPlaces = 0 : 2;
        }
        field(34; "Ajustement Négatif"; Decimal)
        {
            Caption = 'Ajust. négatif (coût)';
            DecimalPlaces = 0 : 2;
        }

        // === CHÈQUES & TRAITES ===
        field(40; "Chèques en Coffre"; Decimal)
        {
            Caption = 'Total Chèques en Coffre';
            DecimalPlaces = 0 : 2;
        }
        field(41; "Chèques Impayés"; Decimal)
        {
            Caption = 'Total Chèques Impayés';
            DecimalPlaces = 0 : 2;
        }
        field(42; "Traites en Coffre"; Decimal)
        {
            Caption = 'Total Traites en Coffre';
            DecimalPlaces = 0 : 2;
        }
        field(43; "Traites Escompte"; Decimal)
        {
            Caption = 'Total Traites Escompte';
            DecimalPlaces = 0 : 2;
        }
        field(44; "Traites Impayées"; Decimal)
        {
            Caption = 'Total Traites Impayées';
            DecimalPlaces = 0 : 2;
        }

        // === VENTES DU JOUR ===
        field(50; "Ventes du Jour"; Decimal)
        {
            Caption = 'Ventes du Jour (TTC)';
            DecimalPlaces = 0 : 2;
        }
        field(51; "Retours du Jour"; Decimal)
        {
            Caption = 'Retours du Jour (TTC)';
            DecimalPlaces = 0 : 2;
        }

        // === MÉTA-DONNÉES ===
        field(100; "Last Calculated"; DateTime)
        {
            Caption = 'Dernier calcul';
        }
        field(101; "Calculated By"; Code[50])
        {
            Caption = 'Calculé par';
        }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
        key(DateKey; "Date") { }
    }

    trigger OnInsert()
    begin
        "Last Calculated" := CurrentDateTime;
        "Calculated By" := UserId;
    end;

    trigger OnModify()
    begin
        "Last Calculated" := CurrentDateTime;
        "Calculated By" := UserId;
    end;
}