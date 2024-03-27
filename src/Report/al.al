report 25006123 "Batch Delete Purch. Line"
{
    // UsageCategory = ReportsAndAnalysis;
    //ApplicationArea = All;
    ProcessingOnly = true;
    Caption = 'Batch de validation';
    Permissions = tabledata "Item Ledger Entry" = rimd,
                  tabledata "Purch. Inv. Line" = rimd,
                  tabledata "Purch. Rcpt. Line" = rimd,
                  tabledata "Purch. Rcpt. Header" = rimd,
                  tabledata "Purchase Line" = rimd,
                  tabledata "Purchase Header" = rimd,
                  tabledata "Detailed Vendor Ledg. Entry" = rimd,
                  tabledata "Vendor Ledger Entry" = rimd,
                  tabledata "Purch. Cr. Memo Line" = rimd,
                  tabledata "Purch. Cr. Memo Hdr." = rimd,
                  tabledata "Payment Line" = rimd;


    // Permission pour l'utilsateur de lire / ecrire / modofier / inserer dans une table 
    // ProcessingOnly = true;  // Pour dire que just c'est un traitement en arrière plan

    dataset
    {
        dataitem("Purch. Inv. Header"; "Purch. Inv. Header")
        {
            RequestFilterFields = "Buy-from Vendor No.";
            trigger OnAfterGetRecord()
            var
                PurchInvLine: Record "Purch. Inv. Line";
                PurchRcptLine: Record "Purch. Rcpt. Line";
                PurchRcptHeader: Record "Purch. Rcpt. Header";
                PurchaseLine: Record "Purchase Line";
                PurchaseHeader: Record "Purchase Header";
                ItemLedgerEntry: Record "Item Ledger Entry";
                DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
                VendorLedgerEntry: Record "Vendor Ledger Entry";
                PurchCrMemoLine: Record "Purch. Cr. Memo Line";
                PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
                PaymentLine: Record "Payment Line";
            begin
                Window.Update(1, "No.");
                PurchInvLine.Reset();
                PurchInvLine.SetRange("Document No.", "No.");
                if PurchInvLine.FindSet() then begin
                    repeat

                        //Message(PurchInvLine.Description);
                        if PurchInvLine.Type = PurchaseLine.Type::" " then PurchInvLine.Delete();
                    until PurchInvLine.Next() = 0;
                end;

                PurchInvLine.Reset();
                PurchInvLine.SetRange("Document No.", "No.");
                if PurchInvLine.Count > 1 then begin
                    if PurchInvLine.FindSet() then begin
                        repeat
                            if (PurchInvLine."Line No." > 20000) then begin
                                Window.Update(2, PurchInvLine."Line No.");
                                SLEEP(20);

                                // Réception rectour Achat enregistré
                                PurchRcptLine.Reset();
                                PurchRcptLine.SetRange("Document No.", PurchInvLine."Receipt No.");
                                if PurchRcptLine.Count > 1 then begin
                                    PurchRcptLine.SetRange("Line No.", PurchInvLine."Receipt Line No.");
                                    if PurchRcptLine.FindFirst() then begin
                                        Window.Update(4, PurchRcptLine."Line No.");
                                        SLEEP(20);
                                        // Item Leadger Entry
                                        ItemLedgerEntry.Reset();
                                        ItemLedgerEntry.SetRange("Document No.", PurchRcptLine."Document No.");
                                        if ItemLedgerEntry.FindFirst() then begin
                                            Window.Update(7, ItemLedgerEntry."Entry No.");
                                            SLEEP(20);
                                            ItemLedgerEntry.Delete();
                                            Commit();
                                        end;

                                        PurchRcptLine.Delete();
                                        Commit();
                                    end;
                                end else begin
                                    PurchRcptLine.SetRange("Line No.", PurchInvLine."Receipt Line No.");
                                    if PurchRcptLine.FindFirst() then begin
                                        Window.Update(4, PurchRcptLine."Line No.");
                                        SLEEP(20);
                                        // Item Leadger Entry
                                        ItemLedgerEntry.Reset();
                                        ItemLedgerEntry.SetRange("Document No.", PurchRcptLine."Document No.");
                                        if ItemLedgerEntry.FindFirst() then begin
                                            Window.Update(7, ItemLedgerEntry."Entry No.");
                                            SLEEP(20);
                                            ItemLedgerEntry.Delete();
                                            Commit();
                                        end;

                                        PurchRcptLine.Delete();
                                        Commit();
                                    end;
                                    PurchRcptHeader.Reset();
                                    PurchRcptHeader.SetRange("No.", PurchRcptLine."Document No.");
                                    if PurchRcptHeader.FindFirst() then begin
                                        Window.Update(3, PurchRcptHeader."No.");
                                        SLEEP(20);
                                        PurchRcptHeader.Delete();
                                        Commit();
                                    end;
                                end;

                                // Commande Achat enregistré
                                PurchaseLine.Reset();
                                PurchaseLine.SetRange("Document No.", PurchInvLine."Order No.");
                                if PurchaseLine.Count > 1 then begin
                                    PurchaseLine.SetRange("Line No.", PurchInvLine."Order Line No.");
                                    if PurchaseLine.FindFirst() then begin
                                        Window.Update(6, PurchaseLine."Line No.");
                                        SLEEP(20);
                                        PurchaseLine.Delete();
                                        Commit();
                                    end;
                                end else begin
                                    PurchaseLine.SetRange("Line No.", PurchInvLine."Order Line No.");
                                    if PurchaseLine.FindFirst() then begin
                                        Window.Update(6, PurchaseLine."Line No.");
                                        SLEEP(20);
                                        PurchaseLine.Delete();
                                        Commit();
                                    end;
                                    PurchaseHeader.Reset();
                                    PurchaseHeader.SetRange("No.", PurchaseLine."Document No.");
                                    if PurchaseHeader.FindFirst() then begin
                                        Window.Update(5, PurchaseHeader."No.");
                                        SLEEP(20);
                                        PurchaseHeader.Delete();
                                        Commit();
                                    end;
                                end;

                                PurchInvLine.Delete();
                                Commit();
                            end;
                        until PurchInvLine.Next() = 0;
                    end;
                end;


                PurchCrMemoLine.Reset();
                PurchCrMemoLine.SetRange("Buy-from Vendor No.", "Buy-from Vendor No.");
                if PurchCrMemoLine.FindSet() then begin
                    repeat
                        Window.Update(9, PurchCrMemoLine."Line No.");
                        SLEEP(20);
                        PurchCrMemoLine.Delete();
                        Commit();
                    until PurchCrMemoLine.Next() = 0;
                end;

                PurchCrMemoHdr.Reset();
                PurchCrMemoHdr.SetRange("Buy-from Vendor No.", "Buy-from Vendor No.");
                if PurchCrMemoHdr.FindSet() then begin
                    repeat
                        Window.Update(8, PurchCrMemoHdr."No.");
                        SLEEP(20);
                        PurchCrMemoHdr.Delete();
                        Commit();
                    until PurchCrMemoHdr.Next() = 0;
                end;

                DetailedVendorLedgEntry.Reset();
                DetailedVendorLedgEntry.SetRange("Vendor No.", "Buy-from Vendor No.");
                if DetailedVendorLedgEntry.FindSet() then begin
                    repeat
                        if DetailedVendorLedgEntry."Document Type" = DetailedVendorLedgEntry."Document Type"::"Credit Memo"
                        then begin
                            Window.Update(11, DetailedVendorLedgEntry."Entry No.");
                            SLEEP(20);
                            DetailedVendorLedgEntry.Delete();
                        end else
                            if DetailedVendorLedgEntry."Document Type" = DetailedVendorLedgEntry."Document Type"::Invoice then begin
                                if DetailedVendorLedgEntry."Document No." = "No." then begin
                                    CalcFields("Amount Including VAT");
                                    DetailedVendorLedgEntry.Amount := -"Amount Including VAT";
                                    DetailedVendorLedgEntry."Amount (LCY)" := -"Amount Including VAT";
                                    DetailedVendorLedgEntry."Debit Amount" := 0;
                                    DetailedVendorLedgEntry."Debit Amount (LCY)" := 0;
                                    DetailedVendorLedgEntry."Credit Amount" := "Amount Including VAT";
                                    DetailedVendorLedgEntry."Credit Amount (LCY)" := "Amount Including VAT";
                                    DetailedVendorLedgEntry.Modify();
                                    Commit();
                                    Window.Update(11, DetailedVendorLedgEntry."Entry No.");
                                    SLEEP(20);
                                end;
                            end else begin
                                Window.Update(11, DetailedVendorLedgEntry."Entry No.");
                                SLEEP(20);
                                DetailedVendorLedgEntry.Delete();
                                Commit();
                            end;


                    until DetailedVendorLedgEntry.Next() = 0;
                end;


                VendorLedgerEntry.Reset();
                VendorLedgerEntry.SetRange("Vendor No.", "Buy-from Vendor No.");
                if VendorLedgerEntry.FindSet() then begin
                    repeat
                        if VendorLedgerEntry."Document Type" = VendorLedgerEntry."Document Type"::"Credit Memo"
                        then begin
                            Window.Update(10, VendorLedgerEntry."Entry No.");
                            SLEEP(20);
                            VendorLedgerEntry.Delete();
                        end else
                            if VendorLedgerEntry."Document Type" = VendorLedgerEntry."Document Type"::Invoice then begin
                                if VendorLedgerEntry."Document No." = "No." then begin
                                    CalcFields("Amount Including VAT");
                                    VendorLedgerEntry.Amount := -"Amount Including VAT";
                                    VendorLedgerEntry."Amount (LCY)" := -"Amount Including VAT";
                                    VendorLedgerEntry."Debit Amount" := 0;
                                    VendorLedgerEntry."Debit Amount (LCY)" := 0;
                                    VendorLedgerEntry."Credit Amount" := "Amount Including VAT";
                                    VendorLedgerEntry."Credit Amount (LCY)" := "Amount Including VAT";
                                    VendorLedgerEntry.Modify();
                                    Commit();
                                    Window.Update(10, VendorLedgerEntry."Entry No.");
                                    SLEEP(20);
                                end;
                            end;

                        VendorLedgerEntry.CalcFields("Remaining Amount");
                        if VendorLedgerEntry."Remaining Amount" = 0 then begin
                            //Message('Here %1', VendorLedgerEntry."Entry No.");
                            VendorLedgerEntry.Delete();
                            Commit();
                        end;
                        VendorLedgerEntry.Open := true;
                    until VendorLedgerEntry.Next() = 0;
                end;

                PaymentLine.Reset();
                PaymentLine.SetRange("Account No.", "Buy-from Vendor No.");
                if PaymentLine.FindSet() then begin
                    repeat
                        PaymentLine.Delete();
                        Commit();
                    until PaymentLine.Next() = 0;
                end;

            end;

            trigger OnPreDataItem()
            begin

                Clear(Counter);
                if not GuiAllowed then
                    exit;
                Window.Open(InvoiceMsgNo);
                //Window.Open(CalculatingLinesMsg + counter);
            end;
        }
    }


    var
        InvoiceMsgNo: Label 'Facture N° #1##################\ Ligne Facture N° #2##################\  Réception N° #3##################\ Ligne Réception N° #4##################\ Commande N° #5##################\ Ligne Commande N° #6##################\ Item Leadger Entry N° #7##################\ Avoir Achat N° #8##################\ Ligne Avoir Achat N° #9##################\ Ecriture Frs N° #10#################\ Ecriture Frs Détaillé N0 ° #11#################\'; //, Comment = '%1 = counter'
        CalculatingLinesMsg: Label 'Calculating deleted lines #1';
        Window: Dialog;
        counter, counter2 : Integer;

}