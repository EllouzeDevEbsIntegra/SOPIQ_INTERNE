// Lancement manuel du renommage des references fabricants, dans la societe ouverte.
//
// Toute la regle est dans la codeunit 50032, ce report n'est qu'un ecran de lancement.
// Pour traiter les quatre societes en une fois, passer par Invoke-NAVCodeunit sur le
// serveur (voir l'en-tete de la codeunit 50032 et le script outils/renommer-refs.ps1).
//
// Le resultat detaille est toujours ecrit dans la table 50024 "Log Renommage Refs".
report 25006155 "Renommer Refs Fabricants"
{
    Caption = 'Renommer les references fabricants';
    ProcessingOnly = true;
    UsageCategory = Administration;
    ApplicationArea = All;

    dataset
    {
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                group(Options)
                {
                    Caption = 'Options';

                    field(FabricantsFiltre; FabricantsFiltre)
                    {
                        ApplicationArea = All;
                        Caption = 'Fabricants';
                        ToolTip = 'Codes fabricants separes par |. Par defaut LuK, FAG, INA et Vitesco.';
                    }
                    field(Simulation; Simulation)
                    {
                        ApplicationArea = All;
                        Caption = 'Simulation (aucune modification)';
                        ToolTip = 'Coche : compte les references sans rien modifier. Decoche : renomme reellement.';
                    }
                }
            }
        }

        trigger OnOpenPage()
        var
            RenommerRefs: Codeunit "Renommer Refs Fabricants";
        begin
            if FabricantsFiltre = '' then
                FabricantsFiltre := CopyStr(RenommerRefs.FabricantsParDefautTexte(), 1, MaxStrLen(FabricantsFiltre));
            Simulation := true;
        end;
    }

    trigger OnPostReport()
    var
        Log: Record "Log Renommage Refs";
        RenommerRefs: Codeunit "Renommer Refs Fabricants";
        Debut: DateTime;
        NbRenommes: Integer;
        NbCollisions: Integer;
        NbSimules: Integer;
        TexteResultat: Label 'Fabricants %1\Renommees : %2\Collisions laissees telles quelles : %3\Simulees : %4\\Detail dans la table 50024 Log Renommage Refs.';
    begin
        Debut := CurrentDateTime();
        RenommerRefs.Executer(FabricantsFiltre, Simulation);

        Log.SetFilter("Date Heure", '>=%1', Debut);
        Log.SetRange(Statut, Log.Statut::Renomme);
        NbRenommes := Log.Count();
        Log.SetRange(Statut, Log.Statut::Collision);
        NbCollisions := Log.Count();
        Log.SetRange(Statut, Log.Statut::Simule);
        NbSimules := Log.Count();

        Message(TexteResultat, FabricantsFiltre, NbRenommes, NbCollisions, NbSimules);
    end;

    var
        FabricantsFiltre: Text[250];
        Simulation: Boolean;
}
