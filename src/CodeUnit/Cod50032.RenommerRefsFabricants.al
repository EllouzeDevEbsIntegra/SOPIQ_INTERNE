// Renommage en lot des references article de 10 caracteres finissant par 0.
//
// Regle, fournie par le metier et appliquee telle quelle :
//   - uniquement les articles des fabricants indiques (LuK, FAG, INA, Vitesco) ;
//   - si le n d'article fait 10 caracteres, commence par un chiffre ET que le 10e
//     caractere est '0', ce '0' est retire, le n passe a 9 caracteres ;
//   - toute autre reference est ignoree, rien n'est modifie dessus. En particulier les
//     references commencant par une lettre, qui suivent un autre format.
//
// Le renommage passe par Item.Rename : Business Central reporte le nouveau n sur tout
// l'historique (ecritures article et valeur, lignes de documents, prix, stock). La
// codeunit 50031 de cette extension reporte en plus les references externes et les
// fiches fournisseur.
//
// Collision : si le n a 9 caracteres existe deja comme article, la reference est
// journalisee et laissee telle quelle. Aucune fusion, c'est une decision metier.
//
// Deux facons de lancer :
//   - le report 25006155, dans la societe ouverte, avec ecran de lancement ;
//   - Invoke-NAVCodeunit depuis le serveur, societe par societe, sans interface :
//       Invoke-NAVCodeunit -ServerInstance BC160 -CompanyName '3S AGENCE' `
//                          -CodeunitId 50032 -MethodName Simuler
//     puis la meme chose avec -MethodName Renommer. Dans ce mode aucun message ne
//     s'affiche : le resultat se lit dans la table 50024 "Log Renommage Refs".
//
// Chaque appel s'execute dans une seule transaction : en cas d'erreur, la societe
// concernee reste inchangee.
codeunit 50032 "Renommer Refs Fabricants"
{
    Permissions = tabledata Item = rm,
                  tabledata "Log Renommage Refs" = rim;

    var
        FabricantsParDefaut: Label 'FAB0015|FAB0096|FAB0103|FAB0350', Locked = true;
        FabricantPilote: Label 'FAB0350', Locked = true;  // Vitesco, pour l'essai

    // Compte sans rien modifier, et journalise ce qui serait fait.
    procedure Simuler()
    begin
        Executer(FabricantsParDefaut, true);
    end;

    // Renomme reellement.
    procedure Renommer()
    begin
        Executer(FabricantsParDefaut, false);
    end;

    // Essai sur Vitesco seul : 36 references, aucune collision connue.
    procedure SimulerVitesco()
    begin
        Executer(FabricantPilote, true);
    end;

    procedure RenommerVitesco()
    begin
        Executer(FabricantPilote, false);
    end;

    procedure FabricantsParDefautTexte(): Text
    begin
        exit(FabricantsParDefaut);
    end;

    procedure Executer(Fabricants: Text; Simulation: Boolean)
    var
        Item: Record Item;
        ItemARenommer: Record Item;
        ItemCible: Record Item;
        Log: Record "Log Renommage Refs";
        ARenommer: Dictionary of [Code[20], Code[20]];  // ancien n -> code fabricant
        AncienNo: Code[20];
        NouveauNo: Code[20];
    begin
        Item.SetFilter("Manufacturer Code", Fabricants);
        if Item.FindSet() then
            repeat
                if EstConcernee(Item."No.") then
                    ARenommer.Add(Item."No.", Item."Manufacturer Code");
            until Item.Next() = 0;

        foreach AncienNo in ARenommer.Keys() do begin
            NouveauNo := CopyStr(AncienNo, 1, 9);

            if ItemCible.Get(NouveauNo) then
                Journaliser(ARenommer.Get(AncienNo), AncienNo, NouveauNo, Log.Statut::Collision, Simulation)
            else
                if Simulation then
                    Journaliser(ARenommer.Get(AncienNo), AncienNo, NouveauNo, Log.Statut::Simule, Simulation)
                else begin
                    ItemARenommer.Get(AncienNo);
                    ItemARenommer.Rename(NouveauNo);
                    Journaliser(ARenommer.Get(AncienNo), AncienNo, NouveauNo, Log.Statut::Renomme, Simulation);
                end;
        end;
    end;

    // Trois conditions, rien d'autre :
    //   - 10 caracteres ;
    //   - le 10e est '0' ;
    //   - le 1er est un chiffre. Les references commencant par une lettre (FB4EPK8300,
    //     FB6PK13900, etc.) sont des codes d'un autre format, ecartees du traitement.
    procedure EstConcernee(No: Code[20]): Boolean
    begin
        if StrLen(No) <> 10 then
            exit(false);
        if (No[1] < '0') or (No[1] > '9') then
            exit(false);
        exit(CopyStr(No, 10, 1) = '0');
    end;

    local procedure Journaliser(Fabricant: Code[20]; AncienNo: Code[20]; NouveauNo: Code[20]; NouveauStatut: Option Renomme,Collision,Simule; Simulation: Boolean)
    var
        Log: Record "Log Renommage Refs";
    begin
        Log.Init();
        Log."Date Heure" := CurrentDateTime();
        Log."Societe" := CopyStr(CompanyName(), 1, MaxStrLen(Log."Societe"));
        Log."Fabricant" := Fabricant;
        Log."Ancien No." := AncienNo;
        Log."Nouveau No." := NouveauNo;
        Log.Statut := NouveauStatut;
        Log.Simulation := Simulation;
        Log."Utilisateur" := CopyStr(UserId(), 1, MaxStrLen(Log."Utilisateur"));
        Log.Insert(true);
    end;
}
