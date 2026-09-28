// Documents non soldes d'un client, tous types confondus, pour l'API du comptoir.
//
// Cette table n'est jamais ecrite en base : la page API 25006868 la declare temporaire et
// la remplit a chaque appel. Elle existe parce qu'une page API n'a qu'une seule table
// source, alors que les documents a payer vivent dans huit tables differentes.
//
// C'est le patron des pages d'etat de Business Central, par exemple
// "Aged Accounts Receivable".
table 70015 "Recu Caisse Doc A Payer"
{
    Caption = 'Document à payer';
    DataClassification = ToBeClassified;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'N° séquentiel';
        }
        field(10; "Customer No"; Code[20])
        {
            Caption = 'Client';
        }
        field(20; type; Enum "Document Caisse Type")
        {
            Caption = 'Type document';
        }
        field(30; "Document No"; Code[20])
        {
            Caption = 'N° document';
        }
        field(40; "Date Document"; Date)
        {
            Caption = 'Date document';
        }
        field(50; Libelle; Text[250])
        {
            Caption = 'Libellé';
        }
        field(60; "Total TTC"; Decimal)
        {
            Caption = 'Montant TTC';
            DecimalPlaces = 0 : 3;
        }
        field(70; "Deja Regle"; Decimal)
        {
            Caption = 'Déjà réglé';
            DecimalPlaces = 0 : 3;
        }
        field(80; "Reste A Payer"; Decimal)
        {
            Caption = 'Reste à payer';
            DecimalPlaces = 0 : 3;
        }
        // -1 pour un avoir ou un retour, qui viennent en deduction, 1 sinon.
        field(90; Signe; Integer)
        {
            Caption = 'Signe';
        }
        // Renseigne uniquement pour le type Impaye : la ligne de paiement d'origine.
        field(100; "Id Ligne Impaye"; Integer)
        {
            Caption = 'N° ligne impayé';
        }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
        key(Client; "Customer No", type, "Document No") { }
    }
}
