report 25006150 "Batch Update OEM Count"
{
    UsageCategory = ReportsAndAnalysis;
    ApplicationArea = All;
    Caption = 'Mise à jour count oem';
    Permissions = tabledata Item = rm;
    ProcessingOnly = true;  // Pour dire que just c'est un traitement en arrière plan

    dataset
    {
        dataitem(Dummy; Integer)
        {
            DataItemTableView = SORTING(Number) WHERE(Number = CONST(1)); // Exécute une seule fois


            trigger OnPreDataItem()
            var
                recItem, recMaster : Record Item;
                countMaster: Integer;
                API: Codeunit "OEM API Integration";
                count: Integer;
            begin
                recMaster.Reset();
                recMaster.SetRange(Produit, true);
                if recMaster.FindSet() then begin
                    repeat
                        Window.Update(1, recMaster."No.");
                        countMaster := 0;
                        recItem.Reset();
                        recItem.SetRange(Produit, false);
                        recItem.SetRange("Reference Origine Lié", recMaster."No.");
                        recItem.CalcFields(isOem);
                        recItem.SetRange(isOem, true);
                        if recItem.FindSet() then begin
                            repeat
                                Window.Update(2, recItem."No.");
                                // Upadate count in OEM
                                Count := API.GetOEMCount(recItem."No.");
                                Window.Update(3, Format(Count));
                                //Message('Item: %1 - Count: %2', recItem."No.", Count);
                                recItem."Count Item Manual " := Count;
                                recItem.Modify();

                                countMaster := countMaster + count;
                            until recItem.Next() = 0;
                        end;
                        //Message('Master Item: %1 - Count: %2', item."No.", countMaster);
                        // Update count in Master
                        Window.Update(4, Format(countMaster));
                        recMaster."Count Item Manual " := countMaster;
                        recMaster.Modify();
                    until recMaster.Next() = 0;
                end;

            end;





        }
    }



    trigger OnInitReport()
    begin

    end;

    trigger OnPostReport()
    begin
        timeFin := CurrentDateTime();
        duration := timeFin - timedebut;
        Message('Traitement terminé avec succès %1 !', duration);
    end;

    trigger OnPreReport()
    begin
        timedebut := CurrentDateTime();
        if not GuiAllowed then
            exit;
        Window.Open(MasterMsgNo);
    end;

    var
        timedebut: DateTime;
        timeFin: DateTime;
        duration: Duration;
        MasterMsgNo: Label 'MASTER N° #1##################\ OEM N° #2##################\  COUNT OEM #3##################\ COUNT MASTER  #4##################\';
        Window: Dialog;
}