codeunit 50019 SubscriberEventProcedure
{
    EventSubscriberInstance = StaticAutomatic;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post (Yes/No)", 'OnBeforeConfirmSalesPost', '', true, true)]
    procedure OnBeforeConfirmSalesPost(salesHeader: Record "Sales Header");
    var
        recSalesLine: Record "Sales Line";
        recSalesHeader: Record "Sales Shipment Header";
        recCrSalesHeader: Record "Return Receipt Header";
        numDoc: TEXT[50];

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
    end;

}