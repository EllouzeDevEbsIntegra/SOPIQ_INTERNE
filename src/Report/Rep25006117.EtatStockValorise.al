report 25006117 "Etat Stock Valorise"
{


    DefaultLayout = RDLC;
    RDLCLayout = './src/report/RDLC/etatStockValorise.rdl';
    Caption = 'Etat Stock Valorise';


    dataset
    {
        dataitem("Item Leadger Entry"; "Item Ledger Entry")
        {
            DataItemTableView = SORTING("Item No.");
            RequestFilterFields = "Item No.", "Posting Date";
            column(Posting_Date; "Posting Date")
            {

            }
            column(Item_No_; "Item No.")
            {

            }
            column(Quantity; Quantity)
            {

            }

            column(Cost_Amount__Actual_; "Cost Amount (Actual)")
            {

            }

            column(Cost_Amount__Expected_; "Cost Amount (Expected)")
            {

            }
        }
    }
}
