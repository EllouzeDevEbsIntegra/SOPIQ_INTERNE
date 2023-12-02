query 50010 "Purchases Dashboard"
{
    Caption = 'Purchases Dashboard';

    elements
    {
        dataitem(Item_Ledger_Entry; "Item Ledger Entry")
        {
            DataItemTableFilter = "Entry Type" = FILTER(Purchase);
            column(Entry_No; "Entry No.")
            {
            }
            column(Document_No; "Document No.")
            {
            }
            column(Posting_Date; "Posting Date")
            {
            }
            column(Entry_Type; "Entry Type")
            {
            }
            column(Quantity; Quantity)
            {
            }
            column(Sales_Amount_Actual; "Sales Amount (Actual)")
            {
            }
            column(Sales_Amount_Expected; "Sales Amount (Expected)")
            {
            }
            column(Cost_Amount_Actual; "Cost Amount (Actual)")
            {
            }
            column(Cost_Amount_Expected; "Cost Amount (Expected)")
            {
            }
            column(Dimension_Set_ID; "Dimension Set ID")
            {
            }
            dataitem(Country_Region; "Country/Region")
            {
                DataItemLink = Code = Item_Ledger_Entry."Country/Region Code";
                column(CountryRegionName; Name)
                {
                }
                dataitem(Vendor; Vendor)
                {
                    DataItemLink = "No." = Item_Ledger_Entry."Source No.";
                    column(VendorName; Name)
                    {
                    }
                    column(Vendor_Posting_Group; "Vendor Posting Group")
                    {
                    }

                    column(Currency_Code; "Currency Code")
                    {

                    }

                    column(City; City)
                    {
                    }
                    dataitem(Item; Item)
                    {
                        DataItemLink = "No." = Item_Ledger_Entry."Item No.";
                        column(Description; Description)
                        {
                        }
                        dataitem(Salesperson_Purchaser; "Salesperson/Purchaser")
                        {
                            DataItemLink = Code = Vendor."Purchaser Code";
                            column(PurchasePersonName; Name)
                            {
                            }
                        }
                    }
                }
            }
        }
    }
}

