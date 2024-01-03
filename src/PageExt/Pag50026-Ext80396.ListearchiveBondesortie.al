pageextension 80396 "Liste archive Bon de sortie" extends "Liste archive Bon de sortie" //50026
{
    layout
    {
        // Add changes to page layout here
    }

    actions
    {
        // Add changes to page actions here
    }

    var
        recuCaisseDoc: Record "Recu Caisse Document";
        recSalesHeaderDoc: Record "Entete archive BS";
        brutHT, totalHt, totalTTC, TotalRemise, Remise : decimal;

    trigger OnAfterGetCurrRecord()
    begin
        recSalesHeaderDoc.Reset();
        CurrPage.SetSelectionFilter(recSalesHeaderDoc);
        if recSalesHeaderDoc.FindSet() then begin
            brutHT := 0;
            totalHt := 0;
            totalTTC := 0;
            TotalRemise := 0;
            Remise := 0;
            repeat

            until recSalesHeaderDoc.Next() = 0;
        end;

    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction in [ACTION::OK, ACTION::LookupOK] then
            CreateLines;
    end;

    procedure CreateLines()
    begin
        recSalesHeaderDoc.Reset();
        CurrPage.SetSelectionFilter(recSalesHeaderDoc);
        if recSalesHeaderDoc.FindSet() then
            repeat
                CreateInvLines(recSalesHeaderDoc);
            until recSalesHeaderDoc.Next() = 0;
    end;


    procedure CreateInvLines(var SalesInvHeader: Record "Entete archive BS")
    var

    begin
        recuCaisseDoc."Document No" := SalesInvHeader."No.";
        recuCaisseDoc."Customer No" := SalesInvHeader."Bill-to Customer No.";
        recuCaisseDoc."Line No" := recuCaisseDoc.incrementNo(recuCaisseDoc."No Recu");
        recuCaisseDoc.Insert();
    end;

    procedure setRecuCaisse(var recuCaisseParam: Record "Recu Caisse Document")
    begin
        recuCaisseDoc := recuCaisseParam;
    end;
}