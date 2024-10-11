query 25006653 PaymentLine
{

    Caption = 'PaymentLine';
    elements
    {
        dataitem(PaymentLine; "Payment Line")
        {
            column(No_; "No.")
            {
            }
            column(Amount; Amount)
            {
            }
            column(Amount__LCY_; "Amount (LCY)")
            {
            }
            column(Account_No_; "Account No.")
            {
            }
            column(Drawee_Reference; "Drawee Reference")
            {
            }
            column("Type_réglement"; "Type réglement")
            {
            }
            column(STCommentaires; STCommentaires)
            {
            }
            column(Posting_Date; "Posting Date")
            {
            }
            column(Due_Date; "Due Date")
            {
            }


        }
    }

    var
        myInt: Integer;

    trigger OnBeforeOpen()
    begin

    end;
}