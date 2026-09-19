// Journal du renommage en lot des references fabricants (codeunit 50032).
//
// Une ligne par reference examinee, dans la societe ou le traitement a tourne. Permet
// de controler apres coup ce qui a ete fait, y compris quand le traitement est lance
// par Invoke-NAVCodeunit, ou aucun message ne s'affiche.
table 50024 "Log Renommage Refs"
{
    Caption = 'Journal renommage references';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'N entree';
            AutoIncrement = true;
        }
        field(10; "Date Heure"; DateTime)
        {
            Caption = 'Date et heure';
        }
        field(20; "Societe"; Text[50])
        {
            Caption = 'Societe';
        }
        field(30; "Fabricant"; Code[20])
        {
            Caption = 'Fabricant';
        }
        field(40; "Ancien No."; Code[20])
        {
            Caption = 'Ancienne reference';
        }
        field(50; "Nouveau No."; Code[20])
        {
            Caption = 'Nouvelle reference';
        }
        field(60; Statut; Option)
        {
            Caption = 'Statut';
            OptionMembers = Renomme,Collision,Simule;
            OptionCaption = 'Renomme,Collision,Simule';
        }
        field(70; Simulation; Boolean)
        {
            Caption = 'Simulation';
        }
        field(80; "Utilisateur"; Code[50])
        {
            Caption = 'Utilisateur';
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(Execution; "Date Heure", Statut)
        {
        }
    }
}
