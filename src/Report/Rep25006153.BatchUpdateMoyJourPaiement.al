report 25006153 "Batch Update Moy Jour Paiement"
{
    UsageCategory = ReportsAndAnalysis;
    ApplicationArea = All;
    Caption = 'Mise à jour du Moyen Jour Paiement des factures vente';
    // Lecture/écriture sur l'entête facture ; lecture sur les lignes de paiement utilisées par le calcul
    Permissions = tabledata "Sales Invoice Header" = rimd,
                  tabledata "Payment Line" = r;
    ProcessingOnly = true; // Just un traitement en arrière plan (planifiable via Job Queue)

    dataset
    {
        dataitem(SalesInvoiceHeader; "Sales Invoice Header")
        {
            // Filtres proposés sur la page de requête / configurables dans la Job Queue
            RequestFilterFields = "No.", "Posting Date", "Sell-to Customer No.";

            trigger OnPreDataItem()
            begin
                ProcessedCount := 0;
                UpdatedCount := 0;
                if GuiAllowed then
                    Window.Open(ProgressTxt);
            end;

            trigger OnAfterGetRecord()
            var
                NewValue: Decimal;
            begin
                ProcessedCount += 1;
                if GuiAllowed then
                    Window.Update(1, "No.");

                // Réutilise la logique métier déjà présente dans la tableextension
                NewValue := SalesInvoiceHeader.MoyJourPaiement(SalesInvoiceHeader);

                // On n'écrit que si la valeur a changé (évite les modifications inutiles)
                if SalesInvoiceHeader."Moy Jour Paiement" <> NewValue then begin
                    SalesInvoiceHeader."Moy Jour Paiement" := NewValue;
                    SalesInvoiceHeader.Modify(false); // Modify(false) : pas de trigger OnModify, plus rapide et sans effet de bord
                    UpdatedCount += 1;
                end;
            end;

            trigger OnPostDataItem()
            begin
                if GuiAllowed then
                    Window.Close();
            end;
        }
    }

    trigger OnPostReport()
    begin
        // Message ignoré automatiquement en contexte Job Queue (GuiAllowed = false)
        if GuiAllowed then
            Message(DoneMsg, ProcessedCount, UpdatedCount);
    end;

    var
        Window: Dialog;
        ProcessedCount: Integer;
        UpdatedCount: Integer;
        ProgressTxt: Label 'Mise à jour du Moyen Jour Paiement...\Facture n°  #1##########';
        DoneMsg: Label 'Traitement terminé.\Factures traitées : %1\Factures mises à jour : %2';
}
