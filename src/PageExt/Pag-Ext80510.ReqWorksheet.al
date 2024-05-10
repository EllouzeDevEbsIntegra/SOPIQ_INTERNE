pageextension 80510 "Req. Worksheet" extends "Req. Worksheet"
{
    layout
    {
        // Add changes to page layout here
        addafter(TotalPurchaseUSD)
        {
            field(TotalLine; TotalLine)
            {
                Caption = 'Nombre de lignes';
            }

        }
    }

    actions
    {
        // Add changes to page actions here
    }

    var
        myInt: Integer;

    local procedure TotalLine(): Integer
    var

    begin

        CalcFields("Total Line");

        exit("Total Line");
    end;

}