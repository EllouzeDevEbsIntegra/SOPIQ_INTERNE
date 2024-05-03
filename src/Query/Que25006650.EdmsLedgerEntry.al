Query 25006650 "Edms Ledger Entry"
{
    Caption = 'Ecriture Comptable EDMS';
    elements
    {
        dataitem(Service_Ledger_Entry_EDMS; "Service Ledger Entry EDMS")
        {
            DataItemTableFilter = "Entry Type" = const(Sale);
            column(Document_Type; "Document Type")
            {
            }
            column(Document_No; "Document No.")
            {
            }
            column(Service_Order_No_; "Service Order No.")
            {
            }
            column(Posting_Date; "Posting Date")
            {
            }
            column(Vehicle_Serial_No_; "Vehicle Serial No.")
            {
            }
            column(Make_Code; "Make Code")
            {
            }
            column(Model_Code; "Model Code")
            {
            }
            column(Model_Version_No_; "Model Version No.")
            {
            }
            column(Customer_No_; "Customer No.")
            {
            }
            column(Bill_to_Customer_No_; "Bill-to Customer No.")
            {
            }
            column(Service_Address; "Service Address")
            {
            }
            column(User_ID; "User ID")
            {
            }
            column(Type; Type)
            {
            }
            column(No_; "No.")
            {
            }
            column(Description; Description)
            {
            }
            column(Unit_Price; "Unit Price")
            {
            }
            column(Discount__; "Discount %")
            {
            }
            column(Amount_LCY; "Amount (LCY)")
            {
                ReverseSign = true;
            }
            column(Amount_Including_VAT__LCY_; "Amount Including VAT (LCY)")
            {
                ReverseSign = true;
            }
            column(Unit_Cost; "Unit Cost")
            {
            }
            column(Total_Cost; "Total Cost")
            {
            }
            column(Resource_Cost_Amount; "Resource Cost Amount")
            {
            }
            column(Line_Discount_Amount__LCY_; "Line Discount Amount (LCY)")
            {
            }
            column(Quantity; Quantity)
            {
                ReverseSign = true;
            }
            column(Finished_Hours; "Finished Hours")
            {
                ReverseSign = true;
            }
            column(Unit_of_Measure_Code; "Unit of Measure Code")
            {
            }
            column(Charged_Qty_; "Charged Qty.")
            {
            }
            column(Chargeable; Chargeable)
            {
            }
            column(Currency_Code; "Currency Code")
            {
            }
            column(Gen__Bus__Posting_Group; "Gen. Bus. Posting Group")
            {
            }
            column(Gen__Prod__Posting_Group; "Gen. Prod. Posting Group")
            {
            }
            column(Location_Code; "Location Code")
            {
            }
            column(Responsibility_Center; "Responsibility Center")
            {
            }
            column(Open; Open)
            {
            }
            column(External_Document_No_; "External Document No.")
            {
            }
            column(Document_Date; "Document Date")
            {
            }
            column(Service_Receiver; "Service Receiver")
            {
            }
            column(Vehicle_Accounting_Cycle_No_; "Vehicle Accounting Cycle No.")
            {
            }
            column(Remaining_Amount; "Remaining Amount")
            {
            }
            column(Cust__Ledger_Entry_No_; "Cust. Ledger Entry No.")
            {
            }
            column(Serv__Order_Remaining_Amt; "Serv. Order Remaining Amt")
            {
            }
            column(Payment_Method_Code; "Payment Method Code")
            {
            }
            column(Deal_Type_Code; "Deal Type Code")
            {
            }
            column(Labor_Group_Code; "Labor Group Code")
            {
            }
            column(Standard_Time; "Standard Time")
            {
            }
            column(Vehicle_Registration_No_; "Vehicle Registration No.")
            {
            }
            column(Package_No_; "Package No.")
            {
            }
            column(VIN; VIN)
            {
            }
            column(Internal; Internal)
            {
            }
            column(Item_Category_Code; "Item Category Code")
            {
            }
            column(Item_Product_Code; "Item Product Code")
            {
            }
            column(Service_Type; "Service Order Type")
            {
            }
            column(Kilometrage; "Variable Field Run 1")
            {
            }

            dataitem(Sales_Invoice_Header; "Sales Invoice Header")
            {
                DataItemLink = "No." = Service_Ledger_Entry_EDMS."Document No.";
                column(Type_Booking; "Type Booking")
                {

                }

                dataitem(Sales_Cr_Memo_Header; "Sales Cr.Memo Header")
                {
                    DataItemLink = "No." = Service_Ledger_Entry_EDMS."Document No.";
                    column(Type_Booking2; "Type Booking")
                    {

                    }
                    column(Phone_No_; "Phone No.")
                    {

                    }



                    dataitem(Customer; Customer)
                    {
                        DataItemLink = "No." = Service_Ledger_Entry_EDMS."Customer No.";
                        column(Name; Name)
                        {
                        }
                        column(Cust_Phone_No; "Phone No.")
                        {

                        }

                        dataitem(Vehicle; Vehicle)
                        {
                            DataItemLink = "Serial No." = Service_Ledger_Entry_EDMS."Vehicle Serial No.";
                            column(First_Registration_Date; "First Registration Date")
                            {

                            }
                            dataitem(Service_Labor; "Service Labor")
                            {
                                DataItemLink = "No." = Service_Ledger_Entry_EDMS."No.";
                                column(TypeMO; "Group Code")
                                {

                                }
                                dataitem(Item; Item)
                                {
                                    DataItemLink = "No." = Service_Ledger_Entry_EDMS."No.";
                                    column(itemGroupe; "Item Product Code")
                                    {

                                    }
                                    dataitem(Item_Category; "Item Category")
                                    {
                                        DataItemLink = Code = Item."Item Product Code";
                                        column(FamilleArticle; Description)
                                        {

                                        }
                                        column(Category_BI; "Category BI")
                                        {

                                        }
                                    }
                                }

                            }
                        }

                    }
                }


            }

        }
    }
}

