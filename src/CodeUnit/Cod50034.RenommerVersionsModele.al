// Renommage en lot des versions de modele Mercedes de 3S AGENCE.
//
// Regle, decidee le 28/09/2026 :
//   - societe 3S AGENCE, et elle seule ;
//   - type d'article "Modele Version" ;
//   - marque Mercedes ;
//   - numero de six chiffres, rien d'autre.
//   Le numero prend alors un point entre le troisieme et le quatrieme chiffre :
//   204002 devient 204.002.
//
// Pourquoi. Le meme numero peut designer une piece dans une societe et un vehicule dans
// une autre : 204002 valait "Vanne EGR" dans SOPIQ PROD et "C 220 CDI" dans 3S AGENCE. Le
// traitement des Item Master allait recopier la piece sur le vehicule. La version 1.0.8.0
// empeche l'ecrasement ; ce renommage separe les deux mondes a la source.
//
// Le renommage passe par Item.Rename : Business Central reporte le nouveau numero sur tout
// ce qui porte une relation vers l'article. Les tables qui n'en ont pas gardent l'ancien
// numero, en silence. Mesure du 28/09/2026 avant lancement : aucune ligne concernee dans
// "Specific Item Ledger Entry", et les treize lignes de "items Master" appartiennent toutes
// a 3S AGENCE. Script de controle : docs/sql/detection-refs-vehicules-non-cascadees.sql
//
// Collision : si le numero pointe existe deja, la fiche est journalisee et laissee telle
// quelle. Aucune fusion, c'est une decision metier. Mesure avant lancement : zero collision
// sur les 850 fiches.
//
// Deux facons de lancer :
//   - depuis le serveur, sans interface :
//       Invoke-NAVCodeunit -ServerInstance BC160 -CompanyName '3S AGENCE' `
//                          -CodeunitId 50034 -MethodName Simuler
//     puis la meme chose avec -MethodName Renommer ;
//   - en appelant Simuler ou Renommer depuis la societe ouverte.
//   Dans les deux cas le resultat se lit dans la table 50024 "Log Renommage Refs".
//
// Chaque fiche est validee immediatement apres son renommage. Le traitement peut donc etre
// interrompu et relance sans rien perdre : une fiche deja renommee porte un point, elle ne
// fait plus six chiffres et n'est plus candidate.
codeunit 50034 "Renommer Versions Modele"
{
    Permissions = tabledata Item = rm,
                  tabledata "Log Renommage Refs" = rim;

    var
        SocieteAutorisee: Label '3S AGENCE', Locked = true;
        MarqueVisee: Label 'MERCEDES-BENZ', Locked = true;
        DebutExecution: DateTime;
        SocieteErr: Label 'Ce traitement ne concerne que la société %1. Société ouverte : %2.', Comment = '%1 société attendue, %2 société ouverte';

    // Compte sans rien modifier, et journalise ce qui serait fait.
    procedure Simuler()
    begin
        Executer(true);
    end;

    // Renomme reellement.
    procedure Renommer()
    begin
        Executer(false);
    end;

    procedure Executer(Simulation: Boolean)
    var
        Item: Record Item;
        ItemARenommer: Record Item;
        ItemCible: Record Item;
        Log: Record "Log Renommage Refs";
        ARenommer: List of [Code[20]];
        AncienNo: Code[20];
        NouveauNo: Code[20];
    begin
        // Les versions de modele existent aussi, en petit nombre, dans les societes de
        // pieces, ou elles sont arrivees par le traitement des Item Master. Elles ne
        // relevent pas de ce chantier : on refuse de tourner ailleurs qu'en 3S AGENCE.
        if CompanyName() <> SocieteAutorisee then
            Error(SocieteErr, SocieteAutorisee, CompanyName());

        // Toutes les lignes d'un meme passage portent la meme valeur : le recapitulatif
        // distingue ainsi deux executions faites le meme jour.
        DebutExecution := CurrentDateTime();

        Item.SetRange("Item Type", Item."Item Type"::"Model Version");
        Item.SetRange("Make Code", CopyStr(MarqueVisee, 1, MaxStrLen(Item."Make Code")));
        if Item.FindSet() then
            repeat
                if EstConcernee(Item."No.") then
                    ARenommer.Add(Item."No.");
            until Item.Next() = 0;

        // La liste est constituee avant de renommer : on ne modifie pas une table pendant
        // qu'on la parcourt.
        foreach AncienNo in ARenommer do begin
            NouveauNo := NumeroPointe(AncienNo);

            if ItemCible.Get(NouveauNo) then
                Journaliser(AncienNo, NouveauNo, Log.Statut::Collision, Simulation)
            else
                if Simulation then
                    Journaliser(AncienNo, NouveauNo, Log.Statut::Simule, Simulation)
                else begin
                    ItemARenommer.Get(AncienNo);
                    ItemARenommer.Rename(NouveauNo);

                    // "N° 2" porte une copie du numero, posee par le traitement des Item
                    // Master. Ce n'est pas une relation : le renommage ne l'atteint pas et
                    // la fiche garderait l'ancien numero dans ce champ. Or ce numero
                    // designe une piece dans une autre societe, c'est justement ce qu'on
                    // cherche a separer. Le balayage du 28/09/2026 n'a trouve que cette
                    // colonne, avec "Item Unit of Measure" que BC met a jour seul.
                    if ItemARenommer."No. 2" = AncienNo then begin
                        ItemARenommer."No. 2" := NouveauNo;
                        ItemARenommer.Modify();
                    end;

                    Journaliser(AncienNo, NouveauNo, Log.Statut::Renomme, Simulation);

                    // Validation apres chaque fiche, comme le ferait un utilisateur qui
                    // renomme un article. Sans cela toute la societe tient dans une seule
                    // transaction : les verrous s'accumulent, les autres traitements sont
                    // bloques, et la moindre erreur annule tout le travail.
                    Commit();
                end;
        end;
    end;

    // Deux conditions, rien d'autre : six caracteres, et tous des chiffres. La marque et le
    // type sont deja filtres par l'appelant.
    procedure EstConcernee(No: Code[20]): Boolean
    var
        Position: Integer;
    begin
        if StrLen(No) <> 6 then
            exit(false);

        for Position := 1 to 6 do
            if (No[Position] < '0') or (No[Position] > '9') then
                exit(false);

        exit(true);
    end;

    // 204002 donne 204.002.
    procedure NumeroPointe(No: Code[20]): Code[20]
    begin
        exit(CopyStr(No, 1, 3) + '.' + CopyStr(No, 4, 3));
    end;

    local procedure Journaliser(AncienNo: Code[20]; NouveauNo: Code[20]; NouveauStatut: Option Renomme,Collision,Simule; Simulation: Boolean)
    var
        Log: Record "Log Renommage Refs";
    begin
        Log.Init();
        Log."Date Heure" := CurrentDateTime();
        Log."Execution" := DebutExecution;
        Log."Societe" := CopyStr(CompanyName(), 1, MaxStrLen(Log."Societe"));
        Log."Fabricant" := CopyStr(MarqueVisee, 1, MaxStrLen(Log."Fabricant"));
        Log."Ancien No." := AncienNo;
        Log."Nouveau No." := NouveauNo;
        Log.Statut := NouveauStatut;
        Log.Simulation := Simulation;
        Log."Utilisateur" := CopyStr(UserId(), 1, MaxStrLen(Log."Utilisateur"));
        Log.Insert(true);
    end;
}
