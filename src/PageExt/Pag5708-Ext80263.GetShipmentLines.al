pageextension 80263 "Get Shipment Lines" extends "Get Shipment Lines"//5708
{
    layout
    {
        // Add changes to page layout here
        addafter(Control1)
        {
            group(Totalisation)
            {
                field(TotalHT; TotalHT)
                {
                    ApplicationArea = All;
                    Style = Strong;
                }
                field(TotalTTC; TotalTTC)
                {
                    ApplicationArea = All;
                    Style = Strong;
                }
            }
        }
    }

    actions
    {
        // Add changes to page actions here

    }
    trigger OnAfterGetCurrRecord()
    var
        myInt: Integer;
    begin
        calctotal();
    end;

    local procedure calctotal()

    begin

        SaleslShptLine.Reset();

        CurrPage.SetSelectionFilter(SaleslShptLine);
        IF SaleslShptLine.FINDSET THEN begin
            TotalHT := 0;
            TotalTTC := 0;
            repeat
                TotalHT := TotalHT + SaleslShptLine."Line Amount HT";
                TotalTTC := TotalTTC + SaleslShptLine."Line Amount";
            UNTIL SaleslShptLine.NEXT = 0;
        end;
    end;

    var
        TotalTTC: Decimal;
        TotalHT: Decimal;
        Shipmentline: Record "Sales Shipment Line";
        SaleslShptLine: Record "Sales Shipment Line";
}