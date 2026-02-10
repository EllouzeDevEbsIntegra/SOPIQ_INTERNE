query 25006656 "Ligne Retour BS"
{


    Caption = 'Ligne Retour BS';
    elements
    {
        dataitem(ligneRetourBs; "Return Receipt Line")
        {

            column(Document_No_; "Document No.")
            {
            }
            column(Posting_Date; "Posting Date")
            {
            }
            column(Sell_to_Customer_No_; "Sell-to Customer No.")
            {
            }
            column(Item_No_; "No.")
            {
            }
            column(Location_Code; "Location Code")
            {
            }
            column(Posting_Group; "Posting Group")
            {
            }
            column(Description; Description)
            {
            }
            column(Unit_of_Measure; "Unit of Measure")
            {
            }
            column(Quantity; Quantity)
            {
            }
            column(Unit_Price; "Unit Price")
            {
            }
            column(Line_Discount__; "Line Discount %")
            {
            }
            column(Discount; "Line Discount %")
            {
            }
            column(Appl__from_Item_Entry; "Appl.-from Item Entry")
            {
            }
            column(Appl__to_Item_Entry; "Appl.-to Item Entry")
            {
            }

            column(Quantity_Invoiced; "Quantity Invoiced")
            {
            }
            column(Bill_to_Customer_No_; "Bill-to Customer No.")
            {
            }
            column(VAT_Base_Amount; "VAT Base Amount")
            {
            }
            column(Unit_Cost; "Unit Cost")
            {
            }
            column(Bin_Code; "Bin Code")
            {
            }
            column(Line_Amount; "Amount Including VAT")
            {
            }
            column(Line_Amount_HT; Amount)
            {
            }
            column(BS; BS)
            {
            }


            dataitem(Entete_retour_BS; "Return Receipt Header")
            {
                DataItemLink = "No." = ligneRetourBs."Document No.";
                column(Solde; Solde)
                {
                }
                column(custNameImprime; custNameImprime)
                {
                }
            }

        }
    }
}