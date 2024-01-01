report 50233 "Batch Validation"
{
    // UsageCategory = ReportsAndAnalysis;
    //ApplicationArea = All;
    Caption = 'Batch de validation';
    // Permissions = tabledata Item = r,
    //               tabledata "Sales Price" = rimd,
    //               tabledata "Customer Additional Profit" = rimd; // Permission pour l'utilsateur de lire / ecrire / modofier / inserer dans une table 'Artcle' dans ce cas
    // ProcessingOnly = true;  // Pour dire que just c'est un traitement en arrière plan


    trigger OnInitReport()
    var
        jrnlRecl: Record "Item Journal Batch";
    begin
        if jrnlRecl.Get() then begin
            Message('%1 - %2', jrnlRecl."Journal Template Name", jrnlRecl.Description);
        end;
    end;


}