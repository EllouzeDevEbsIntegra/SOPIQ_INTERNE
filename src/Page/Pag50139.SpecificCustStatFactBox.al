page 50139 "Specific Cust. Stat. FactBox"
{
    Caption = 'Customer Statistics';
    PageType = CardPart;
    SourceTable = Customer;

    layout
    {
        area(content)
        {
            field(FindNoTInvoicedLines; FindNotSolde(rec))
            {
                Caption = 'BS non soldé';
                ApplicationArea = All;
                trigger OnDrillDown()
                var
                    BsHeader: Record "Entete archive BS";
                begin
                    BsHeader.Reset();
                    BsHeader.SetRange("Bill-to Customer No.", rec."No.");
                    BsHeader.SetRange(Solde, false);
                    Page.Run(Page::"Liste archive Bon de sortie", BsHeader);
                end;
            }


        }

    }

    actions
    {
    }

    local procedure FindNotSolde(recCustomer: Record Customer): Decimal
    var
        BSLine: Record "Ligne archive BS";
        BSHeader: Record "Entete archive BS";
        totalNonSolde: Decimal;
    begin
        totalNonSolde := 0;
        BSHeader.Reset();
        BSHeader.SetRange("Bill-to Customer No.", recCustomer."No.");
        BSHeader.SetRange(Solde, false);
        if BSHeader.FindSet() then begin
            repeat
                BSLine.Reset();
                BSLine.SetRange("Document No.", BSHeader."No.");
                if BSLine.FindSet() then begin
                    totalNonSolde := totalNonSolde + BSLine."Line Amount";
                end;
            until BSHeader.Next() = 0;
        end;

        exit(totalNonSolde);
    end;




}

