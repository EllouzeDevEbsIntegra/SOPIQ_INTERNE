codeunit 50019 SubscriberEventProcedure
{
    EventSubscriberInstance = StaticAutomatic;


    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post (Yes/No)", 'OnBeforeConfirmSalesPost', '', true, true)]
    procedure OnBeforeConfirmSalesPost(salesHeader: Record "Sales Header"; HideDialog: Boolean; IsHandled: Boolean; DefaultOption: Integer; PostAndSend: Boolean);
    var
        recSalesLine: Record "Sales Line";
        recSalesHeader: Record "Sales Shipment Header";
        recCrSalesHeader: Record "Return Receipt Header";
        numDoc: TEXT[50];
        SalesFunctions: Codeunit 50021;

    begin
        if (salesHeader."Document Type" = salesHeader."Document Type"::"Credit Memo") then begin
            salesHeader.ignoreStamp(salesHeader);
            salesHeader.Modify(true);
        end;
        recSalesLine.Reset();
        recSalesLine.SetRange("Document No.", salesHeader."No.");
        IF recSalesLine.FINDSET THEN
            REPEAT

                if (recSalesLine.Type = "Sales Line Type"::" ") THEN BEGIN
                    if (salesHeader."Document Type" = salesHeader."Document Type"::Invoice) then begin
                        numDoc := recSalesLine.Description.Substring(16, 11);
                        recSalesHeader.SetRange("No.", numDoc);
                        if recSalesHeader.FindFirst() THEN BEGIN
                            recSalesLine."Description" := recSalesLine.Description + ' Du ' + FORMAT(recSalesHeader."Posting Date");
                            recSalesLine.Modify();
                        END
                    end;

                    if (salesHeader."Document Type" = salesHeader."Document Type"::"Credit Memo") then begin
                        if (StrLen(recSalesLine.Description) > 25) then
                            numDoc := recSalesLine.Description.Substring(22, 11)
                        else
                            numDoc := '';

                        recCrSalesHeader.SetRange("No.", numDoc);
                        if recCrSalesHeader.FindFirst() THEN BEGIN
                            recSalesLine."Description" := recSalesLine.Description + ' Du ' + FORMAT(recCrSalesHeader."Posting Date");
                            recSalesLine.Modify();
                        END;

                    end;
                END
            UNTIL recSalesLine.Next() = 0;


        //@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
        // if (salesHeader."Document Type" = salesHeader."Document Type"::"Return Order") AND (salesHeader.BS = true) then begin
        //     Message('This document is BS Return');

        //     IsHandled := true;
        //     HideDialog := true;
        //     DefaultOption := 1;
        //     SalesFunctions.ConfirmBSPOST(SalesHeader, 1);
        // end;
        //@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    end;

    [EventSubscriber(ObjectType::Codeunit, codeunit::"Undo Sales Shipment Line", 'OnAfterNewSalesShptLineInsert', '', true, true)]

    local procedure OnAfterNewSalesShptLineInsert(var NewSalesShipmentLine: Record "Sales Shipment Line"; OldSalesShipmentLine: Record "Sales Shipment Line")
    VAR
        PostArchivShipLine: Record "Ligne archive BS";
        recBS: Record "Entete archive BS";

    begin
        // Message('OLD -->  %1  *** %2', OldSalesShipmentLine."Document No.", OldSalesShipmentLine."Line No.");
        // Message('NEW -->  %1  *** %2', NewSalesShipmentLine."Document No.", NewSalesShipmentLine."Line No.");

        AddArchiveLigneBS(NewSalesShipmentLine, OldSalesShipmentLine);
        // AJOUTER CONDITION SI BON SORTIE
        PostArchivShipLine.Reset();
        PostArchivShipLine.SetRange("Document No.", OldSalesShipmentLine."Document No.");
        PostArchivShipLine.SetRange("Line No.", OldSalesShipmentLine."Line No.");
        if PostArchivShipLine.FindFirst() then begin
            recBS.Reset();
            recBS.Get(PostArchivShipLine."Document No.");
            if recBS.Find() then begin
                recBS.Solde := false;
                recBS.Modify();
                Commit();
            end;
            PostArchivShipLine."Qty. Invoiced (Base)" := OldSalesShipmentLine."Quantity (Base)";
            PostArchivShipLine."Quantity Invoiced" := OldSalesShipmentLine.Quantity;
            PostArchivShipLine."Qty. Shipped Not Invoiced" := 0;
            PostArchivShipLine.Correction := true;
            PostArchivShipLine.Modify();
        end;

        recBS.Reset();
        recBS.Get(PostArchivShipLine."Document No.");
        if recBS.Find() then begin
            recBS.CalcFields("Montant reçu caisse", "Montant TTC");
            if (recBS."Montant TTC" = recBS."Montant reçu caisse")
            then begin
                recBS.Solde := true;
            end
            else begin
                recBS.Solde := false;
            end;
            recBS.Modify();
            Commit();
        end;
    end;

    procedure AddArchiveLigneBS(NewSalesShipmentLine: Record "Sales Shipment Line"; OldSalesShipmentLine: Record "Sales Shipment Line")
    var
        PostShipLineArchiv: Record "Ligne archive BS";
    begin
        PostShipLineArchiv.Reset();
        PostShipLineArchiv.TransferFields(NewSalesShipmentLine);
        PostShipLineArchiv."Line Amount" := -PostShipLineArchiv."Line Amount";
        PostShipLineArchiv."Line Amount HT" := -PostShipLineArchiv."Line Amount HT";
        // Message('enregistre %1 *** archive %2 //  enregistre %3  *** archive %4 // enregistre %5 *** archive %6', NewSalesShipmentLine."Document No.", PostShipLineArchiv."Document No.", NewSalesShipmentLine."Line Amount", PostShipLineArchiv."Line Amount", NewSalesShipmentLine."Line Amount HT", PostShipLineArchiv."Line Amount HT");
        PostShipLineArchiv.Insert;
    end;





    [EventSubscriber(ObjectType::Table, 36, 'OnAfterGetNoSeriesCode', '', true, true)]
    procedure OnAfterGetNoSeriesCode(var SalesHeader: Record "Sales Header"; SalesReceivablesSetup: Record "Sales & Receivables Setup"; var NoSeriesCode: Code[20])
    var
        SalesSetup: Record "Sales & Receivables Setup";
    begin
        if SalesHeader.BS = true then begin
            SalesSetup.Get();
            NoSeriesCode := SalesSetup."Retour BS";
        end;
    end;

    [EventSubscriber(ObjectType::table, 36, 'OnAfterInitRecord', '', true, true)]
    local procedure OnAfterInitRecord(var SalesHeader: Record "Sales Header")
    var
        SalesSetup: Record "Sales & Receivables Setup";
    begin
        if (SalesHeader.BS = true) then begin

            SalesSetup.Get();
            SalesHeader."Return Receipt No. Series" := SalesSetup."Retour BS Enregistré";
            //Message('%1', SalesHeader."Return Receipt No. Series");
        end;

    end;

}