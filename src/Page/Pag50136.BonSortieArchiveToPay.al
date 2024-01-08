page 50136 "Bon Sortie Archive To Pay"
{
    Editable = false;
    PageType = List;
    UsageCategory = Lists;
    ApplicationArea = all;
    SourceTable = "Entete archive BS";
    SourceTableView = where(solde = filter(false));
    Caption = 'Liste Bon Sortie à payer';

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

                field("Montant TTC"; "Montant TTC")
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
                field("Total TTC"; totalTTC)
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
        restePayer: Decimal;
        recSalesHeaderDoc: Record "Entete archive BS";
        totalTTC: decimal;


    trigger OnAfterGetCurrRecord()
    begin
        recSalesHeaderDoc.Reset();
        CurrPage.SetSelectionFilter(recSalesHeaderDoc);
        if recSalesHeaderDoc.FindSet() then begin

            totalTTC := 0;

            repeat
                recSalesHeaderDoc.CalcFields("Montant TTC");
                totalTTC := totalTTC + recSalesHeaderDoc."Montant TTC";
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


    procedure CreateInvLines(var SalesInvHeader: Record "Entete archive BS")
    var

    begin
        SalesInvHeader.CalcFields("Montant TTC");
        recuCaisseDoc."Document No" := SalesInvHeader."No.";
        recuCaisseDoc.type := recuCaisseDoc.type::BS;
        recuCaisseDoc."Customer No" := SalesInvHeader."Bill-to Customer No.";
        recuCaisseDoc."Line No" := recuCaisseDoc.incrementNo(recuCaisseDoc."No Recu");
        recuCaisseDoc."Total TTC" := SalesInvHeader."Montant TTC";
        recuCaisseDoc."Montant Reglement" := SalesInvHeader."Montant TTC";
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
            recuCaisse.CalcFields(totalDocToPay, "totalReçu");
        end;

    end;

    procedure setRecuCaisse(var recuCaisseParam: Record "Recu Caisse Document")
    begin
        recuCaisseDoc := recuCaisseParam;
    end;

    trigger OnAfterGetRecord()
    begin
        rec.CalcFields("Montant TTC", "Montant reçu caisse");
        restePayer := "Montant TTC" - "Montant reçu caisse";
        // if (restePayer < 1) then begin
        //     rec.solde := true;
        //     rec.Modify();
        // end;
    end;
}