codeunit 50030 "SI Sales Invoice Totals"
{
    // Renvoie, au format JSON, la somme TTC et la somme "Remaining Amount" (Montant Ouvert)
    // des factures vente (Sales Invoice Header) correspondant aux filtres passes.
    // Parametres texte/code vides => filtre ignore. Dates a 0D => pas de filtre date.
    // Reproduit le perimetre de la page "Posted Sales Invoices (Serv.)" (25006189).
    // Exposer en Web Service (Type = Codeunit) pour appel SOAP depuis Postman.

    procedure GetSalesInvoiceTotals(donneurOrdreNo: Code[20]; billToCustomerNo: Code[20]; fromDate: Date; toDate: Date; documentProfile: Text; salespersonCode: Code[20]; zoneRecouvrement: Code[20]; remainingAmountFilter: Text; responsibilityCenter: Code[10]; initiateur: Code[20]; excludeInternalBillTo: Boolean) resultJson: Text
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

        // Filtres normaux supplementaires (champs reels) repris de la page 25006189
        if responsibilityCenter <> '' then
            SalesInvHeader.SetRange("Responsibility Center", responsibilityCenter);
        if excludeInternalBillTo then
            SalesInvHeader.SetRange("Internal Bill-to Customer", false);

        // "Amount Including VAT", "Remaining Amount" et "Initiateur" sont des FlowFields.
        // On NE les filtre PAS via SetFilter (resultats faux sur un FlowField) : on calcule
        // ligne par ligne (comme la page BC) puis on filtre en memoire.
        if SalesInvHeader.FindSet() then
            repeat
                SalesInvHeader.CalcFields("Amount Including VAT", "Remaining Amount", Initiateur);
                if RemainingMatches(SalesInvHeader."Remaining Amount", remainingAmountFilter)
                   and ((initiateur = '') or (SalesInvHeader.Initiateur = initiateur)) then begin
                    TotalTTC += SalesInvHeader."Amount Including VAT";
                    TotalRemaining += SalesInvHeader."Remaining Amount";
                    NbDocuments += 1;
                end;
            until SalesInvHeader.Next() = 0;

        JObj.Add('totalTTC', TotalTTC);
        JObj.Add('totalRemaining', TotalRemaining);
        JObj.Add('nbDocuments', NbDocuments);
        JObj.WriteTo(resultJson);
    end;

    local procedure RemainingMatches(Value: Decimal; FilterExpr: Text): Boolean
    var
        Op: Text;
        NumText: Text;
        Threshold: Decimal;
    begin
        FilterExpr := DelChr(FilterExpr, '=', ' ');
        if FilterExpr = '' then
            exit(true);

        case true of
            FilterExpr.StartsWith('>='):
                begin
                    Op := '>=';
                    NumText := CopyStr(FilterExpr, 3);
                end;
            FilterExpr.StartsWith('<='):
                begin
                    Op := '<=';
                    NumText := CopyStr(FilterExpr, 3);
                end;
            FilterExpr.StartsWith('<>'):
                begin
                    Op := '<>';
                    NumText := CopyStr(FilterExpr, 3);
                end;
            FilterExpr.StartsWith('>'):
                begin
                    Op := '>';
                    NumText := CopyStr(FilterExpr, 2);
                end;
            FilterExpr.StartsWith('<'):
                begin
                    Op := '<';
                    NumText := CopyStr(FilterExpr, 2);
                end;
            FilterExpr.StartsWith('='):
                begin
                    Op := '=';
                    NumText := CopyStr(FilterExpr, 2);
                end;
            else begin
                Op := '=';
                NumText := FilterExpr;
            end;
        end;

        if not Evaluate(Threshold, NumText) then
            exit(true);

        case Op of
            '>':
                exit(Value > Threshold);
            '<':
                exit(Value < Threshold);
            '>=':
                exit(Value >= Threshold);
            '<=':
                exit(Value <= Threshold);
            '<>':
                exit(Value <> Threshold);
            '=':
                exit(Value = Threshold);
        end;

        exit(true);
    end;
}
