page 50139 "Specific Cust. Stat. FactBox"
{
    Caption = 'Customer Statistics';
    PageType = CardPart;
    SourceTable = Customer;

    layout
    {
        area(content)
        {
            field("Bs Non Solde"; FindNotSolde(rec))
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

            field("Retour BS Non Solde"; FindRetourBSNotSolde(rec))
            {
                Caption = 'Retour BS non soldé';
                ApplicationArea = All;
                trigger OnDrillDown()
                var
                    RetourBsHeader: Record "Return Receipt Header";
                begin
                    RetourBsHeader.Reset();
                    RetourBsHeader.SetRange("Bill-to Customer No.", rec."No.");
                    RetourBsHeader.SetRange(Solde, false);
                    Page.Run(Page::"Posted Return Receipts BS", RetourBsHeader);
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
                    repeat
                        totalNonSolde := totalNonSolde + BSLine."Line Amount";
                    until BSLine.Next() = 0;
                end;
            until BSHeader.Next() = 0;
        end;

        exit(totalNonSolde);
    end;

    local procedure FindRetourBSNotSolde(recCustomer: Record Customer): Decimal
    var
        retourBS: Record "Return Receipt Header";
        retourBSLine: Record "Return Receipt Line";
        RetourNonSolde: Decimal;
    begin
        RetourNonSolde := 0;
        retourBS.Reset();
        retourBS.SetRange("Bill-to Customer No.", recCustomer."No.");
        retourBS.SetFilter(BS, '%1', true);
        retourBS.SetRange(Solde, false);
        if retourBS.FindSet() then begin
            repeat
                retourBSLine.Reset();
                retourBSLine.SetRange("Document No.", retourBS."No.");
                if retourBSLine.FindSet() then begin
                    repeat
                        RetourNonSolde := RetourNonSolde + retourBSLine."Amount Including VAT";
                    until retourBSLine.Next() = 0;
                end;
            until retourBS.Next() = 0;
        end;

        exit(RetourNonSolde);
    end;




}

