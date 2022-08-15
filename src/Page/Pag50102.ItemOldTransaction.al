page 50102 "Item Old Transaction"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "Item Old Transaction";
    Caption = 'Mouvement articles 2020-2021';

    layout
    {
        area(Content)
        {
            group(GroupName)
            {
                field("Document N°"; "Document N°")
                {


                }

                field("Document Type"; "Document Type")
                {


                }

                field("Is Output"; "Is Output")
                {


                }

                field("Is Input"; "Is Input")
                {


                }

                field("Tier N°"; "Tier N°")
                {


                }

                field("Tier Name"; "Tier Name")
                {


                }

                field("Document date"; "Document date")
                {


                }

                field("Year"; "Year")
                {


                }

                field("Item N°"; "Item N°")
                {


                }

                field("Item Description"; "Item Description")
                {


                }

                field("Sales Qty"; "Sales Qty")
                {


                }

                field("Purshase Qty"; "Purshase Qty")
                {


                }

                field("Unit Price HT"; "Unit Price HT")
                {



                }

                field("Discount Percent"; "Discount Percent")
                {



                }

                field("Amount HT"; "Amount HT")
                {



                }

                field("VAT Tax Amount"; "VAT Tax Amount")
                {



                }

                field("Total Line HT"; "Total Line HT")
                {



                }

                field("Total Line TTC"; "Total Line TTC")
                {



                }

            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ActionName)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin

                end;
            }
        }
    }

    var
        myInt: Integer;
}