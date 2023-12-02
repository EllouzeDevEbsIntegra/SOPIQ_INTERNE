query 50011 "Purch Rcpt Lines"
{
    Caption = 'Purchase Receipts Lines';

    elements
    {
        dataitem(Purch_Rcpt_Line; "Purch. Rcpt. Line")
        {
            DataItemTableFilter = Quantity = FILTER(<> 0);
            column(Entry_No; "Item Rcpt. Entry No.")
            {
            }
            column(Document_No; "Document No.")
            {
            }
            column(Posting_Date; "Posting Date")
            {
            }

            column(Quantity; Quantity)
            {
            }

            column(Dimension_Set_ID; "Dimension Set ID")
            {
            }

            column(Direct_Unit_Cost; "Direct Unit Cost")
            {

            }

            column(Unit_Cost; "Unit Cost")
            {

            }

            column(Currency_Code; "Currency Code")
            {

            }
            dataitem(Purch__Rcpt__Header; "Purch. Rcpt. Header")
            {
                DataItemLink = "No." = Purch_Rcpt_Line."Document No.";
                column(Currency_Factor; "Currency Factor")
                {

                }
            }
        }
    }
}

