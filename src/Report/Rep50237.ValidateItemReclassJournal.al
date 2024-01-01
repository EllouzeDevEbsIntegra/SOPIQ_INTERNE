report 50237 "Validate Item Reclass. Journal"
{
    Caption = 'Valider feuille reclassement article';
    UsageCategory = ReportsAndAnalysis;
    ProcessingOnly = true;
    UseRequestPage = false;
    ApplicationArea = All;

    trigger OnPreReport()
    begin
        ItemJournalLine.Reset();
        ItemJournalLine.SetRange("LM Ready For Validation", true);
        if ItemJournalLine.FindSet() then begin
            ItemJnlPostBatch.SetSuppressCommit(false);
            ItemJnlPostBatch.Run(ItemJournalLine);
        end;
    end;

    var
        ItemJournalLine: Record "Item Journal Line";
        ItemJnlPostBatch: Codeunit "Item Jnl.-Post Batch";
}