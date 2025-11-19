codeunit 50026 "KPI Cache Job"
{
    trigger OnRun()
    var
        KPIManagement: Codeunit "KPI Management";
    begin
        KPIManagement.UpdateAllKPICache();
        KPIManagement.CleanupOldCache(30); // Garder 30 jours
    end;
}