page 50114 "Follow Up List"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "Follow Up Header";
    SourceTableView = sorting("Date") order(descending);
    CardPageId = "Follow Up Card";
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;

    // SourceTableView = where("Document Type" = filter(Order | "Return Order"));
    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                field(No; No)
                {
                    Editable = false;

                }
                field("Date"; "Date")
                {
                    Editable = false;
                }
                field("Sales Invoice No"; "Sales Invoice No")
                {
                    Editable = false;
                }
                field("Customer No"; "Customer No")
                {
                    Visible = false;
                    Editable = false;
                }
                field("Customer Name"; "Customer Name")
                {
                    Editable = false;
                }

                field(statut; statut)
                {
                    Editable = false;
                }


                field("Sales Invoice Date"; "Sales Invoice Date")
                {
                    Visible = false;
                    Editable = false;
                }




                field("Customer Phone No"; "Customer Phone No")
                {
                    Visible = false;
                    Editable = false;
                }
                field("Customer Adress"; "Customer Adress")
                {
                    Visible = false;
                    Editable = false;
                }



                field("Service Order No"; "Service Order No")
                {
                    Visible = false;
                    Editable = false;
                }

                field("Service Order Date"; "Service Order Date")
                {
                    Visible = false;
                    Editable = false;
                }

                field("Service Order Type"; "Service Order Type")
                {
                    Visible = false;
                    Editable = false;
                }

                field("Work Description"; "Work Description")
                {
                    Visible = false;
                    Editable = false;
                }
                field("Salesperson Code"; "Salesperson Code")
                {
                    Visible = false;
                    Editable = false;
                }

                field(Comment; Comment)
                {
                    Visible = true;
                    Editable = false;
                }

                field(note; note)
                {
                    Caption = 'Note en %';
                    DecimalPlaces = 2;
                    Editable = false;
                }


            }
        }
    }

}