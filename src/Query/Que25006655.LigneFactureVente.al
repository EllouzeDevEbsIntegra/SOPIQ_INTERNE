query 25006655 "Ligne Facture Vente"
{


    Caption = 'Ligne Facture Vente';
    elements
    {
        dataitem(ligneFactureVente; "Sales Invoice Line")
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
            column(Appl__from_Item_Entry; "Appl.-from Item Entry")
            {
            }
            column(Appl__to_Item_Entry; "Appl.-to Item Entry")
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
            column(Old_Document; "Old Document")
            {
            }

            dataitem(Entete_Facture_Vente; "Sales Invoice Header")
            {
                DataItemLink = "No." = ligneFactureVente."Document No.";
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