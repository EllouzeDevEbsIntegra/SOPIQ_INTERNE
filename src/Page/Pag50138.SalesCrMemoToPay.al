page 50138 "Sales Cr Memo To Pay"
{
    Editable = false;
    PageType = List;
    UsageCategory = Lists;
    ApplicationArea = all;
    SourceTable = "Sales Cr.Memo Header";
    SourceTableView = where(solde = filter(false));
    Caption = 'Liste Avoir à payer';


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

                field("Bill-to Customer No."; "Bill-to Customer No.")
                {

                }
                field("Remaining Amount"; "Remaining Amount")
                {

                }
                field("Montant reçu caisse"; "Montant reçu caisse")
                {
                    Visible = false;
                }
                field(restePayer; restePayer)
                {
                    ApplicationArea = all;
                }
            }
            group(Totalisation)
            {

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

        recSalesHeaderDoc: Record "Sales Cr.Memo Header";
        totalTTC: decimal;
        restePayer: Decimal;


    trigger OnAfterGetRecord()
    begin
        rec.CalcFields("Remaining Amount", "Montant reçu caisse");
        restePayer := "Remaining Amount" - "Montant reçu caisse";
        // if (restePayer < 1) then begin
        //     rec.solde := true;
        //     rec.Modify();
        // end;
    end;

    trigger OnAfterGetCurrRecord()
    begin
        recSalesHeaderDoc.Reset();
        CurrPage.SetSelectionFilter(recSalesHeaderDoc);
        if recSalesHeaderDoc.FindSet() then begin

            totalTTC := 0;

            repeat
                recSalesHeaderDoc.CalcFields(Amount, "Amount Including VAT");

                totalTTC := totalTTC + recSalesHeaderDoc."Amount Including VAT";
            until recSalesHeaderDoc.Next() = 0;
        end;

    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction in [ACTION::OK, ACTION::LookupOK] then begin
            CreateLines;
        end;
        exit(true);
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


    procedure CreateInvLines(var SalesInvHeader: Record "Sales Cr.Memo Header")
    var

    begin
        SalesInvHeader.CalcFields(Amount, "Amount Including VAT", "Remaining Amount");
        recuCaisseDoc."Document No" := SalesInvHeader."No.";
        recuCaisseDoc.type := recuCaisseDoc.type::Invoice;
        recuCaisseDoc."Customer No" := SalesInvHeader."Bill-to Customer No.";
        recuCaisseDoc."Line No" := recuCaisseDoc.incrementNo(recuCaisseDoc."No Recu");
        recuCaisseDoc."Total TTC" := SalesInvHeader."Amount Including VAT";
        recuCaisseDoc."Montant Reglement" := SalesInvHeader."Amount Including VAT";
        recuCaisseDoc.Insert();
        updateSumRecuCaisse(recuCaisseDoc."No Recu");
    end;

    procedure updateSumRecuCaisse(recuCaisseNo: code[20])
    var
        recuCaisse: Record "Recu Caisse";
    begin
        recuCaisse.Reset();
        recuCaisse.SetRange(No, recuCaisseNo);
        if recuCaisse.FindFirst() then begin
            // recuCaisse.totalDocToPay := recuCaisse.totalDocToPay + totalTTC;
            // recuCaisse.Modify();
            recuCaisse.CalcFields(totalDocToPay, "totalReçu");
        end;

    end;

    procedure setRecuCaisse(var recuCaisseParam: Record "Recu Caisse Document")
    begin
        recuCaisseDoc := recuCaisseParam;
    end;

}