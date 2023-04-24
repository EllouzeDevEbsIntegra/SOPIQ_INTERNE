pageextension 80141 "Posted Sales Invoice" extends "Posted Sales Invoice"//132
{
    layout
    {
        // Add changes to page layout here
    }

    actions
    {
        addafter(Print)
        {
            action(PrintPR)
            {
                Caption = 'Imprimer PR';
                ApplicationArea = All;
                Visible = true;
                // RunObject = report "Invoice PR";
                Image = Print;
                trigger OnAction()
                VAR
                    SalesHeader: Record "Sales Invoice Header";

                begin
                    CurrPage.SETSELECTIONFILTER(SalesHeader);
                    REPORT.RUNMODAL(REPORT::"Invoice PR", TRUE, FALSE, SalesHeader);
                end;




            }
        }
        // Add changes to page actions here
    }

    var
        myInt: Integer;
}