report 25006150 "Batch Update OEM Count"
{
    UsageCategory = ReportsAndAnalysis;
    ApplicationArea = All;
    Caption = 'Mise à jour count oem';
    Permissions = tabledata Item = rm;
    ProcessingOnly = true;  // Pour dire que just c'est un traitement en arrière plan

    dataset
    {
        dataitem(MasterItem; Item)
        {
            DataItemTableView = WHERE(Produit = CONST(true));
            RequestFilterFields = "No.";

            trigger OnAfterGetRecord()
            var
                recItem: Record Item;
                countMaster: Integer;
                API: Codeunit "OEM API Integration";
                count: Integer;
            begin
                if GuiAllowed then
                    Window.Update(1, MasterItem."No.");

                countMaster := 0;
                recItem.Reset();
                recItem.SetRange(Produit, false);
                recItem.SetRange("Reference Origine Lié", MasterItem."No.");
                // Correction: Il est préférable d'utiliser SetFilter pour les FlowFields
                recItem.SetFilter(isOem, '%1', true);
                if recItem.FindSet() then
                    repeat
                        if GuiAllowed then
                            Window.Update(2, recItem."No.");

                        // Upadate count in OEM
                        Count := API.GetOEMCount(recItem."No.");
                        if GuiAllowed then
                            Window.Update(3, Count);

                        recItem."Count Item Manual " := Count;
                        recItem."Count OEM Update Date" := Today();
                        recItem.Modify();

                        countMaster := countMaster + Count;
                        if GuiAllowed then
                            Window.Update(4, countMaster);
                    until recItem.Next() = 0;

                // Update count in Master
                MasterItem."Count Item Manual " := countMaster;
                MasterItem."Count OEM Update Date" := Today();
                MasterItem.Modify();

                // OPTIMISATION: Commit après chaque article maître pour libérer les verrous
                Commit();
                Sleep(100); // Pause pour permettre à d'autres processus de s'exécuter
            end;





        }
    }



    trigger OnInitReport()
    begin

    end;

    trigger OnPostReport()
    begin
        if GuiAllowed then
            Window.Close();
        TimeFin := CurrentDateTime();
        Duration := TimeFin - TimeDebut;
        Message('Traitement terminé avec succès en %1 !', Duration);
    end;

    trigger OnPreReport()
    begin
        TimeDebut := CurrentDateTime();
        if GuiAllowed then
            Window.Open(MasterMsgNo);
    end;

    var
        TimeDebut: DateTime;
        TimeFin: DateTime;
        Duration: Duration;
        MasterMsgNo: Label 'MASTER N° #1##################\ OEM N° #2##################\  COUNT OEM #3##################\ COUNT MASTER  #4##################\';
        Window: Dialog;
}