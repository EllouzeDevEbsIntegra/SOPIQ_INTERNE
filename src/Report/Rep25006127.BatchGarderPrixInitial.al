report 25006127 "Batch Garder Prix Initial"
{
    // // UsageCategory = ReportsAndAnalysis;
    // //ApplicationArea = All;
    ProcessingOnly = true;
    Caption = 'Batch Garder Prix Initial BS';
    Permissions = tabledata "Sales Shipment Line" = rimd,
                  tabledata "Sales Shipment Header" = rimd;


    // // Permission pour l'utilsateur de lire / ecrire / modofier / inserer dans une table 
    // // ProcessingOnly = true;  // Pour dire que just c'est un traitement en arrière plan
    dataset
    {
        dataitem("Sales Shipment Line"; "Sales Shipment Line")
        {
            RequestFilterFields = "Document No.";
            trigger OnAfterGetRecord()
            var
                SalesLine: Record 37;
                salessetup: Record "Sales & Receivables Setup";
            begin
                if (Quantity > 0) AND ("Order No." <> '') then begin
                    salessetup.get;
                    CalcFields(BS);
                    IF BS then begin
                        SalesLine.RESET;
                        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
                        SalesLine.setrange("Document No.", "Order No.");
                        SalesLine.setrange("Line No.", "Order Line No.");
                        SalesLine.SetFilter(Quantity, '>%1', 0);
                        IF SalesLine.FindFirst THEN
                            if (salessetup."Same Price Order/BS" = true) OR (SalesLine."Unit Cost" = 0) then begin
                                "Prix Vente 1" := SalesLine."Unit Price";
                                "Prix Vente 2" := SalesLine."Unit Price" * (1 - (SalesLine."Line Discount %" / 100));
                                "Line Discount %" := SalesLine."Line Discount %";
                                "Montant ligne HT BS" := SalesLine.Amount;
                                "Montant ligne TTC BS" := SalesLine."Amount Including VAT";
                            end else begin
                                "Prix Vente 1" := "Unit Cost" * (1 + (salessetup."Prix de vente 1 % remise" / 100));
                                "Prix Vente 2" := "Prix Vente 1" * (1 - (salessetup."Prix de vente 2 % remise" / 100));
                                "Line Discount %" := SalesSetup."Prix de vente 2 % remise";
                                "Montant ligne HT BS" := ("Prix Vente 2" * Quantity);
                                IF "VAT %" > 0 then
                                    "Montant ligne TTC BS" := ("Prix Vente 2" * Quantity) * (1 + ("VAT %" / 100)) else
                                    "Montant ligne TTC BS" := ("Prix Vente 2" * Quantity);
                            end;
                        "Line Amount Order" := SalesLine."Line Amount";
                        "Quantity Order" := SalesLine.Quantity;
                    end;

                    "% Discount" := SalesLine."Line Discount %";
                    IF SalesLine.Quantity > Quantity then
                        "Line Amount" := (SalesLine."Amount Including VAT" / SalesLine.Quantity) * Quantity else
                        "Line Amount" := SalesLine."Amount Including VAT";
                    IF SalesLine."VAT %" <> 0 then
                        "Line Amount HT" := "Line Amount" / (1 + (SalesLine."VAT %" / 100)) else
                        "Line Amount HT" := "Line Amount";
                    Modify();
                    Commit();
                end;
            end;
        }
    }


}