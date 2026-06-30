codeunit 50030 "SI Sales Invoice Totals"
{
    // Renvoie, au format JSON, la somme TTC et la somme Remaining Amount
    // des factures vente (Sales Invoice Header) correspondant aux filtres passés.
    // Paramètres vides => filtre ignoré.
    // Exposer en Web Service (Type = Codeunit) pour appel SOAP depuis Postman.

    procedure GetSalesInvoiceTotals(donneurOrdreNo: Code[20]; billToCustomerNo: Code[20]; fromDate: Date; toDate: Date; documentProfile: Text; salespersonCode: Code[20]; zoneRecouvrement: Code[20]; remainingAmountFilter: Text) resultJson: Text
    var
        SalesInvHeader: Record "Sales Invoice Header";
        JObj: JsonObject;
        TotalTTC: Decimal;
        TotalRemaining: Decimal;
        NbDocuments: Integer;
    begin
        SalesInvHeader.Reset();

        if donneurOrdreNo <> '' then
            SalesInvHeader.SetRange("Sell-to Customer No.", donneurOrdreNo);
        if billToCustomerNo <> '' then
            SalesInvHeader.SetRange("Bill-to Customer No.", billToCustomerNo);

        if (fromDate <> 0D) and (toDate <> 0D) then
            SalesInvHeader.SetRange("Posting Date", fromDate, toDate)
        else begin
            if fromDate <> 0D then
                SalesInvHeader.SetFilter("Posting Date", '>=%1', fromDate);
            if toDate <> 0D then
                SalesInvHeader.SetFilter("Posting Date", '<=%1', toDate);
        end;

        if documentProfile <> '' then
            SalesInvHeader.SetFilter("Document Profile", documentProfile);
        if salespersonCode <> '' then
            SalesInvHeader.SetRange("Salesperson Code", salespersonCode);
        if zoneRecouvrement <> '' then
            SalesInvHeader.SetRange("Tax Area Code", zoneRecouvrement);

        // Filtre sur le FlowField "Remaining Amount" (ex. '>0' = non payé, '=0' = soldé)
        if remainingAmountFilter <> '' then
            SalesInvHeader.SetFilter("Remaining Amount", remainingAmountFilter);

        // "Amount Including VAT" et "Remaining Amount" sont des FlowFields :
        // on boucle et on cumule via CalcFields.
        if SalesInvHeader.FindSet() then
            repeat
                SalesInvHeader.CalcFields("Amount Including VAT", "Remaining Amount");
                TotalTTC += SalesInvHeader."Amount Including VAT";
                TotalRemaining += SalesInvHeader."Remaining Amount";
                NbDocuments += 1;
            until SalesInvHeader.Next() = 0;

        JObj.Add('totalTTC', TotalTTC);
        JObj.Add('totalRemaining', TotalRemaining);
        JObj.Add('nbDocuments', NbDocuments);
        JObj.WriteTo(resultJson);
    end;
}
