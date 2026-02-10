query 25006654 "Ligne archive BS"
{


    Caption = 'Ligne archive BS';
    elements
    {
        dataitem(ligneArchiveBs; "Ligne archive BS")
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
            column(Discount; "% Discount")
            {
            }
            column(Appl__from_Item_Entry; "Appl.-from Item Entry")
            {
            }
            column(Appl__to_Item_Entry; "Appl.-to Item Entry")
            {
            }
            column(Qty__Shipped_Not_Invoiced; "Qty. Shipped Not Invoiced")
            {
            }
            column(Quantity_Invoiced; "Quantity Invoiced")
            {
            }
            column(Order_No_; "Order No.")
            {
            }
            column(Order_Line_No_; "Order Line No.")
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
            column(Line_Amount; "Line Amount")
            {
            }
            column(Line_Amount_HT; "Line Amount HT")
            {
            }
            column(BS; BS)
            {
            }
            column(Old_Document; "Old Document")
            {
            }
            column(Old_Sell_to_Customer_No_; "Old Sell-to Customer No.")
            {
            }
            column(Old_Bill_to_Customer_No_; "Old Bill-to Customer No.")
            {
            }
            column(Prix_Vente_1; "Prix Vente 1")
            {
            }
            column(Prix_Vente_2; "Prix Vente 2")
            {
            }
            column(Montant_ligne_HT_BS; "Montant ligne HT BS")
            {
            }
            column(Montant_ligne_TTC_BS; "Montant ligne TTC BS")
            {
            }
            column(No__BL; "No. BL")
            {
            }
            column(Related_Invoice_No__; "Related Invoice No. ")
            {
            }

            dataitem(Entete_archive_BS; "Entete archive BS")
            {
                DataItemLink = "No." = ligneArchiveBs."Document No.";
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