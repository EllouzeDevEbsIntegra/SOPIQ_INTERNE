query 50012 "Purch CrMemo Line"
{
    Caption = 'Purchase Credit Memo Lines';

    elements
    {
        dataitem(Purch_Cr_Memo_Line; "Purch. Cr. Memo Line")
        {
            DataItemTableFilter = Quantity = FILTER(<> 0);
            column(Document_No; "Document No.")
            {
            }
            column(Line_No_; "Line No.")
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

            dataitem(PurchCrMemoHdr; "Purch. Cr. Memo Hdr.")
            {
                DataItemLink = "No." = Purch_Cr_Memo_Line."Document No.";
                column(No_; "No.")
                {
                }

                column(Currency_Code; "Currency Code")
                {

                }

                column(Currency_Factor; "Currency Factor")
                {

                }
                dataitem(Item_Ledger_Entry; "Item Ledger Entry")
                {
                    DataItemLink = "Document No." = Purch_Cr_Memo_Line."Document No.", "document Line No." = Purch_Cr_Memo_Line."Line No.";
                    column(Entry_No_; "Entry No.")
                    {

                    }
                }
            }



        }
    }
}

