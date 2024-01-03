page 50134 "Sales Invoice To Pay"
{
    Editable = false;
    PageType = List;
    UsageCategory = Lists;
    ApplicationArea = all;
    SourceTable = "Sales Invoice Header";

    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                field("No."; "No.")
                {
                    ApplicationArea = All;
                }

                field("Sell-to Customer No."; "Sell-to Customer No.")
                {

                }

                field("Bill-to Customer No."; "Bill-to Customer No.")
                {

                }

                field(Amount; Amount)
                {

                }

                field("Invoice Discount Amount"; "Invoice Discount Amount")
                {

                }

                field("Amount Including VAT"; "Amount Including VAT")
                {

                }

                field("Remaining Amount"; "Remaining Amount")
                {

                }
            }
            group(Totalisation)
            {
                field(brutHT; brutHT)
                {
                    ApplicationArea = All;
                    Style = Strong;
                }
                field(totalRem; TotalRemise)
                {
                    ApplicationArea = All;
                    Style = Strong;
                }

                field(Remise; Remise)
                {
                    ApplicationArea = All;
                    Style = Strong;
                }
                field(TotalHT; totalHt)
                {
                    ApplicationArea = All;
                    Style = Strong;
                }
                field(TotalTTC; totalTTC)
                {
                    ApplicationArea = All;
                    Style = Strong;
                }


            }
        }
    }

    actions
    {
        area(Processing)
        {

        }
    }

    var
        recuCaisseDoc: Record "Recu Caisse Document";

        recSalesHeaderDoc: Record "Sales Invoice Header";
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
                recSalesHeaderDoc.CalcFields(DiscountAmount, Amount, "Amount Including VAT");
                brutHT := brutHT + recSalesHeaderDoc.Amount + recSalesHeaderDoc.DiscountAmount;
                TotalRemise := TotalRemise + recSalesHeaderDoc.DiscountAmount;
                Remise := (TotalRemise / brutHT) * 100;
                totalHt := totalHt + recSalesHeaderDoc.Amount;
                totalTTC := totalTTC + recSalesHeaderDoc."Amount Including VAT" + recSalesHeaderDoc."STStamp Amount";
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
            //Message(recSalesHeaderDoc."No.");
            until recSalesHeaderDoc.Next() = 0;
    end;


    procedure CreateInvLines(var SalesInvHeader: Record "Sales Invoice Header")
    var

    begin
        recuCaisseDoc."Document No" := SalesInvHeader."No.";
        recuCaisseDoc."Customer No" := SalesInvHeader."Bill-to Customer No.";
        recuCaisseDoc."Line No" := recuCaisseDoc.incrementNo(recuCaisseDoc."No Recu");
        recuCaisseDoc.Insert();
        //Message('test %1', recuCaisseDoc."No Recu");
    end;

    procedure setRecuCaisse(var recuCaisseParam: Record "Recu Caisse Document")
    begin
        recuCaisseDoc := recuCaisseParam;
    end;

}