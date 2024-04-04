report 25006126 "Batch Calc. Rcpt Line Ht/TTC"
{
    // // UsageCategory = ReportsAndAnalysis;
    // //ApplicationArea = All;
    ProcessingOnly = true;
    Caption = 'Batch Calc. Rcpt Line Ht/TTC';
    Permissions = tabledata "Purch. Rcpt. Line" = rimd,
                  tabledata "Purch. Rcpt. Header" = rimd;


    // // Permission pour l'utilsateur de lire / ecrire / modofier / inserer dans une table 
    // // ProcessingOnly = true;  // Pour dire que just c'est un traitement en arrière plan
    dataset
    {
        dataitem(pruchRecptLine; "Purch. Rcpt. Line")
        {
            RequestFilterFields = "Document No.";
            trigger OnAfterGetRecord()
            begin
                "Line Amount HT" := "Unit Cost" * Quantity;
                if ("VAT %" <> 0) then
                    "Line Amount" := "Unit Cost" * Quantity * (1 + ("VAT %" / 100)) else
                    "Line Amount" := "Unit Cost" * Quantity;
                Modify();
                Commit();
            end;
        }
    }


}